import { assertEquals } from "https://deno.land/std@0.213.0/assert/assert_equals.ts";
import {
  afterEach,
  beforeEach,
  describe,
  it,
} from "https://deno.land/std@0.220.0/testing/bdd.ts";
import {
  Api,
  iApi,
  iInvoiceHasAppointments,
  iInvoicePrototype,
  iTimePeriod,
} from "../../../helpers/api.ts";
import { supabaseServiceClient as supabase } from "../../../../_shared/supabase/supabase.ts";

export const cleanUp = async () => {
  await supabase.from("invoices").delete().neq("id", 0);
  await supabase.from("appointments").delete().neq("id", 0);
  await supabase.from("invoices_has_appointments").delete().neq("id", 0);
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
  await supabase.from("invoice_has_appointments").upsert({
    invoice_id: 1000,
    appointment_id: 1,
  });
};

describe(
  "API Helper for create_invoice_drafts_for_period",
  {
    sanitizeOps: false,
    sanitizeResources: false,
  },
  () => {
    let api: iApi;
    beforeEach(async () => {
      await cleanUp();
      await upsertTestData();
      const password = "Hybertz";
      const email = "integration@admin.dk";
      await supabase.auth.signInWithPassword({ email, password });
      const { data: authData } = await supabase.auth.getSession();
      const authHeader = authData.session?.access_token;
      api = new Api(`Bearer ${authHeader!}`);
    });
    afterEach(async () => {
      await cleanUp();
    });
    it("should get invoices has appointments by appointment ids", async () => {
      // Given a user is signed in and the DB is clean with specific data setup,
      // When getInvoicesHasAppointmentsByAppointmentIds is called with appointment id 1,
      // Then it should return an array with one invoice has appointments object with appointment_id 1.

      //Arrange & Act
      const res = await api.getInvoicesHasAppointmentsByAppointmentIds([1]);

      //Assert
      assertEquals(res.length, 1);
      assertEquals(res, [
        {
          appointment_id: 1,
        },
      ]);
    });
    it("should get subscriptions by client ids", async () => {
      // Given a user is signed in and the DB is clean with specific data setup,
      // When getSubscriptionsByClientIds is called with a specific client id,
      // Then it should return an array with one subscription object for that client id.
      //Arrange

      //Act
      const res = await api.getSubscriptionsByClientIds([
        "77f089d8-66f5-40b2-9520-fb494350b7a3",
      ]);

      //Assert
      assertEquals(res.length, 1);
      assertEquals(res, [
        {
          id: "fake-sub-1",
          client_id: "77f089d8-66f5-40b2-9520-fb494350b7a3",
        },
      ]);
    });
    it("should get completed appointments within period", async () => {
      // Given a user is signed in and the DB is clean with specific data setup,
      // When getCompletedAppointmentsWithinPeriod is called with a specific time period,
      // Then it should return an array with one completed appointment within that period.
      //Arrange
      const period: iTimePeriod = {
        period_start: "2021-01-01T00:00:00.000Z",
        period_end: "2021-01-01T01:00:00.000Z",
      };
      //Act
      const res = await api.getCompletedAppointmentsWithinPeriod(period);
      //Assert
      assertEquals(res.length, 1);
    });
    it("should insert invoices", async () => {
      // Given a user is signed in and the DB is clean with specific data setup,
      // When insertInvoices is called with a test invoice prototype,
      // Then it should insert the invoice and return an array with the inserted invoice object.
      //Arrange
      const testInvoices: iInvoicePrototype[] = [
        {
          status: "draft",
          from: "2024-01-01T01:00:00.000Z",
          to: "2024-01-31T01:00:00.000Z",
          subscription_id: "fake-sub-1",
        },
      ];
      //Act
      const res = await api.insertInvoices(testInvoices);
      //Assert
      assertEquals(res[0].subscription_id, "fake-sub-1");
      assertEquals(res.length, 1);
    });
    it("insert invoice has appointments", async () => {
      // Given a user is signed in and the DB is clean with specific data setup,
      // When insertInvoiceHasAppointments is called with a test invoice has appointments object,
      // Then it should insert the invoice has appointments and the DB should have one corresponding entry.
      //Arrange
      await supabase.from("invoices").upsert({
        id: 2,
        status: "draft",
        from: "2024-01-01",
        to: "2024-01-31",
        subscription_id: "fake-sub-1",
      });
      const testInvoiceHasAppointments: iInvoiceHasAppointments[] = [
        {
          invoice_id: 2,
          appointment_id: 2,
        },
      ];
      //Act
      await api.insertInvoiceHasAppointments(testInvoiceHasAppointments);
      const { data } = await supabase.from("invoice_has_appointments").select()
        .eq("invoice_id", 2);
      //Assert
      assertEquals(data!.length, 1);
    });
  },
);
