interface IBillwerkResponse {
  id: string;
  handle: string;
  customer: string;
  subscription: string;
  state: "pending" | "settled";
  type: string;
  amount: number;
  number: number;
  currency: string;
  due: string;
  credits: [];
  created: string;
  dunning_plan: string;
  discount_amount: number;
  org_amount: number;
  amount_vat: number;
  amount_ex_vat: number;
  settled_amount: number;
  refunded_amount: number;
  order_lines: {
    id: string;
    ordertext: string;
    amount: number;
    vat: number;
    quantity: number;
    origin: string;
    timestamp: string;
    amount_vat: number;
    amount_ex_vat: number;
    unit_amount: number;
    unit_amount_vat: number;
    unit_amount_ex_vat: number;
    amount_defined_incl_vat: boolean;
  }[];
  additional_costs: [];
  transactions: [];
  credit_notes: [];
  billing_address: {
    address: string;
    city: string;
    country: string;
    email: string;
    phone: string;
    first_name: string;
    last_name: string;
    postal_code: string;
  };
}

export default IBillwerkResponse;
