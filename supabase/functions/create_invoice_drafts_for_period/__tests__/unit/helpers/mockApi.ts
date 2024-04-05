import {
  iApi,
  iAppointment,
  iAppointmentIds,
  iInvoiceCreated,
  iInvoiceHasAppointments,
  iInvoicePrototype,
  iSubscription,
  iTimePeriod,
} from "../../../helpers/api.ts";

export class MockApi implements iApi {
  getCompletedAppointmentsWithinPeriod(
    period: iTimePeriod,
  ): Promise<iAppointment[]> {
    throw new Error("not intended for actual use");
  }

  getInvoicesHasAppointmentsByAppointmentIds(
    appointmentIds: number[],
  ): Promise<iAppointmentIds[]> {
    throw new Error("not intended for actual use");
  }

  getSubscriptionsByClientIds(client_ids: string[]): Promise<iSubscription[]> {
    throw new Error("not intended for actual use");
  }

  insertInvoiceHasAppointments(
    invoiceHasAppointments: iInvoiceHasAppointments[],
  ): Promise<void> {
    throw new Error("not intended for actual use");
  }

  insertInvoices(invoices: iInvoicePrototype[]): Promise<iInvoiceCreated[]> {
    throw new Error("not intended for actual use");
  }
}
