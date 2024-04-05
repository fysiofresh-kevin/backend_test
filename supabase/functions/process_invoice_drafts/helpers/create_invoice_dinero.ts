import { IInvoiceWithOrderLines } from "../model/Invoice.ts";
import getBearerToken from "../../_shared/helpers/get_bearer_token.ts";
import { DINERO_ORG_ID, DINERO_API_URL, TRANSFER_PROTOCOL } from "../../_shared/environment.ts";
export interface IDineroResponse {
  Guid: string;
  TimeStamp: string;
}

interface IReturnValue {
  error?: Error;
  data?: IDineroResponse;
}

const createInvoiceDinero = async (
  invoice: IInvoiceWithOrderLines,
): Promise<IReturnValue> => {
  const { access_token: dineroBearer } = await getBearerToken();

  if (!dineroBearer) {
    console.error("ERROR GETTING DINERO BEARER TOKEN");
    return {
      error: new Error("No Dinero bearer token"),
    };
  }

  const headers = new Headers({
    Authorization: `Bearer ${dineroBearer}`,
    "Content-Type": "application/json",
  });

  const orderLines = invoice.order_lines.map((orderLine) => {
    return {
      description: orderLine.service,
      quantity: 1,
      accountNumber: 1000,
      discount: orderLine.discount,
      unit: "session",
      lineType: "Product",
      baseAmountValue: orderLine.price,
    };
  });

  const organizationId = DINERO_ORG_ID;
  const res = await fetch(
    `${TRANSFER_PROTOCOL}${DINERO_API_URL}/v1/${organizationId}/invoices`,
    {
      body: JSON.stringify({
        externalReference: invoice.subscription_id,
        description: `Invoice for subscription ${invoice.subscription_id}`,
        comment: "Here is a comment",
        productLines: orderLines,
        showLinesInclVat: true,
        contactGuid: "f8e8286a-9838-46f7-77c6-080dd66b67f4",
      }),
      headers,
      method: "POST",
    },
  );

  const data = await res.json();

  if (res.status === 201) {
    return { data };
  } else {
    console.error("ERROR CREATING DINERO INVOICE", data);
    return { error: new Error(res.statusText) };
  }
};

export default createInvoiceDinero;
