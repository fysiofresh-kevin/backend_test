import createInvoiceDinero from "../../../helpers/create_invoice_dinero.ts";
import * as mf from "https://deno.land/x/mock_fetch@0.3.0/mod.ts";
import { assertEquals } from "https://deno.land/std@0.61.0/testing/asserts.ts";
import { DINERO_ORG_ID } from "../../../../_shared/environment.ts";

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
  subscription_has_invoices: [{ subscription_id: 0, invoice_id: 0 }],
};

const expectedData = {
  Guid: "a279611a-8647-40fc-a452-e1bbb0d38cda",
  TimeStamp: "2024-01-24T12:39:46.000Z",
};

Deno.test("createInvoiceDinero returns a dinero invoice", async () => {
  // Arrange
  mf.install();

  mf.mock("POST@/dineroapi/oauth/token", (_req) => {
    return new Response(
      JSON.stringify({
        access_token: "value",
        expires_in: 3600,
        refresh_token: "",
        token_type: "Bearer",
      }),
      {
        status: 200,
      },
    );
  });

  const organizationId = DINERO_ORG_ID;
  mf.mock(`POST@/v1/${organizationId}/invoices`, (_req) => {
    return new Response(JSON.stringify(expectedData), {
      status: 201,
    });
  });

  // Act
  const response = await createInvoiceDinero(sampleInvoice);

  // Assert
  assertEquals(response.data, expectedData);
});
