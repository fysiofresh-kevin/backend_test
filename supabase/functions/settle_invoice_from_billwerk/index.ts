import BillwerkRequest from "../_shared/models/BillwerkRequest.ts";
import { settle_invoice_from_billwerk } from "./settle_invoice_from_billwerk.ts";

Deno.serve(async (req) => {
  const billwerkRequest = await req.json() as BillwerkRequest;
  const { message, status } = await settle_invoice_from_billwerk(
    billwerkRequest,
  );
  return new Response(message, {
    status,
  });
});
