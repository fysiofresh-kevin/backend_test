type BillwerkRequest = {
  id: string;
  event_id: string;
  event_type:
    | "invoice_settled"
    | "invoice_cancelled"
    | "invoice_created"
    | "subscription_renewal"
    | "subscription_created";
  timestamp: Date | string;
  signature: string;
  customer?: string;
  payment_method?: string;
  payment_method_reference?: string;
  subscription?: string;
  invoice?: string;
  transaction?: string;
  credit_note?: string;
  credit?: string;
};

export default BillwerkRequest;
