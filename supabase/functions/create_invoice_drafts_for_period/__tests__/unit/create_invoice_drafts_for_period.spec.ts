import { assertEquals } from "https://deno.land/std@0.213.0/assert/assert_equals.ts";
import {
  assertSpyCall,
  assertSpyCalls,
  stub,
} from "https://deno.land/std@0.215.0/testing/mock.ts";
import {
  helper,
  iAppointmentsWithSubscriptions,
  iSubscriptionHasAppointment,
} from "../../helpers/helper.ts";
import {
  ApiHelper,
  iInvoiceCreated,
  iInvoiceHasAppointments,
  iInvoicePrototype,
} from "../../helpers/api.ts";
import { exampleAppointmentWithSubscriptionOutput } from "./helpers/test_data.ts";
import { create_invoice_drafts_for_period } from "../../create_invoice_drafts_for_period.ts";
import { MockApi } from "./helpers/mockApi.ts";
import { describe, it } from "https://deno.land/std@0.220.0/testing/bdd.ts";

describe("Create Invoice Drafts For Period", () => {
  it("should create invoices and invoice_has_appointments", async () => {
    //Given a function invocation
    //When everything works as expected
    //Then the function creates the necessary data structures and returns 200.

    //Arrange
    const authHeader = "Authorized user";
    const period_start_string = "2024-01-01";
    const period_end_string = "2024-01-31";

    const period = {
      period_start: period_start_string,
      period_end: period_end_string,
    };

    const api = new MockApi();
    const createApiInstanceStub = stub(
      ApiHelper,
      "createApiInstance",
      //@ts-ignore
      () => api,
    );

    const appointmentsWithSubscriptions: iAppointmentsWithSubscriptions[] =
      exampleAppointmentWithSubscriptionOutput;

    const getAppointmentsWithSubscriptionToProcessStub = stub(
      helper,
      "getAppointmentsWithSubscriptionToProcess",
      //@ts-ignore
      () => Promise.resolve(appointmentsWithSubscriptions),
    );

    const invoicesToCreate: iInvoicePrototype[] = [
      {
        from: "2024-01-01",
        status: "draft",
        subscription_id: "sub-1",
        to: "2024-01-31",
      },
      {
        from: "2024-01-01",
        status: "draft",
        subscription_id: "sub-2",
        to: "2024-01-31",
      },
    ];
    const createdInvoices: iInvoiceCreated[] = [
      { id: 0, subscription_id: "sub-1" },
      { id: 1, subscription_id: "sub-2" },
    ];
    const insertInvoicesStub = stub(
      api,
      "insertInvoices",
      //@ts-ignore
      () => Promise.resolve(createdInvoices),
    );

    const subHasAppointmentsToCreate: iSubscriptionHasAppointment[] = [
      {
        appointments: [
          { id: 2, client_id: "client-1" },
          {
            id: 4,
            client_id: "client-1",
          },
        ],
        subscription_id: "sub-1",
      },
      {
        appointments: [{ id: 3, client_id: "client-2" }],
        subscription_id: "sub-2",
      },
    ];
    const invoiceHasAppointmentsToCreate: iInvoiceHasAppointments[] = [
      { appointment_id: 2, invoice_id: 0 },
      { appointment_id: 4, invoice_id: 0 },
      { appointment_id: 3, invoice_id: 1 },
    ];
    const buildInvoiceHasAppointmentsToCreateStub = stub(
      helper,
      "buildInvoiceHasAppointmentsArray",
      //@ts-ignore
      () => invoiceHasAppointmentsToCreate,
    );

    const insertInvoiceHasAppointmentsStub = stub(
      api,
      "insertInvoiceHasAppointments",
    );

    //Act
    const response = await create_invoice_drafts_for_period(authHeader, period);

    //Assert
    assertSpyCall(createApiInstanceStub, 0, {
      args: [authHeader],
      //@ts-ignore
      returned: api,
    });
    assertSpyCalls(createApiInstanceStub, 1);

    assertSpyCall(getAppointmentsWithSubscriptionToProcessStub, 0, {
      args: [api, period],
      //@ts-ignore
      returned: Promise.resolve(appointmentsWithSubscriptions),
    });
    assertSpyCalls(getAppointmentsWithSubscriptionToProcessStub, 1);

    assertSpyCall(insertInvoicesStub, 0, {
      args: [invoicesToCreate],
      //@ts-ignore
      returned: Promise.resolve(createdInvoices),
    });
    assertSpyCalls(insertInvoicesStub, 1);

    assertSpyCall(buildInvoiceHasAppointmentsToCreateStub, 0, {
      args: [createdInvoices, subHasAppointmentsToCreate],
      //@ts-ignore
      returned: invoiceHasAppointmentsToCreate,
    });
    assertSpyCalls(buildInvoiceHasAppointmentsToCreateStub, 1);

    assertSpyCall(insertInvoiceHasAppointmentsStub, 0, {
      args: [invoiceHasAppointmentsToCreate],
    });
    assertSpyCalls(insertInvoiceHasAppointmentsStub, 1);

    assertEquals(response, { status: 200 });
    createApiInstanceStub.restore();
    getAppointmentsWithSubscriptionToProcessStub.restore();
    insertInvoicesStub.restore();
    buildInvoiceHasAppointmentsToCreateStub.restore();
    insertInvoiceHasAppointmentsStub.restore();
  });
  it("should create invoices and invoice_has_appointments for singular client", async () => {
    //Given a function invocation
    //When everything works as expected
    //Then the function creates the necessary data structures and returns 200.

    //Arrange
    const authHeader = "Authorized user";
    const period_start_string = "2024-01-01";
    const period_end_string = "2024-01-31";

    const period = {
      period_start: period_start_string,
      period_end: period_end_string,
      user_id: "client-1",
    };

    const api = new MockApi();
    const createApiInstanceStub = stub(
      ApiHelper,
      "createApiInstance",
      //@ts-ignore
      () => api,
    );

    const appointmentsWithSubscriptions: iAppointmentsWithSubscriptions[] = [
      exampleAppointmentWithSubscriptionOutput[0],
    ];

    const getAppointmentsWithSubscriptionToProcessStub = stub(
      helper,
      "getAppointmentsWithSubscriptionToProcess",
      //@ts-ignore
      () => Promise.resolve(appointmentsWithSubscriptions),
    );

    const invoicesToCreate: iInvoicePrototype[] = [
      {
        from: "2024-01-01",
        status: "draft",
        subscription_id: "sub-1",
        to: "2024-01-31",
      },
    ];
    const createdInvoices: iInvoiceCreated[] = [
      { id: 0, subscription_id: "sub-1" },
    ];
    const insertInvoicesStub = stub(
      api,
      "insertInvoices",
      //@ts-ignore
      () => Promise.resolve(createdInvoices),
    );

    const subHasAppointmentsToCreate: iSubscriptionHasAppointment[] = [
      {
        appointments: [
          { id: 2, client_id: "client-1" },
          {
            id: 4,
            client_id: "client-1",
          },
        ],
        subscription_id: "sub-1",
      },
    ];
    const invoiceHasAppointmentsToCreate: iInvoiceHasAppointments[] = [
      { appointment_id: 2, invoice_id: 0 },
      { appointment_id: 4, invoice_id: 0 },
      { appointment_id: 3, invoice_id: 1 },
    ];
    const buildInvoiceHasAppointmentsToCreateStub = stub(
      helper,
      "buildInvoiceHasAppointmentsArray",
      //@ts-ignore
      () => invoiceHasAppointmentsToCreate,
    );

    const insertInvoiceHasAppointmentsStub = stub(
      api,
      "insertInvoiceHasAppointments",
    );

    //Act
    const response = await create_invoice_drafts_for_period(authHeader, period);

    //Assert
    assertSpyCall(createApiInstanceStub, 0, {
      args: [authHeader],
      //@ts-ignore
      returned: api,
    });
    assertSpyCalls(createApiInstanceStub, 1);

    assertSpyCall(getAppointmentsWithSubscriptionToProcessStub, 0, {
      args: [api, period],
      //@ts-ignore
      returned: Promise.resolve(appointmentsWithSubscriptions[0]),
    });
    assertSpyCalls(getAppointmentsWithSubscriptionToProcessStub, 1);

    assertSpyCall(insertInvoicesStub, 0, {
      args: [invoicesToCreate],
      //@ts-ignore
      returned: Promise.resolve(createdInvoices),
    });
    assertSpyCalls(insertInvoicesStub, 1);

    assertSpyCall(buildInvoiceHasAppointmentsToCreateStub, 0, {
      args: [createdInvoices, subHasAppointmentsToCreate],
      //@ts-ignore
      returned: invoiceHasAppointmentsToCreate,
    });
    assertSpyCalls(buildInvoiceHasAppointmentsToCreateStub, 1);

    assertSpyCall(insertInvoiceHasAppointmentsStub, 0, {
      args: [invoiceHasAppointmentsToCreate],
    });
    assertSpyCalls(insertInvoiceHasAppointmentsStub, 1);

    assertEquals(response, { status: 200 });
    createApiInstanceStub.restore();
    getAppointmentsWithSubscriptionToProcessStub.restore();
    insertInvoicesStub.restore();
    buildInvoiceHasAppointmentsToCreateStub.restore();
    insertInvoiceHasAppointmentsStub.restore();
  });
  it("should not throw error, instead return 500", async () => {
    //Given a function invocation
    //When something goes wrong
    //Then the function aborts and returns status 500.

    //Arrange
    const authHeader = "Authorized user";
    const period_start_string = "2024-01-01";
    const period_end_string = "2024-01-31";

    const period = {
      period_start: period_start_string,
      period_end: period_end_string,
    };

    //since we aren't stubbing the mockAPI it will cause an error.
    const api = new MockApi();
    const createApiInstanceStub = stub(
      ApiHelper,
      "createApiInstance",
      //@ts-ignore
      () => api,
    );

    //Act
    const response = await create_invoice_drafts_for_period(authHeader, period);

    //Assert
    assertEquals(response, { status: 500 });
    createApiInstanceStub.restore();
  });
});

