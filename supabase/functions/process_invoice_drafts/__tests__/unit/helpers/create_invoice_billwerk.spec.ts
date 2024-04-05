import { denock } from "https://deno.land/x/denock@0.2.0/mod.ts";
import createInvoiceBillwerk from "../../../helpers/create_invoice_billwerk.ts";
import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { REEPAY_API_URL, TRANSFER_PROTOCOL } from "../../../../_shared/environment.ts";
Deno.test("createInvoiceBillwerk returns a billwerk invoice", async () => {
  // Arrange
  const expectedData = {
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

  const sampleInvoice = {
    id: 1,
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

  denock({
    method: "POST", //denock expects http | https, not https://
    protocol: TRANSFER_PROTOCOL.split('://')[0] as "http" | "https",
    host: REEPAY_API_URL,
    path: `/v1/subscription/sub1/invoice`,
    replyStatus: 200,
    responseBody: expectedData,
  });

  // Act
  const response = await createInvoiceBillwerk(sampleInvoice);

  // Assert
  response.error && console.error(response.error);

  assertEquals(response.data, expectedData);
});
