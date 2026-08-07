import { serve } from "https://deno.land/std@0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

serve(async (req) => {
  try {
    const body = await req.json();
    const result = body?.Result;

    if (result) {
      const conversationId = result.ConversationID;
      const success = result.ResultCode === 0;

      await supabase
        .from("payments")
        .update({ payout_status: success ? "completed" : "failed" })
        .eq("payout_reference", conversationId);
    }

    return new Response(JSON.stringify({ received: true }), { status: 200 });
  } catch (error) {
    return new Response(JSON.stringify({ received: true, error: error.message }), {
      status: 200,
    });
  }
});
