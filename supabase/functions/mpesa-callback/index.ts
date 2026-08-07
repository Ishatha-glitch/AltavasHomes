import { serve } from "https://deno.land/std@0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

async function payoutToLandlord(payment: {
  id: string;
  landlord_id: string;
  amount: number;
}) {
  try {
    const { data: landlord, error } = await supabase
      .from("profiles")
      .select("phone, full_name")
      .eq("id", payment.landlord_id)
      .single();

    if (error || !landlord?.phone) {
      await supabase
        .from("payments")
        .update({ payout_status: "failed" })
        .eq("id", payment.id);
      return;
    }

    const CONSUMER_KEY = Deno.env.get("MPESA_CONSUMER_KEY")!;
    const CONSUMER_SECRET = Deno.env.get("MPESA_CONSUMER_SECRET")!;
    const INITIATOR_NAME = Deno.env.get("MPESA_INITIATOR_NAME")!;
    const SECURITY_CREDENTIAL = Deno.env.get("MPESA_SECURITY_CREDENTIAL")!;
    const B2C_SHORTCODE = Deno.env.get("MPESA_B2C_SHORTCODE")!;
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;

    const auth = btoa(`${CONSUMER_KEY}:${CONSUMER_SECRET}`);
    const tokenRes = await fetch(
      "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      { headers: { Authorization: `Basic ${auth}` } },
    );
    const { access_token } = await tokenRes.json();

    const b2cRes = await fetch(
      "https://sandbox.safaricom.co.ke/mpesa/b2c/v1/paymentrequest",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${access_token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          InitiatorName: INITIATOR_NAME,
          SecurityCredential: SECURITY_CREDENTIAL,
          CommandID: "BusinessPayment",
          Amount: Math.round(payment.amount),
          PartyA: B2C_SHORTCODE,
          PartyB: landlord.phone,
          Remarks: "AltavasHomes rent payout",
          QueueTimeOutURL: `${SUPABASE_URL}/functions/v1/mpesa-b2c-result`,
          ResultURL: `${SUPABASE_URL}/functions/v1/mpesa-b2c-result`,
          Occasion: "Rent payout",
        }),
      },
    );

    const b2cResult = await b2cRes.json();

    await supabase
      .from("payments")
      .update({
        payout_status: b2cResult.ResponseCode === "0" ? "processing" : "failed",
        payout_reference: b2cResult.ConversationID ?? null,
      })
      .eq("id", payment.id);
  } catch (_e) {
    await supabase
      .from("payments")
      .update({ payout_status: "failed" })
      .eq("id", payment.id);
  }
}

serve(async (req) => {
  try {
    const body = await req.json();
    const callback = body?.Body?.stkCallback;

    if (!callback) {
      return new Response(JSON.stringify({ received: true }), { status: 200 });
    }

    const checkoutRequestId = callback.CheckoutRequestID;
    const resultCode = callback.ResultCode;

    if (resultCode === 0) {
      const items = callback.CallbackMetadata?.Item ?? [];
      const get = (name: string) =>
        items.find((i: { Name: string }) => i.Name === name)?.Value;

      const receiptNumber = get("MpesaReceiptNumber");

      const { data: payment } = await supabase
        .from("payments")
        .update({
          status: "completed",
          receipt_number: receiptNumber ?? null,
          paid_at: new Date().toISOString(),
        })
        .eq("transaction_reference", checkoutRequestId)
        .select("id, landlord_id, amount")
        .single();

      if (payment) {
        // Fire the payout, but don't block Safaricom's callback response on it.
        payoutToLandlord(payment);
      }
    } else {
      await supabase
        .from("payments")
        .update({ status: "failed" })
        .eq("transaction_reference", checkoutRequestId);
    }

    return new Response(JSON.stringify({ received: true }), { status: 200 });
  } catch (error) {
    return new Response(JSON.stringify({ received: true, error: error.message }), {
      status: 200,
    });
  }
});
