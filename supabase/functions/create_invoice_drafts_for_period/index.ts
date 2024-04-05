import {
  type iTimePeriodPrototype,
  create_invoice_drafts_for_period,
  type iTimePeriodPrototype,
} from "./create_invoice_drafts_for_period.ts";
import { corsHeaders } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: { ...corsHeaders },
    });
  }
  const authHeader = req.headers.get("Authorization")!;
  const request = await req.json() as iTimePeriodPrototype;
  const { status } = await create_invoice_drafts_for_period(
    authHeader,
    request,
  );
  return new Response("request was processed", {
    status,
    headers: { ...corsHeaders },
  });
});
