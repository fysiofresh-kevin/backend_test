import BillwerkRequest from "../../../_shared/models/BillwerkRequest.ts";

export const sample_data: BillwerkRequest[] = [
  {
    id: "81948d18ca218b028ca4f94c3530bfdf",
    timestamp: "2024-02-05T11:58:29.393Z",
    signature:
      "a8999e57388c80f717d7ca22cd1d0b76b2a8c446a75682b74413aab2e7644efd",
    invoice: "i-1707133862613",
    customer: "cust-0413",
    transaction: "a2e7005982854ee530fae4cfa13c6e4f",
    event_type: "invoice_settled",
    event_id: "22010b05049fa9cc0394371e01775530",
  },
  {
    id: "a42cbe7f01adc2a3f999e791a4f66666",
    timestamp: "2024-02-05T11:59:31.885Z",
    signature:
      "45cd5ad3cfb8376aedb91166ad2ed2b81e9eeb3a5364cdd49e4a33d7b3625853",
    invoice: "i-1707133811212",
    customer: "cust-0413",
    transaction: "8bbee4a2d8fb810b515ae1c84b0fcd29",
    event_type: "invoice_settled",
    event_id: "3b6df3bb3ea7f9d57e7034c3291366a8",
  },
];
