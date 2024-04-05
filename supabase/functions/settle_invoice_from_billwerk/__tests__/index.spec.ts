import { sample_data } from "./test_data/sample_data.ts";
import { assertEquals } from "https://deno.land/std@0.213.0/assert/assert_equals.ts";
import {
  assertSpyCall,
  assertSpyCalls,
  stub,
} from "https://deno.land/std@0.215.0/testing/mock.ts";
import { settle_invoice_from_billwerk } from "../settle_invoice_from_billwerk.ts";
import { settle_invoice_module } from "../helpers/settle_invoice.ts";

const test_invoice_settle_success = async () => {
  // Arrange
  const request = sample_data[0];

  const settleInvoiceReturn = {
    message: "Invoice Settled",
    status: 200,
  } as any;

  const settleInvoiceStub = stub(
    settle_invoice_module,
    "settle_invoice",
    //@ts-ignore
    () => settleInvoiceReturn,
  );

  // Act
  const { message, status, error } = await settle_invoice_from_billwerk(
    request,
  );

  if (error) {
    throw new Error(`${message}: ${error.message}`);
  }

  // Assert
  assertSpyCall(settleInvoiceStub, 0, {
    args: [request],
    //@ts-ignore
    returned: settleInvoiceReturn,
  });
  assertSpyCalls(settleInvoiceStub, 1);
  assertEquals(status, 200);
  assertEquals(message, "Invoice Settled");
};

Deno.test("should settle invoice successfully", test_invoice_settle_success);
