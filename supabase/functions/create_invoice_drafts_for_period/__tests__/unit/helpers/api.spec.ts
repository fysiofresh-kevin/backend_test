import {
  Api,
  iInvoiceCreated,
  iInvoiceHasAppointments,
  iInvoicePrototype,
} from "../../../helpers/api.ts";
import {
  assertSpyCall,
  assertSpyCalls,
  stub,
} from "https://deno.land/std@0.215.0/testing/mock.ts";
import {
  clientCreation,
  supabase,
} from "../../../../_shared/supabase/supabase.ts";
import { appointments } from "./test_data.ts";
import {
  getInsertMock,
  getInsertWithSelectMock,
  getSelectWithInMock,
} from "../../../../_shared/__tests__/supabaseMockProviders.ts";

const setup = () => {
  const clientCreationStub = stub(
    clientCreation,
    "createSupabaseClientWithAuthHeader",
    () => supabase,
  );
  return { clientCreationStub };
};
const teardown = (init: any) => {
  init.clientCreationStub.restore();
};
const test_constructor = async () => {
  //Arrange
  const authHeader = "Authorized user";

  const clientCreationStub = stub(
    clientCreation,
    "createSupabaseClientWithAuthHeader",
    () => supabase,
  );

  //Act
  new Api(authHeader);

  //Assert
  assertSpyCall(clientCreationStub, 0, {
    args: [authHeader],
    //@ts-ignore
    returned: supabase,
  });
  assertSpyCalls(clientCreationStub, 1);
  clientCreationStub.restore();
};
Deno.test(
  "should create supabase client with authheader on construction of api",
  test_constructor,
);
const test_getInvoicesHasAppointmentsByAppointmentIds = async () => {
  //Arrange
  const authHeader = "Authorized user";

  const init = setup();

  const appointmentIds = [0, 1, 2, 3];

  const query = "invoice_has_appointments";
  const responseMock = { data: [0, 1, 2], error: null } as any;
  const requestReturn = getSelectWithInMock(responseMock);

  const fromStub = stub(
    supabase,
    "from",
    //@ts-ignore
    () => requestReturn,
  );

  const sut = new Api(authHeader);

  //Act
  await sut.getInvoicesHasAppointmentsByAppointmentIds(appointmentIds);

  //Assert
  assertSpyCall(fromStub, 0, {
    args: [query],
    //@ts-ignore
    returned: requestReturn,
  });
  assertSpyCalls(fromStub, 1);
  teardown(init);
  fromStub.restore();
};
Deno.test(
  "should retrieve invoice_has_appointments",
  test_getInvoicesHasAppointmentsByAppointmentIds,
);
const test_getSubscriptionsByClientIds = async () => {
  //Arrange
  const authHeader = "Authorized user";

  const init = setup();

  const client_ids = ["0", "1", "2"];
  const subs = [
    {
      client_id: "0",
      id: "sub-0",
    },
    {
      client_id: "1",
      id: "sub-1",
    },
    {
      client_id: "2",
      id: "sub-2",
    },
  ];

  const query = "subscriptions";
  const responseMock = { data: subs, error: null } as any;
  const requestReturn = getSelectWithInMock(responseMock);

  const fromStub = stub(
    supabase,
    "from",
    //@ts-ignore
    () => requestReturn,
  );

  const sut = new Api(authHeader);

  //Act
  await sut.getSubscriptionsByClientIds(client_ids);

  //Assert
  assertSpyCall(fromStub, 0, {
    args: [query],
    //@ts-ignore
    returned: requestReturn,
  });
  assertSpyCalls(fromStub, 1);
  teardown(init);
  fromStub.restore();
};
Deno.test(
  "should retrieve subscriptions by client ids",
  test_getSubscriptionsByClientIds,
);
const test_getCompletedAppointmentsWithinPeriod = async () => {
  //Arrange
  const authHeader = "Authorized user";
  const init = setup();

  const period = {
    period_start: "2024-01-01",
    period_end: "2024-01-31",
  };

  const query = "appointments";
  const responseMock = { data: appointments, error: null } as any;
  const lteMock = () => Promise.resolve(responseMock);
  const gteMock = () => ({ lte: lteMock });
  const eqMock = () => ({ gte: gteMock });
  const selectMock = () => ({ eq: eqMock });
  const requestReturn = {
    select: selectMock,
  };

  const fromStub = stub(
    supabase,
    "from",
    //@ts-ignore
    () => requestReturn,
  );

  const sut = new Api(authHeader);

  //Act
  await sut.getCompletedAppointmentsWithinPeriod(period);

  //Assert
  assertSpyCall(fromStub, 0, {
    args: [query],
    //@ts-ignore
    returned: requestReturn,
  });
  assertSpyCalls(fromStub, 1);
  teardown(init);
  fromStub.restore();
};
Deno.test(
  "should retrieve appointments by period",
  test_getCompletedAppointmentsWithinPeriod,
);
const test_insertInvoices = async () => {
  //Arrange
  const authHeader = "Authorized user";

  const init = setup();

  const protoInvoices = [
    {} as iInvoicePrototype,
    {} as iInvoicePrototype,
    {} as iInvoicePrototype,
  ];
  const createdInvoices = [
    {} as iInvoiceCreated,
    {} as iInvoiceCreated,
    {} as iInvoiceCreated,
  ];

  const query = "invoices";
  const responseMock = { data: createdInvoices, error: null } as any;
  const requestReturn = getInsertWithSelectMock(responseMock);

  const fromStub = stub(
    supabase,
    "from",
    //@ts-ignore
    () => requestReturn,
  );

  const sut = new Api(authHeader);

  //Act
  await sut.insertInvoices(protoInvoices);

  //Assert
  assertSpyCall(fromStub, 0, {
    args: [query],
    //@ts-ignore
    returned: requestReturn,
  });
  assertSpyCalls(fromStub, 1);
  teardown(init);
  fromStub.restore();
};
Deno.test("should insert a list of invoices", test_insertInvoices);
const test_insertInvoiceHasAppointments = async () => {
  //Arrange
  const authHeader = "Authorized user";

  const init = setup();

  const invoiceHasAppointments = [
    {} as iInvoiceHasAppointments,
    {} as iInvoiceHasAppointments,
    {} as iInvoiceHasAppointments,
  ];

  const query = "invoice_has_appointments";
  const responseMock = { error: null } as any;
  const requestReturn = getInsertMock(responseMock);

  const fromStub = stub(
    supabase,
    "from",
    //@ts-ignore
    () => requestReturn,
  );

  const sut = new Api(authHeader);

  //Act
  await sut.insertInvoiceHasAppointments(invoiceHasAppointments);

  //Assert
  assertSpyCall(fromStub, 0, {
    args: [query],
    //@ts-ignore
    returned: requestReturn,
  });
  assertSpyCalls(fromStub, 1);
  teardown(init);
  fromStub.restore();
};
Deno.test(
  "should insert a list of invoices_has_appointments",
  test_insertInvoiceHasAppointments,
);
