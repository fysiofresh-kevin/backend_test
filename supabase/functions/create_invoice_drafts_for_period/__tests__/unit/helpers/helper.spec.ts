import {
  Api,
  iApi,
  iAppointment,
  iAppointmentIds,
  iInvoiceCreated,
  iInvoiceHasAppointments,
  iInvoicePrototype,
  iSubscription,
  iTimePeriod,
} from "../../../helpers/api.ts";
import {
  assertSpyCall,
  assertSpyCalls,
  stub,
} from "https://deno.land/std@0.215.0/testing/mock.ts";
import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  filterAppointmentsForUserByClientId,
  helper,
  iSubscriptionHasAppointment,
  mapAppointmentsToInvoice,
} from "../../../helpers/helper.ts";
import {
  appointments,
  invoice_has_appointments,
  subscriptions,
} from "./test_data.ts";
import { MockApi } from "./mockApi.ts";
import { describe, it } from "https://deno.land/std@0.220.0/testing/bdd.ts";
import { iTimePeriodPrototype } from "../../../create_invoice_drafts_for_period.ts";
describe("helper", () => {
  describe("getAppointmentsWithSubscriptionToProcess", () => {
    it("should retrieve uninvoiced appointments with associated subscriptions", async () => {
      //Arrange
      const api = new MockApi();

      const expectedAppointmentsForPeriod = appointments;
      const expectedPeriod = {
        period_start: "2024-01-01",
        period_end: "2024-01-32",
      };
      const appointmentsForPeriodStub = stub(
        api,
        "getCompletedAppointmentsWithinPeriod",
        //@ts-ignore
        () => Promise.resolve(expectedAppointmentsForPeriod),
      );

      const appointmentsFilterData: iAppointmentIds[] =
        invoice_has_appointments;
      const expectedAppointmentIds: number[] =
        expectedAppointmentsForPeriod.map((x) => x.id);
      const appointmentsFilterDataStub = stub(
        api,
        "getInvoicesHasAppointmentsByAppointmentIds",
        //@ts-ignore
        () => Promise.resolve(appointmentsFilterData)
      );

      const subscriptionReturns: iSubscription[] = subscriptions;

      const uniqueClients: string[] = ["client-1", "client-2"];

      const subscriptionsStub = stub(
        api,
        "getSubscriptionsByClientIds",
        //@ts-ignore
        () => Promise.resolve(subscriptionReturns)
      );

      const expectedResponse = [
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

      //Act
      const response = await helper.getAppointmentsWithSubscriptionToProcess(
        api,
        expectedPeriod
      );

      //Assert
      assertSpyCall(appointmentsForPeriodStub, 0, {
        args: [expectedPeriod],
        //@ts-ignore
        returned: Promise.resolve(expectedAppointmentsForPeriod),
      });
      assertSpyCalls(appointmentsForPeriodStub, 1);

      assertSpyCall(appointmentsFilterDataStub, 0, {
        args: [expectedAppointmentIds],
        //@ts-ignore
        returned: Promise.resolve(appointmentsFilterData),
      });
      assertSpyCalls(appointmentsFilterDataStub, 1);

      assertSpyCall(subscriptionsStub, 0, {
        args: [uniqueClients],
        //@ts-ignore
        returned: Promise.resolve(subscriptionReturns),
      });
      assertSpyCalls(subscriptionsStub, 1);
      assertEquals(response, expectedResponse);
      //restore
      appointmentsForPeriodStub.restore();
      appointmentsFilterDataStub.restore();
      subscriptionsStub.restore();
    });
    it("should retrieve uninvoiced appointments with associated subscriptions for a singular user_id", async () => {
      //Arrange
      const api = new MockApi();

      const expectedAppointmentsForPeriod = appointments;
      const expectedPeriod: iTimePeriodPrototype = {
        period_start: "2024-01-01",
        period_end: "2024-01-32",
        user_id: "client-1"
      };
      const appointmentsForPeriodStub = stub(
        api,
        "getCompletedAppointmentsWithinPeriod",
        //@ts-ignore
        () => Promise.resolve(expectedAppointmentsForPeriod),
      );

      const appointmentsFilterData: iAppointmentIds[] =
        invoice_has_appointments;
      const expectedAppointmentIds: number[] =
        expectedAppointmentsForPeriod.map((x) => x.id);
      const appointmentsFilterDataStub = stub(
        api,
        "getInvoicesHasAppointmentsByAppointmentIds",
        //@ts-ignore
        () => Promise.resolve(appointmentsFilterData),
      );

      const subscriptionReturns: iSubscription[] = subscriptions;

      const uniqueClients: string[] = ["client-1"];

      const subscriptionsStub = stub(
        api,
        "getSubscriptionsByClientIds",
        //@ts-ignore
        () => Promise.resolve(subscriptionReturns),
      );

      const expectedResponse = [
        {
          subscription_id: "sub-1",
          appointments: [
            { id: 2, client_id: "client-1" },
            { id: 4, client_id: "client-1" },
          ],
        },
      ];

      //Act
      const response = await helper.getAppointmentsWithSubscriptionToProcess(
        api,
        expectedPeriod,
      );

      //Assert
      assertSpyCall(appointmentsForPeriodStub, 0, {
        args: [expectedPeriod],
        //@ts-ignore
        returned: Promise.resolve(expectedAppointmentsForPeriod),
      });
      assertSpyCalls(appointmentsForPeriodStub, 1);

      assertSpyCall(appointmentsFilterDataStub, 0, {
        args: [expectedAppointmentIds],
        //@ts-ignore
        returned: Promise.resolve(appointmentsFilterData),
      });
      assertSpyCalls(appointmentsFilterDataStub, 1);

      assertSpyCall(subscriptionsStub, 0, {
        args: [uniqueClients],
        //@ts-ignore
        returned: Promise.resolve(subscriptionReturns),
      });
      assertSpyCalls(subscriptionsStub, 1);
      assertEquals(response, expectedResponse);
      //restore
      appointmentsForPeriodStub.restore();
      appointmentsFilterDataStub.restore();
      subscriptionsStub.restore();
    });
  });
});

const test_filterAppointmentsForUserByClientId = async () => {
  //Arrange
  const client_id = "client-1";
  const exampleAppointments = [
    { id: 0, client_id: "client-1" },
    { id: 1, client_id: "client-2" },
    { id: 2, client_id: "client-1" },
    { id: 3, client_id: "client-2" },
    { id: 4, client_id: "client-1" },
  ];
  const expectedFilteredAppointments = [
    { id: 0, client_id: "client-1" },
    { id: 2, client_id: "client-1" },
    { id: 4, client_id: "client-1" },
  ];

  //Act
  const result = filterAppointmentsForUserByClientId(
    client_id,
    exampleAppointments,
  );

  //Assert
  assertEquals(result, expectedFilteredAppointments);
};
Deno.test(
  "should filter appointments by client id",
  test_filterAppointmentsForUserByClientId,
);

const test_mapAppointmentsToInvoices = async () => {
  //Arrange
  const invoice: iInvoiceCreated = {
    id: 0,
    subscription_id: "sub-1",
  };
  const subHasAppointments: iSubscriptionHasAppointment[] = [
    {
      appointments: [
        { id: 1, client_id: "client-1" } as iAppointment,
        { id: 2, client_id: "client-1" } as iAppointment,
      ],
      subscription_id: "sub-1",
    },
  ];
  const expectedResult: iInvoiceHasAppointments[] = [
    {
      appointment_id: 1,
      invoice_id: 0,
    },
    {
      appointment_id: 2,
      invoice_id: 0,
    },
  ];

  //Act
  const result = mapAppointmentsToInvoice(invoice, subHasAppointments);

  //Assert
  assertEquals(result, expectedResult);
};
Deno.test(
  "should map appointments to invoices",
  test_mapAppointmentsToInvoices,
);

const test_buildInvoiceHasAppointmentsToCreate = async () => {
  //Arrange
  const invoices: iInvoiceCreated[] = [
    {
      id: 0,
      subscription_id: "sub-1",
    },
    {
      id: 1,
      subscription_id: "sub-2",
    },
  ];
  const subHasAppointments: iSubscriptionHasAppointment[] = [
    {
      appointments: [
        { id: 1, client_id: "client-1" } as iAppointment,
        { id: 2, client_id: "client-1" } as iAppointment,
      ],
      subscription_id: "sub-1",
    },
    {
      appointments: [{ id: 4, client_id: "client-2" } as iAppointment],
      subscription_id: "sub-2",
    },
  ];
  const expectedResult: iInvoiceHasAppointments[] = [
    {
      appointment_id: 1,
      invoice_id: 0,
    },
    {
      appointment_id: 2,
      invoice_id: 0,
    },
    {
      appointment_id: 4,
      invoice_id: 1,
    },
  ];

  //Act
  const result: iInvoiceHasAppointments[] = helper
    .buildInvoiceHasAppointmentsArray(invoices, subHasAppointments);

  //Assert
  assertEquals(result, expectedResult);
};
Deno.test(
  "should create a list of invoice_has_appoinments, that map what appointments have been invoiced",
  test_buildInvoiceHasAppointmentsToCreate,
);
