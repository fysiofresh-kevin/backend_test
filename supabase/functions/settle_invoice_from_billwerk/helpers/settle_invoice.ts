import BillwerkRequest from "../../_shared/models/BillwerkRequest.ts";
import { api } from "../../_shared/billwerk/api.ts";
import { supabase } from "../../_shared/supabase/supabase.ts";

const settle_invoice = async (billwerkRequest: BillwerkRequest) => {
  const { status, data } = await api.get_invoice_from_billwerk(billwerkRequest);
  if (status != 200) {
    return {
      message: "Error: Unexpected error from billwerk",
      status: status,
    };
  }

  if (data.state !== "settled") {
    return {
      message: "Error: Invoice not settled",
      status: 400,
    };
  }

  const { error } = await supabase.from("invoices")
    .update({ "status": "settled" })
    .eq("billwerk_id", billwerkRequest.id);

  if (error) {
    return {
      message: error.message,
      status: 500,
    };
  } else {
    return {
      message: "Invoice Settled",
      status: 200,
    };
  }
};

export const settle_invoice_module = {
  settle_invoice,
};
