import BillwerkRequest from "../../../_shared/models/BillwerkRequest.ts";
import { settle_invoice_module } from "../../helpers/settle_invoice.ts";
import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { supabase } from "../../../_shared/supabase/supabase.ts";
import {
  assertSpyCall,
  assertSpyCalls,
  stub,
} from "https://deno.land/std@0.215.0/testing/mock.ts";
import { getUpdateWithEqMock } from "../../../_shared/__tests__/supabaseMockProviders.ts";
import { api } from "../../../_shared/billwerk/api.ts";

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
const test_valid_invoice = async () => {
  // Arrange
  // To simplify the test we're excluding unused response fields in our mock.
  const billwerkResponseMock = {
    status: 200,
    data: { state: "settled" },
  };

  const getInvoiceFromBillwerkStub = stub(
    api,
    "get_invoice_from_billwerk",
    //@ts-ignore
    () => billwerkResponseMock,
  );
  const supabaseResponseMock = { data: null, error: null } as any;
  const fromStubReturn = getUpdateWithEqMock(supabaseResponseMock);
  const fromStub = stub(
    supabase,
    "from",
    //@ts-ignore
    () => fromStubReturn,
  );

  // Act
  const { status } = await settle_invoice_module.settle_invoice(request);

  // Assert
  assertSpyCall(getInvoiceFromBillwerkStub, 0, {
    args: [request],
    //@ts-ignore
    returned: billwerkResponseMock,
  });
  assertSpyCall(fromStub, 0, {
    args: ["invoices"],
    //@ts-ignore
    returned: fromStubReturn,
  });
  assertSpyCalls(fromStub, 1);
  assertEquals(status, 200);

  //Restore
  getInvoiceFromBillwerkStub.restore();
  fromStub.restore();
};
Deno.test("should respond status 200 - Invoice Settled", test_valid_invoice);
const test_invoice_not_settled = async () => {
  // Arrange
  const billwerkResponseMock = {
    status: 200,
    data: { state: "booked" },
  };

  const getInvoiceFromBillwerkStub = stub(
    api,
    "get_invoice_from_billwerk",
    //@ts-ignore
    () => billwerkResponseMock,
  );

  // Act
  const { status } = await settle_invoice_module.settle_invoice(request);

  // Assert
  assertEquals(status, 400);
  getInvoiceFromBillwerkStub.restore();
};
Deno.test(
  "should respond status 400 - Invoice not settled",
  test_invoice_not_settled,
);

const test_supabase_error = async () => {
  // Arrange
  // To simplify the test we're excluding unused response fields in our mock.
  const billwerkResponseMock = {
    status: 200,
    data: { state: "settled" },
  };

  const getInvoiceFromBillwerkStub = stub(
    api,
    "get_invoice_from_billwerk",
    //@ts-ignore
    () => billwerkResponseMock,
  );
  const supabaseResponseMock = { data: null, error: {} } as any;
  const fromStubReturn = getUpdateWithEqMock(supabaseResponseMock);
  const fromStub = stub(
    supabase,
    "from",
    //@ts-ignore
    () => fromStubReturn,
  );

  // Act
  const { status } = await settle_invoice_module.settle_invoice(request);

  //Assert
  assertEquals(status, 500);

  //Restore
  getInvoiceFromBillwerkStub.restore();
  fromStub.restore();
};
Deno.test("should respond status 500 - supabase error", test_supabase_error);
