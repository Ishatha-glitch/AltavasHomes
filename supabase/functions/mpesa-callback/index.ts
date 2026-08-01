import { serve } from "https://deno.land/std@0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

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
      // Successful payment — pull receipt number and paid amount out of the metadata array
      const items = callback.CallbackMetadata?.Item ?? [];
      const get = (name: string) =>
        items.find((i: { Name: string }) => i.Name === name)?.Value;

      const receiptNumber = get("MpesaReceiptNumber");

      await supabase
        .from("payments")
        .update({
          status: "completed",
          receipt_number: receiptNumber ?? null,
          paid_at: new Date().toISOString(),
        })
        .eq("transaction_reference", checkoutRequestId);
    } else {
      // User cancelled, timed out, or it otherwise failed
      await supabase
        .from("payments")
        .update({ status: "failed" })
        .eq("transaction_reference", checkoutRequestId);
    }

    // Safaricom just needs a 200 response — it doesn't read the body
    return new Response(JSON.stringify({ received: true }), { status: 200 });
  } catch (error) {
    return new Response(JSON.stringify({ received: true, error: error.message }), {
      status: 200,
    });
  }
});
