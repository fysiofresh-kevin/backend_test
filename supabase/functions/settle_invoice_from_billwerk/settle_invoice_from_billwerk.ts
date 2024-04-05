import BillwerkRequest from "../_shared/models/BillwerkRequest.ts";
import Verify_signature from "./helpers/verify_signature.ts";
import { settle_invoice_module } from "./helpers/settle_invoice.ts";

export const settle_invoice_from_billwerk = async (
  billwerkRequest: BillwerkRequest,
) => {
  try {
    const { timestamp, id, signature } = billwerkRequest;

    if (!Verify_signature(timestamp, id, signature)) {
      return {
        message: "Error: Unauthorized",
        status: 401,
        error: null,
      };
    }

    if (billwerkRequest.event_type === "invoice_settled") {
      const { message, status } = await settle_invoice_module.settle_invoice(
        billwerkRequest,
      );
      return {
        message: message,
        status: status,
        error: null,
      };
    }

    return {
      message: "Error:  Bad request",
      status: 400,
      error: null,
    };
  } catch (error) {
    return {
      message: "SETTLE_INVOICE_ERROR",
      status: error.status,
      error: error,
    };
  }
};
