import { helper, iSubscriptionHasAppointment } from "./helpers/helper.ts";
import {
  ApiHelper,
  iAppointment,
  iInvoiceCreated,
  iInvoiceHasAppointments,
  iInvoicePrototype,
  iTimePeriod,
} from "./helpers/api.ts";

export interface iTimePeriodPrototype extends iTimePeriod {
  user_id?: string;
}

export const create_invoice_drafts_for_period = async (
  authHeader: any,
  params: iTimePeriodPrototype,
) => {
  try {
    //Create the supabase client instance
    const supabase = ApiHelper.createApiInstance(authHeader);
    const appointmentsWithSubscriptions = await helper
      .getAppointmentsWithSubscriptionToProcess(supabase, params);

    //Create invoice Objects pr. client. Also map each subscription to an invoice, since we don't have invoice IDs at this point.
    const invoicesToCreate: iInvoicePrototype[] = [];
    const subHasAppointmentsToCreate: iSubscriptionHasAppointment[] = [];
    for (const key in appointmentsWithSubscriptions) {
      const appointmentsForUser: iAppointment[] =
        appointmentsWithSubscriptions[key].appointments;
      const subscription_id =
        appointmentsWithSubscriptions[key].subscription_id;
      const invoice = {
        from: params.period_start,
        to: params.period_end,
        status: "draft",
        subscription_id: subscription_id,
      } as iInvoicePrototype;

      const invoiceHasAppointments = {
        appointments: appointmentsForUser,
        subscription_id: subscription_id,
      } as iSubscriptionHasAppointment;
      subHasAppointmentsToCreate.push(invoiceHasAppointments);
      invoicesToCreate.push(invoice);
    }

    //Insert created invoices into DB.
    const createdInvoices: iInvoiceCreated[] = await supabase.insertInvoices(
      invoicesToCreate,
    );

    //Map appointments to created invoices by subscriptionId.
    const invoiceHasAppointments: iInvoiceHasAppointments[] = helper
      .buildInvoiceHasAppointmentsArray(
        createdInvoices,
        subHasAppointmentsToCreate,
      );

    //Insert invoiceHasAppointments objects
    await supabase.insertInvoiceHasAppointments(invoiceHasAppointments);

    return { status: 200 };
  } catch (err: any) {
    console.error(err.message);
    return { status: 500 };
  }
};
