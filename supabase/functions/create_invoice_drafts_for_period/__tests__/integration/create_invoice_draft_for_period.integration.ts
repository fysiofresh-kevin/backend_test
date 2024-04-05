import { supabaseServiceClient as supabase } from "../../../_shared/supabase/supabase.ts";
import { assertEquals } from "https://deno.land/std@0.213.0/assert/assert_equals.ts";
import { type iTimePeriod } from "../../helpers/api.ts";
import {
  beforeEach,
  describe,
  it,
} from "https://deno.land/std@0.220.0/testing/bdd.ts";
import { cleanUp, upsertTestData } from "./helpers/api.integration.ts";

describe("create_invoice_drafts_for_period", {
  sanitizeOps: false,
  sanitizeResources: false,
}, () => {
  beforeEach(async () => {
    await cleanUp();
    await upsertTestData();
  });
  it("should create invoice drafts for period", async () => {
    //Arrange
    const period: iTimePeriod = {
      period_start: "2021-01-01T00:00:00.000Z",
      period_end: "2021-01-04T01:00:00.000Z",
    };
    await supabase.from("appointments").upsert([
      {
        client_id: "77f089d8-66f5-40b2-9520-fb494350b7a3",
        status: "completed",
        start: "2021-01-01T00:00:00.000Z",
        end: "2021-01-01T01:00:00.000Z",
      },
      {
        client_id: "77f089d8-66f5-40b2-9520-fb494350b7a3",
        status: "completed",
        start: "2021-01-02T00:00:00.000Z",
        end: "2021-01-01T01:00:00.000Z",
      },
      {
        client_id: "77f089d8-66f5-40b2-9520-fb494350b7a3",
        status: "completed",
        start: "2021-01-03T00:00:00.000Z",
        end: "2021-01-01T01:00:00.000Z",
      },
    ]);

    const invoiceCount =
      (await supabase.from("invoices").select()).data!.length;

    //Act
    const { error } = await supabase.functions.invoke(
      "create_invoice_drafts_for_period",
      {
        body: period,
      },
    );
    const { data } = await supabase.from("invoices").select();

    //Assert
    assertEquals(error, null);
    assertEquals(data!.length, invoiceCount + 1);
  });

  it("should create invoice drafts for period for a given user_id", async () => {
    //Arrange
    const period: iTimePeriod = {
      period_start: "2021-01-01T00:00:00.000Z",
      period_end: "2021-01-04T01:00:00.000Z",
    };
    await supabase.from("appointments").upsert([
      {
        client_id: "77f089d8-66f5-40b2-9520-fb494350b7a3",
        status: "completed",
        start: "2021-01-01T00:00:00.000Z",
        end: "2021-01-01T01:00:00.000Z",
      },
      {
        client_id: "77f089d8-66f5-40b2-9520-fb494350b7a3",
        status: "completed",
        start: "2021-01-02T00:00:00.000Z",
        end: "2021-01-01T01:00:00.000Z",
      },
      {
        client_id: "7a38a993-93cf-462e-b8ad-52dd0b9c4022",
        status: "completed",
        start: "2021-01-03T00:00:00.000Z",
        end: "2021-01-01T01:00:00.000Z",
      },
    ]);

    const invoiceCount =
      (await supabase.from("invoices").select()).data!.length;

    //Act
    const { error } = await supabase.functions.invoke(
      "create_invoice_drafts_for_period",
      {
        body: {...period, user_id: "77f089d8-66f5-40b2-9520-fb494350b7a3" },
      },
    );
    const { data } = await supabase.from("invoices").select();

    //Assert
    assertEquals(error, null);
    assertEquals(data!.length, invoiceCount + 1);
  });

  it("should not create invoice drafts for period without appointments", async () => {
    //Arrange
    const period: iTimePeriod = {
      period_start: "2021-01-01T00:00:00.000Z",
      period_end: "2021-01-04T01:00:00.000Z",
    };

    const invoiceCount =
      (await supabase.from("invoices").select()).data!.length;

    //Act
    const { error } = await supabase.functions.invoke(
      "create_invoice_drafts_for_period",
      {
        body: period,
      },
    );
    const { data } = await supabase.from("invoices").select();

    //Assert
    assertEquals(error, null);
    assertEquals(data!.length, invoiceCount);
  });
});
