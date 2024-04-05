import {
  iAppointment,
  iAppointmentIds,
  iSubscription,
} from "../../../helpers/api.ts";
import { iAppointmentsWithSubscriptions } from "../../../helpers/helper.ts";

export const appointments: iAppointment[] = [
  { id: 0, client_id: "client-1" },
  { id: 1, client_id: "client-2" },
  { id: 2, client_id: "client-1" },
  { id: 3, client_id: "client-2" },
  { id: 4, client_id: "client-1" },
];

export const invoice_has_appointments: iAppointmentIds[] = [
  { appointment_id: 0 },
  { appointment_id: 1 },
];

export const subscriptions: iSubscription[] = [
  {
    id: "sub-1",
    client_id: "client-1",
  },
  {
    id: "sub-2",
    client_id: "client-2",
  },
];

export const exampleAppointmentWithSubscriptionOutput:
  iAppointmentsWithSubscriptions[] = [
    {
      subscription_id: "sub-1",
      appointments: [
        { id: 2, client_id: "client-1" },
        { id: 4, client_id: "client-1" },
      ],
    },
    {
      subscription_id: "sub-2",
      appointments: [{ id: 3, client_id: "client-2" }],
    },
  ];
