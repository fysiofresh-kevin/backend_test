import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import processInvoiceDrafts from "../../process_invoice_drafts.ts";
import * as mf from "https://deno.land/x/mock_fetch@0.3.0/mod.ts";
import {
  expectedBillwerkData,
  expectedDineroData,
  sampleInvoice,
} from "../test_data/sample_data.ts";
import {DINERO_ORG_ID, SUPABASE_URL, TRANSFER_PROTOCOL} from "../../../_shared/environment.ts";
const test_process_invoice_drafts = async () => {
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

  mf.mock("POST@/v1/subscription/sub1/invoice", () => {
    return new Response(JSON.stringify(expectedBillwerkData), {
      status: 200,
    });
  });

  const organizationId = DINERO_ORG_ID;
  mf.mock(`POST@/v1/${organizationId}/invoices`, (_req) => {
    return new Response(JSON.stringify(expectedDineroData), {
      status: 201,
    });
  });

  const req = new Request(
    `${TRANSFER_PROTOCOL}${SUPABASE_URL}/v1/functions/process_invoice_drafts`,
    {
      body: JSON.stringify([sampleInvoice]),
      method: "POST",
    },
  );

  const mockCreateClient = (_access_token: string) => {
    return {
      from: () => ({
        update: () => ({
          eq: () => ({
            data: [sampleInvoice],
            error: null,
          }),
        }),
        select: () => ({
          eq: () => ({
            data: [sampleInvoice],
            error: null,
          }),
        }),
      }),
    };
  };

  // @ts-ignore Uses mockCreateClient which does not have the same return values as CreateSupabaseClient
  const res = await processInvoiceDrafts(req, mockCreateClient);
  const data = await res.json();

  assertEquals(res.status, 200);
  assertEquals(data, [
    {
      dinero: expectedDineroData,
      billwerk: expectedBillwerkData,
    },
  ]);
};

Deno.test("processInvoiceDrafts", test_process_invoice_drafts);
