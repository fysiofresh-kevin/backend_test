import { iTimePeriodPrototype } from "../create_invoice_drafts_for_period.ts";
import {
  iApi,
  iAppointment,
  iInvoiceCreated,
  iInvoiceHasAppointments,
  iTimePeriod,
} from "./api.ts";

export interface iSubscriptionHasAppointment {
  appointments: iAppointment[];
  subscription_id: string;
}
export interface iAppointmentsWithSubscriptions {
  subscription_id: string;
  appointments: iAppointment[];
}

async function getAppointmentsWithSubscriptionToProcess(
  supabase: iApi,
  period: iTimePeriodPrototype,
): Promise<iAppointmentsWithSubscriptions[]> {
  const user_id = period.user_id;
  //Collect all invoices, between start and end that are also completed.
  let appointments: iAppointment[] = await supabase
    .getCompletedAppointmentsWithinPeriod(period);
  const appointmentIds = appointments.map((x) => x.id);
  let appointmentFilterData = await supabase
    .getInvoicesHasAppointmentsByAppointmentIds(appointmentIds);
  //Filter appointments - returns all invoices who are NOT currently invoiced.
  appointments = appointments.filter((x) => {
    const idx = appointmentFilterData.findIndex((y) =>
      y.appointment_id == x.id
    );
    if (idx == -1) return x;
  }) as iAppointment[];

  //Get relevant clients from appointments.
  const clients = appointments.map((x) => {
    return x.client_id;
  });
  //Make client list distinct to avoid duplicates.
  let uniqueClients: string[] = [];
  clients.forEach((x) => {
    //returns -1 if x is not in the client list.
    const idx = uniqueClients.findIndex((y) => y == x);
    if (idx == -1) uniqueClients.push(x);
  });
  if (user_id) {
    //Filter uniqueClients to only contain user_id
    uniqueClients = [user_id];
  }

  //Get subscriptions for each client.
  const subscriptions = await supabase.getSubscriptionsByClientIds(
    uniqueClients,
  );
  //Map subscription to client
  const appointmentsWithSubscriptions: iAppointmentsWithSubscriptions[] = [];
  for (const key in uniqueClients) {
    const client = uniqueClients[key];
    const obj = {
      // @ts-ignore
      subscription_id: subscriptions.find((x) => x.client_id == client).id,
      appointments: filterAppointmentsForUserByClientId(client, appointments),
    } as iAppointmentsWithSubscriptions;
    if (obj.subscription_id) {
      appointmentsWithSubscriptions.push(obj);
    }
  }
  return appointmentsWithSubscriptions;
}
export function filterAppointmentsForUserByClientId(
  client_id: string,
  appointments: iAppointment[],
): iAppointment[] {
  return appointments.filter((x) => {
    if (x.client_id === client_id) return x;
  });
}
export function mapAppointmentsToInvoice(
  invoice: iInvoiceCreated,
  subHasAppointments: iSubscriptionHasAppointment[],
): iInvoiceHasAppointments[] {
  //@ts-ignore
  const appointmentsFound = subHasAppointments.find((x) =>
    x.subscription_id == invoice.subscription_id
  );
  if (appointmentsFound) {
    const invoiceHasAppointments: iInvoiceHasAppointments[] = [];
    const invoice_id = invoice.id;
    const appointments = appointmentsFound.appointments;
    for (const key in appointments) {
      const appointment = appointments[key];
      const invoiceHasAppointment = {
        invoice_id: invoice_id,
        appointment_id: appointment.id,
      };
      invoiceHasAppointments.push(invoiceHasAppointment);
    }
    return invoiceHasAppointments;
  } else {
    const errorMsg = "consistency error between invoice and subscriptions list";
    console.log(errorMsg);
    throw new Error(errorMsg);
  }
}
function buildInvoiceHasAppointmentsArray(
  createdInvoices: iInvoiceCreated[],
  subHasAppointmentsToCreate: iSubscriptionHasAppointment[],
) {
  let invoiceHasAppointments: iInvoiceHasAppointments[] = [];
  for (const key in createdInvoices) {
    const invoice = createdInvoices[key];
    const result = mapAppointmentsToInvoice(
      invoice,
      subHasAppointmentsToCreate,
    );
    invoiceHasAppointments = invoiceHasAppointments.concat(result);
  }
  return invoiceHasAppointments;
}
export const helper = {
  getAppointmentsWithSubscriptionToProcess,
  buildInvoiceHasAppointmentsArray,
};
