import {
  afterEach,
  beforeEach,
  describe,
  it,
} from "https://deno.land/std@0.220.0/testing/bdd.ts";
import { supabaseServiceClient as supabase } from "../../../_shared/supabase/supabase.ts";
import {
  assertEquals,
  assertNotEquals,
} from "https://deno.land/std@0.61.0/testing/asserts.ts";
import { assertExists } from "https://deno.land/std@0.192.0/testing/asserts.ts";

const cleanUp = async () => {
  await supabase.from("invoices").delete().neq("id", 0);
  await supabase.from("order_lines").delete().neq("id", 0);
};

export const upsertTestData = async () => {
  await supabase.from("subscriptions").upsert({
    id: "fake-sub-1",
    status: "active",
    client_id: "77f089d8-66f5-40b2-9520-fb494350b7a3",
  });
  await supabase.from("invoices").insert({
    id: 1000,
    status: "draft",
    from: "2020-01-01",
    to: "2023-01-31",
    subscription_id: "fake-sub-1",
  });
  await supabase.from("appointments").upsert([
    {
      id: 1,
      client_id: "77f089d8-66f5-40b2-9520-fb494350b7a3",
      status: "completed",
      start: "2021-01-01T00:00:00.000Z",
      end: "2021-01-01T01:00:00.000Z",
    },
    {
      id: 2,
      client_id: "77f089d8-66f5-40b2-9520-fb494350b7a3",
      status: "completed",
      start: "2022-01-01T00:00:00.000Z",
      end: "2022-01-01T01:00:00.000Z",
    },
  ]);
  await supabase.from("order_lines").upsert([{
    invoice_id: 1000,
    appointment_id: 1,
    service: "Hjemmebehandling",
    price: 450,
    discount: 10,
  }, {
    invoice_id: 1000,
    appointment_id: 2,
    service: "Telefonkonsultation",
    price: 250,
    discount: 0,
  }]);
};

describe("process_invoice_drafts", {
  sanitizeOps: false,
  sanitizeResources: false,
}, () => {
  beforeEach(async () => {
    await cleanUp();
    await upsertTestData();
  });
  afterEach(async () => {
    await cleanUp();
  });
  it("should return billwerk and dinero data", async () => {
    const { data, error } = await supabase.functions.invoke(
      "process_invoice_drafts",
      {
        body: [1000],
      },
    );

    assertEquals(error, null);
    assertEquals(JSON.parse(data).length, 1);
    assertExists(JSON.parse(data)[0].billwerk);
    assertExists(JSON.parse(data)[0].dinero);
  });
  it("should return error if invoice is not found", async () => {
    const { data, error } = await supabase.functions.invoke(
      "process_invoice_drafts",
      {
        body: [1001],
      },
    );

    assertNotEquals(error, null);
    assertEquals(data, null);
  });
  it("should add billwerk and dinero data to existing invoice", async () => {
    await supabase.functions.invoke(
      "process_invoice_drafts",
      {
        body: [1000],
      },
    );

    const { data, error } = await supabase.from("invoices").select();

    assertNotEquals(data, null);
    assertEquals(error, null);
    assertEquals(data![0].billwerk_id, "sample-id");
    assertEquals(data![0].dinero_id, "1234567890");
  });
});
