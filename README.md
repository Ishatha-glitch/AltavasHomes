# AltavasHomes (Flutter)

Rentals + rent tracking + service bookings for tenants, landlords, and service
providers (plumbers, electricians, movers, etc.), built with **Flutter**,
**Supabase**, and shipped via **Codemagic** to Android, iOS, APK, and web.

---

## 1. What's in this project

```
altavashomes_flutter/
  lib/
    main.dart                  # App entry, Supabase init
    router.dart                # go_router, role-based redirects
    providers/auth_provider.dart
    services/db.dart
    screens/
      auth/                    # role select, sign up, sign in
      tenant/                  # dashboard, browse (GPS+map), detail
      landlord/                # dashboard, add property (GPS+photos)
      service_provider/        # dashboard (bookings, schedule, pay)
    widgets/
      rent_progress_bar.dart
      property_card.dart
  pubspec.yaml
  codemagic.yaml               # CI/CD: Android APK/AAB, iOS IPA, Web
  .env.example                 # copy to .env locally, never commit .env
supabase/
  schema.sql                   # run once in Supabase SQL editor
```

The `supabase/schema.sql` file (shared with the earlier scaffold) sets up:
- `profiles` (tenant / landlord / service_provider, auto-created on signup)
- `properties` (GPS lat/lng, bedrooms, bathrooms, rent, photos, vacancy status)
- `leases` (tenant ↔ property ↔ landlord, monthly rent)
- `payments` + a `lease_payment_progress` view (drives the % rent-paid bar)
- `service_bookings` (task, scheduled time, expected pay, status)
- a public `property-images` storage bucket

---

## 2. Set up Supabase

1. Go to [supabase.com](https://supabase.com) → **New project**.
2. Once created, open **SQL Editor → New query**, paste the entire contents
   of `supabase/schema.sql`, and run it.
3. Go to **Project Settings → API** and copy:
   - **Project URL** → this is `SUPABASE_URL`
   - **anon public key** → this is `SUPABASE_ANON_KEY`
4. Go to **Authentication → Providers** and make sure **Email** is enabled.
   (Optional: turn off "Confirm email" while testing, so sign-up is instant.)
5. Locally, copy `.env.example` to `.env` and fill in the two values above.
   **Never commit `.env`** — it's already in `.gitignore`.

---

## 3. Push the code to GitHub

```bash
cd altavashomes_flutter
git init
git add .
git commit -m "Initial AltavasHomes Flutter app"
gh repo create altavashomes --private --source=. --push
# or manually: create a repo on github.com, then
git remote add origin https://github.com/YOUR_USERNAME/altavashomes.git
git branch -M main
git push -u origin main
```

Because `.env` is git-ignored, your Supabase keys never end up in the repo —
Codemagic will inject them at build time (step 5).

---

## 4. Get Google Maps API keys (for GPS + map screens)

The app uses `google_maps_flutter`, which needs API keys for Android and iOS:

1. In [Google Cloud Console](https://console.cloud.google.com), create a
   project → enable **Maps SDK for Android** and **Maps SDK for iOS**.
2. Create an API key under **Credentials**.
3. Add the key to:
   - `android/app/src/main/AndroidManifest.xml` inside `<application>`:
     ```xml
     <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_KEY"/>
     ```
   - `ios/Runner/AppDelegate.swift`, near the top of `application(_:didFinishLaunchingWithOptions:)`:
     ```swift
     GMSServices.provideAPIKey("YOUR_KEY")
     ```
     (also `import GoogleMaps` at the top of the file)
4. For Android, also add location permissions to `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
   ```
5. For iOS, add to `ios/Runner/Info.plist`:
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>AltavasHomes uses your location to show nearby rentals and pin exact house locations.</string>
   ```

(These native folders — `android/`, `ios/` — are generated the first time you
run `flutter create .` inside this project, or automatically the first time
you build on Codemagic. If they don't exist yet locally, run:
`flutter create --platforms=android,ios,web .` from the project root once
you have Flutter installed.)

---

## 5. Connect Codemagic and build

1. Go to [codemagic.io](https://codemagic.io) → sign in with GitHub → select
   your `altavashomes` repo.
2. Codemagic will detect `codemagic.yaml` in the repo root and offer three
   workflows: **AltavasHomes Android**, **AltavasHomes iOS**, **AltavasHomes Web**.
3. Under **App settings → Environment variables**, add (mark as "secret"):
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
4. **Android**: the Android workflow builds a release APK (installable
   directly on any Android phone — the ".apk file" you asked about) and an
   `.aab` bundle (for Play Store submission). No extra signing setup is
   required for a testable APK; for Play Store release signing, add a
   keystore under **App settings → Code signing → Android code signing**.
5. **iOS**: requires an Apple Developer account. Under **App settings → Code
   signing → iOS code signing**, connect your Apple Developer account (or
   upload a signing certificate + provisioning profile). Codemagic then
   builds and can submit straight to TestFlight.
6. **Web**: builds a static `build/web` folder. Download the artifact and
   deploy it to any static host — e.g. **Netlify**, **Vercel**, **GitHub
   Pages**, or **Firebase Hosting**. Quickest option:
   ```bash
   npm install -g netlify-cli
   netlify deploy --dir=build/web --prod
   ```
7. Click **Start new build** on any workflow to kick things off. Every future
   `git push` to `main` can auto-trigger builds if you enable that under
   **Workflow → Triggering**.

---

## 6. Payments (mobile money & bank)

The tenant dashboard's "Pay with Mobile Money" / "Pay from Bank" buttons
currently insert a `pending` row into the `payments` table — this is the
hook point, not a finished payment integration (real money movement needs a
licensed payment processor and its own compliance review, which is outside
what this code can responsibly stub out). To go live:

1. Pick a provider for your region — e.g. **M-Pesa Daraja API** (Kenya),
   **Flutterwave** or **Paystack** (multi-country Africa), or **Stripe** (cards/bank, global).
2. Write a **Supabase Edge Function** (`supabase/edge-functions/payment-webhook`
   folder is scaffolded for this) that:
   - Receives the payment request from the app (amount, lease_id, method)
   - Calls the provider's API (e.g. M-Pesa STK Push) to prompt the user's phone
   - Listens for the provider's webhook/callback
   - On success, updates the matching `payments` row's `status` to `completed`
3. The `lease_payment_progress` view already recalculates the % bar
   automatically once a payment's status flips to `completed` — no app
   changes needed.

---

## 7. Running locally

```bash
flutter pub get
flutter run                 # pick a connected device/emulator, or:
flutter run -d chrome       # web
flutter build apk --release # local APK build
```
