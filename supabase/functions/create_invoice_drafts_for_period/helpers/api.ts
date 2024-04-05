import { clientCreation } from "../../_shared/supabase/supabase.ts";
export interface iTimePeriod {
  period_start: string;
  period_end: string;
}
export interface iSubscription {
  id: string;
  client_id: string;
}
export interface iInvoiceCreated {
  id: number;
  subscription_id: string;
}
export interface iInvoicePrototype {
  from: string;
  to: string;
  status: "draft";
  subscription_id: string;
}
export interface iAppointment {
  id: number;
  client_id: string;
}

export interface iAppointmentIds {
  appointment_id: number;
}
export interface iInvoiceHasAppointments {
  appointment_id: number;
  invoice_id: number;
}
export interface iApi {
  getInvoicesHasAppointmentsByAppointmentIds(
    appointmentIds: number[],
  ): Promise<iAppointmentIds[]>;
  getSubscriptionsByClientIds(client_ids: string[]): Promise<iSubscription[]>;
  getCompletedAppointmentsWithinPeriod(
    period: iTimePeriod,
  ): Promise<iAppointment[]>;
  insertInvoices(invoices: iInvoicePrototype[]): Promise<iInvoiceCreated[]>;
  insertInvoiceHasAppointments(
    invoiceHasAppointments: iInvoiceHasAppointments[],
  ): Promise<void>;
}
const createApiInstance = (authHeader: string): iApi => {
  return new Api(authHeader);
};
export class Api implements iApi {
  supabase: any;
  constructor(authHeader: string) {
    this.supabase = clientCreation.createSupabaseClientWithAuthHeader(
      authHeader,
    );
  }
  async getInvoicesHasAppointmentsByAppointmentIds(
    appointmentIds: number[],
  ): Promise<iAppointmentIds[]> {
    const { data, error } = await this.supabase
      .from("invoice_has_appointments")
      .select("appointment_id")
      .in("appointment_id", appointmentIds);

    if (error) {
      console.log("is appointment invoiced collection error");
      console.log(error);
      throw new Error(error);
    }
    return data;
  }
  async getSubscriptionsByClientIds(
    client_ids: string[],
  ): Promise<iSubscription[]> {
    const { data, error } = await this.supabase
      .from("subscriptions")
      .select(`id, client_id`)
      .in("client_id", client_ids);

    if (error) {
      console.log("collect subscriptions by clients error");
      console.log(error);
      throw new Error(error);
    }
    return data;
  }
  async getCompletedAppointmentsWithinPeriod(
    period: iTimePeriod,
  ): Promise<iAppointment[]> {
    const isoStart = new Date(period.period_start).toISOString();
    const isoEnd = new Date(period.period_end).toISOString();
    const { data, error } = await this.supabase
      .from("appointments")
      .select(`
            id, client_id
        `)
      .eq("status", "completed")
      .gte("start", isoStart)
      .lte("end", isoEnd);

    if (error) {
      console.log("appointment collection error");
      console.log(error);
      throw new Error(error);
    }
    return data;
  }
  async insertInvoices(
    invoices: iInvoicePrototype[],
  ): Promise<iInvoiceCreated[]> {
    const { data, error } = await this.supabase
      .from("invoices")
      .insert(invoices)
      .select(`id, subscription_id`);

    if (error) {
      console.error("create invoice error");
      console.error(error);
      throw new Error(error.message);
    }
    return data;
  }
  async insertInvoiceHasAppointments(
    invoiceHasAppointments: iInvoiceHasAppointments[],
  ): Promise<void> {
    const { error } = await this.supabase
      .from("invoice_has_appointments")
      .insert(invoiceHasAppointments);
    if (error) {
      console.log("create invoice has appointment error");
      console.log(error);
      throw new Error(error);
    }
  }
}

export const ApiHelper = {
  createApiInstance,
};
