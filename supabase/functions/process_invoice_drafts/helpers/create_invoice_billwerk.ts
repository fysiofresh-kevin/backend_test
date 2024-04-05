import IBillwerkResponse from "../model/BillwerkResponse.ts";
import { IInvoiceWithOrderLines } from "../model/Invoice.ts";
import {REEPAY_API_KEY, REEPAY_API_URL, TRANSFER_PROTOCOL} from "../../_shared/environment.ts";
interface IReturnValue {
  error?: Error;
  data?: IBillwerkResponse;
}

const createInvoiceBillwerk = async (
  invoice: IInvoiceWithOrderLines,
): Promise<IReturnValue> => {
  const encodedCredentials = btoa(`${REEPAY_API_KEY}:`)
    .toString();

  const headers = new Headers({
    "Authorization": `Basic ${encodedCredentials}`,
    "Content-Type": "application/json",
  });

  const orderLines = invoice.order_lines.map((orderLine) => {
    return {
      ordertext: orderLine.service,
      amount: orderLine.price * 100,
      vat: 0.25,
      quantity: 1,
      amount_incl_vat: "true",
    };
  });

  const url = `${TRANSFER_PROTOCOL}${REEPAY_API_URL}/v1/subscription/${invoice.subscription_id}/invoice`;
  const res = await fetch(
    url,
    {
      body: JSON.stringify({
        handle: 123123, //invoice.id,
        due: "2023-10-16T15:00:00",
        order_lines: orderLines,
        billing_address: {
          address: "Københavns gade 42, 2th.",
          city: "aalborg",
          country: "DK",
          email: "test@bruger.com",
          phone: "66666666",
          first_name: "Carl",
          last_name: "Johnson",
          postal_code: "4531",
        },
      }),
      headers,
      method: "POST",
    },
  );

  const data = await res.json();

  if (res.status === 200) {
    return { data: data };
  } else {
    console.log("createInvoiceBillwerk error", data);
    return {
      error: new Error(data.http_reason, { cause: data.error }),
    };
  }
};

export default createInvoiceBillwerk;
