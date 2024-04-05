import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { denock } from "https://deno.land/x/denock@0.2.0/mod.ts";
import BillwerkRequest from "../../models/BillwerkRequest.ts";
import { api } from "../../billwerk/api.ts";
import {REEPAY_API_URL, TRANSFER_PROTOCOL} from "../../environment.ts";

const request: BillwerkRequest = {
  id: "81948d18ca218b028ca4f94c3530bfdf",
  timestamp: "2024-02-05T11:58:29.393Z",
  signature: "a8999e57388c80f717d7ca22cd1d0b76b2a8c446a75682b74413aab2e7644efd",
  invoice: "not_a_real_invoice",
  customer: "cust-0413",
  transaction: "a2e7005982854ee530fae4cfa13c6e4f",
  event_type: "invoice_settled",
  event_id: "22010b05049fa9cc0394371e01775530",
};

const test_get_invoice_from_billwerk = async () => {
  const billwerkResponseMock = { state: "settled" };

  denock({
    method: "GET",//denock expects http | https, not https://
    protocol: TRANSFER_PROTOCOL.split('://')[0]  as "http" | "https",
    host: REEPAY_API_URL,
    path: `/v1/invoice/${request.invoice}`,
    replyStatus: 200,
    responseBody: billwerkResponseMock,
  });

  const { status, data } = await api.get_invoice_from_billwerk(request);
  assertEquals(status, 200);
  assertEquals(data, billwerkResponseMock);
};
Deno.test(
  "should return invoice.state.settled",
  test_get_invoice_from_billwerk,
);
