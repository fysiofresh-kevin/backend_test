import BillwerkRequest from "../models/BillwerkRequest.ts";
import {REEPAY_API_KEY, REEPAY_API_URL, TRANSFER_PROTOCOL} from "../../_shared/environment.ts";
export interface iBillwerkInvoiceResponse {
  state: string;
}

const base64ApiKey = btoa(`${REEPAY_API_KEY}:`);

async function get_invoice_from_billwerk(billwerkRequest: BillwerkRequest) {
  const invoiceId = billwerkRequest.invoice;
  const url = `${TRANSFER_PROTOCOL}${REEPAY_API_URL}/v1/invoice/${invoiceId}`;

  const response = await fetch(url, {
    method: "GET",
    headers: {
      "Authorization": `Basic ${base64ApiKey}`,
      "Content-Type": "application/json",
    },
  });

  const status = response.status;
  let data: iBillwerkInvoiceResponse = { state: "not assigned" };
  if (response.ok) {
    data = await response.json();
  }
  return { status, data };
}

export const api = {
  get_invoice_from_billwerk,
};
