import processInvoiceDrafts from "./process_invoice_drafts.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { createServerDbClient } from "./process_invoice_drafts.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: { ...corsHeaders },
    });
  }

  return await processInvoiceDrafts(req, createServerDbClient);
});
