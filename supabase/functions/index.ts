import { serve } from "https://deno.land/std@0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

serve(async (req) => {
  try {
    const { phone, amount, lease_id, account_ref } = await req.json();

    // Get OAuth Token from Daraja
    const auth = btoa(`\( {Deno.env.get("MPESA_CONSUMER_KEY")!}: \){Deno.env.get("MPESA_CONSUMER_SECRET")!}`);
    const tokenRes = await fetch(
      "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      { headers: { Authorization: `Basic ${auth}` } }
    );
    const { access_token } = await tokenRes.json();

    // STK Push
    const timestamp = new Date().toISOString().replace(/[^0-9]/g, '').slice(0, 14);
    const password = btoa(`\( {Deno.env.get("MPESA_SHORTCODE")!} \){Deno.env.get("MPESA_PASSKEY")!}${timestamp}`);

    const stkRes = await fetch("https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${access_token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        BusinessShortCode: Deno.env.get("MPESA_SHORTCODE")!,
        Password: password,
        Timestamp: timestamp,
        TransactionType: "CustomerPayBillOnline",
        Amount: Math.round(amount),
        PartyA: phone,
        PartyB: Deno.env.get("MPESA_SHORTCODE")!,
        PhoneNumber: phone,
        CallBackURL: "https://YOUR-PROJECT.supabase.co/functions/v1/mpesa-callback",
        AccountReference: account_ref || "ALTAVAS-RENT",
        TransactionDesc: "AltavasHomes Rent Payment",
      }),
    });

    const result = await stkRes.json();

    // Save pending payment
    await supabase.from("payments").insert({
      lease_id,
      tenant_id: null, // TODO: get from auth context
      landlord_id: null, // TODO: get from lease
      amount,
      method: "mobile_money",
      status: "pending",
      period_month: new Date().toISOString().slice(0, 10),
      reference: result.CheckoutRequestID || result.ConversationID,
    });

    return new Response(JSON.stringify({ success: true, result }), { status: 200 });

  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: error.message }), { status: 400 });
  }
});
