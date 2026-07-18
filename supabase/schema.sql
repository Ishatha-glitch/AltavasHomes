-- ============================================================
-- ALTAVASHOMES — SUPABASE SCHEMA
-- Run this in Supabase SQL editor (Project > SQL Editor > New query)
-- ============================================================

-- 1. PROFILES (extends auth.users) --------------------------------
create type user_role as enum ('tenant', 'landlord', 'service_provider');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role user_role not null,
  service_category text, -- only for service_provider e.g. 'plumber','electrician','mover'
  avatar_url text,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Profiles are viewable by everyone"
  on public.profiles for select using (true);

create policy "Users can insert their own profile"
  on public.profiles for insert with check (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update using (auth.uid() = id);

-- Auto-create profile row when a new auth user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, phone, role, service_category)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'phone',
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'tenant'),
    new.raw_user_meta_data->>'service_category'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 2. PROPERTIES -----------------------------------------------------
create type property_status as enum ('vacant', 'occupied');

create table public.properties (
  id uuid primary key default gen_random_uuid(),
  landlord_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  address text,
  latitude double precision not null,
  longitude double precision not null,
  bedrooms int not null default 1,
  bathrooms int not null default 1,
  rent_amount numeric(12,2) not null,
  currency text default 'KES',
  status property_status not null default 'vacant',
  images text[] default '{}',      -- storage URLs
  created_at timestamptz default now()
);

alter table public.properties enable row level security;

create policy "Anyone can view properties"
  on public.properties for select using (true);

create policy "Landlords can insert their own properties"
  on public.properties for insert with check (auth.uid() = landlord_id);

create policy "Landlords can update their own properties"
  on public.properties for update using (auth.uid() = landlord_id);

create policy "Landlords can delete their own properties"
  on public.properties for delete using (auth.uid() = landlord_id);

-- 3. LEASES (links a tenant to a property they rent) -----------------
create table public.leases (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  tenant_id uuid not null references public.profiles(id) on delete cascade,
  landlord_id uuid not null references public.profiles(id) on delete cascade,
  monthly_rent numeric(12,2) not null,
  start_date date not null default current_date,
  active boolean not null default true,
  created_at timestamptz default now()
);

alter table public.leases enable row level security;

create policy "Tenant or landlord can view their lease"
  on public.leases for select
  using (auth.uid() = tenant_id or auth.uid() = landlord_id);

create policy "Landlord can create lease"
  on public.leases for insert with check (auth.uid() = landlord_id);

create policy "Landlord can update lease"
  on public.leases for update using (auth.uid() = landlord_id);

-- 4. PAYMENTS (rent payments made by tenants) ------------------------
create type payment_method as enum ('mobile_money', 'bank');
create type payment_status as enum ('pending', 'completed', 'failed');

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  lease_id uuid not null references public.leases(id) on delete cascade,
  tenant_id uuid not null references public.profiles(id) on delete cascade,
  landlord_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric(12,2) not null,
  method payment_method not null,
  status payment_status not null default 'pending',
  period_month date not null,  -- e.g. '2026-07-01' = July 2026 rent
  reference text,              -- transaction ref from payment gateway
  created_at timestamptz default now()
);

alter table public.payments enable row level security;

create policy "Tenant/landlord can view related payments"
  on public.payments for select
  using (auth.uid() = tenant_id or auth.uid() = landlord_id);

create policy "Tenant can create own payment"
  on public.payments for insert with check (auth.uid() = tenant_id);

create policy "Tenant can update own pending payment"
  on public.payments for update using (auth.uid() = tenant_id);

-- Helper view: % of current month's rent paid, per lease
create view public.lease_payment_progress as
select
  l.id as lease_id,
  l.tenant_id,
  l.landlord_id,
  l.monthly_rent,
  date_trunc('month', now())::date as period_month,
  coalesce(sum(p.amount) filter (
    where p.status = 'completed'
      and date_trunc('month', p.period_month) = date_trunc('month', now())
  ), 0) as paid_amount,
  round(
    coalesce(sum(p.amount) filter (
      where p.status = 'completed'
        and date_trunc('month', p.period_month) = date_trunc('month', now())
    ), 0) / l.monthly_rent * 100, 1
  ) as percent_paid
from public.leases l
left join public.payments p on p.lease_id = l.id
group by l.id, l.tenant_id, l.landlord_id, l.monthly_rent;

-- 5. SERVICE BOOKINGS (plumbers, electricians, movers, etc.) ---------
create type booking_status as enum ('booked', 'in_progress', 'completed', 'cancelled');

create table public.service_bookings (
  id uuid primary key default gen_random_uuid(),
  service_provider_id uuid not null references public.profiles(id) on delete cascade,
  client_id uuid not null references public.profiles(id) on delete cascade,
  task_description text not null,
  scheduled_time timestamptz not null,
  expected_amount numeric(12,2),
  status booking_status not null default 'booked',
  address text,
  created_at timestamptz default now()
);

alter table public.service_bookings enable row level security;

create policy "Provider/client can view their bookings"
  on public.service_bookings for select
  using (auth.uid() = service_provider_id or auth.uid() = client_id);

create policy "Client can create booking"
  on public.service_bookings for insert with check (auth.uid() = client_id);

create policy "Provider can update booking status"
  on public.service_bookings for update
  using (auth.uid() = service_provider_id or auth.uid() = client_id);

-- 6. STORAGE BUCKET for property photos ------------------------------
insert into storage.buckets (id, name, public)
values ('property-images', 'property-images', true)
on conflict (id) do nothing;

create policy "Public read property images"
  on storage.objects for select using (bucket_id = 'property-images');

create policy "Authenticated upload property images"
  on storage.objects for insert
  with check (bucket_id = 'property-images' and auth.role() = 'authenticated');
