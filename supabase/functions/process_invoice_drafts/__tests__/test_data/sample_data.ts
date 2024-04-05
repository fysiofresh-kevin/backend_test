const sampleInvoice = {
  id: 10,
  created_at: "2024-01-24 12:39:46+00",
  from: "2024-01-24 12:39:46+00",
  to: "2024-01-31 12:39:51+00",
  billwerk_id: "bw1",
  dinero_id: "dn1",
  status: "pending",
  change_log: "initial creation",
  subscription_id: "sub1",
  order_lines: [
    {
      service: "Hjemmebehandling",
      price: 490,
      discount: 10,
    },
  ],
  client: {
    id: 101,
    email: "kj@casual.com",
    name: "Karl Johan",
  },
};

const expectedBillwerkData = {
  id: "47d0ee9fa48f46d5beae4b71655e58fb",
  handle: "kev-test-1",
  customer: "cust-0413",
  subscription: "fake-sub-3",
  state: "pending",
  type: "so",
  amount: 49000,
  number: 409,
  currency: "DKK",
  due: "2023-10-16T13:00:00.000+00:00",
  credits: [],
  created: "2024-02-13T09:31:30.231+00:00",
  dunning_plan: "dunning_plan_fcc5",
  discount_amount: 0,
  org_amount: 49000,
  amount_vat: 9800,
  amount_ex_vat: 39200,
  settled_amount: 0,
  refunded_amount: 0,
  order_lines: [
    {
      id: "275a37b94248aca376f9cff8ea99afdf",
      ordertext: "Hjemmebehandling",
      amount: 49000,
      vat: 0.25,
      quantity: 1,
      origin: "ondemand",
      timestamp: "2024-02-13T09:31:30.231+00:00",
      amount_vat: 9800,
      amount_ex_vat: 39200,
      unit_amount: 49000,
      unit_amount_vat: 9800,
      unit_amount_ex_vat: 39200,
      amount_defined_incl_vat: true,
    },
  ],
  additional_costs: [],
  transactions: [],
  credit_notes: [],
  billing_address: {
    address: "Københavns gade 42, 2th.",
    city: "aalborg",
    country: "DK",
    email: "test@bruger.com",
    phone: "66666666",
    first_name: "Carl",
    last_name: "Johnson",
    postal_code: "4531",
  },
};

const expectedDineroData = {
  Guid: "a279611a-8647-40fc-a452-e1bbb0d38cda",
  TimeStamp: "2024-01-24T12:39:46.000Z",
};

export { expectedBillwerkData, expectedDineroData, sampleInvoice };
