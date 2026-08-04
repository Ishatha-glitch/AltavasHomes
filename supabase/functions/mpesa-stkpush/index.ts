import { serve } from "https://deno.land/std@0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const JSON_HEADERS = { "Content-Type": "application/json" };

serve(async (req) => {
  try {
    const { phone, amount, lease_id, tenant_id, landlord_id, account_ref } =
      await req.json();

    if (!phone || !amount || !lease_id || !tenant_id || !landlord_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "phone, amount, lease_id, tenant_id and landlord_id are all required",
        }),
        { status: 400, headers: JSON_HEADERS },
      );
    }

    const CONSUMER_KEY = Deno.env.get("MPESA_CONSUMER_KEY")!;
    const CONSUMER_SECRET = Deno.env.get("MPESA_CONSUMER_SECRET")!;
    const SHORTCODE = Deno.env.get("MPESA_SHORTCODE")!;
    const PASSKEY = Deno.env.get("MPESA_PASSKEY")!;
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;

    // 1. Get OAuth token from Daraja
    const auth = btoa(`${CONSUMER_KEY}:${CONSUMER_SECRET}`);
    const tokenRes = await fetch(
      "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      { headers: { Authorization: `Basic ${auth}` } },
    );
    const { access_token } = await tokenRes.json();

    // 2. STK Push
    const timestamp = new Date().toISOString().replace(/[^0-9]/g, "").slice(0, 14);
    const password = btoa(`${SHORTCODE}${PASSKEY}${timestamp}`);

    const stkRes = await fetch(
      "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${access_token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          BusinessShortCode: SHORTCODE,
          Password: password,
          Timestamp: timestamp,
          TransactionType: "CustomerPayBillOnline",
          Amount: Math.round(amount),
          PartyA: phone,
          PartyB: SHORTCODE,
          PhoneNumber: phone,
          CallBackURL: `${SUPABASE_URL}/functions/v1/hyper-responder`,
          AccountReference: account_ref || "ALTAVAS-RENT",
          TransactionDesc: "AltavasHomes Rent Payment",
        }),
      },
    );

    const result = await stkRes.json();

    // 3. Log the pending payment with real column names
    await supabase.from("payments").insert({
      lease_id,
      tenant_id,
      landlord_id,
      amount,
      payment_method: "mobile_money",
      payment_month: new Date().toISOString().slice(0, 10),
      status: "pending",
      transaction_reference: result.CheckoutRequestID ?? result.ConversationID ?? null,
    });

    return new Response(
      JSON.stringify({ success: true, result }),
      { status: 200, headers: JSON_HEADERS },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 400, headers: JSON_HEADERS },
    );
  }
});
