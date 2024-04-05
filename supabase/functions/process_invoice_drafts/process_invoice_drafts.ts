import {
  createClient,
  SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2.39.3";
import createInvoiceDinero from "./helpers/create_invoice_dinero.ts";
import createInvoiceBillwerk from "./helpers/create_invoice_billwerk.ts";
import IBillwerkResponse from "./model/BillwerkResponse.ts";
import { IDineroResponse } from "./helpers/create_invoice_dinero.ts";
import { corsHeaders } from "../_shared/cors.ts";
import {TRANSFER_PROTOCOL, SUPABASE_URL, SUPABASE_ANON_KEY } from "../_shared/environment.ts";

interface IResponse {
  billwerk: IBillwerkResponse;
  dinero: IDineroResponse;
}

export function createServerDbClient(accessToken: string) {
  return createClient(
      `${TRANSFER_PROTOCOL}${SUPABASE_URL}`,
      SUPABASE_ANON_KEY,
    {
      db: {
        schema: "public",
      },
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
      global: {
        headers: {
          Authorization: accessToken,
        },
      },
    },
  );
}

const processInvoiceDrafts = async (
  req: Request,
  createServerDbClient: (accessToken: string) => SupabaseClient,
) => {
  const supabase = createServerDbClient(req.headers.get("Authorization")!);
  const invoices = (await req.json()) as { id: string }[];

  const responses: IResponse[] = [];

  for (let i = 0; i < invoices.length; i++) {
    const { data, error } = await supabase
      .from("invoices")
      .select(`
        *,
        order_lines (service, price, discount)
      `)
      .eq("id", invoices[i]);

    if (error) {
      console.error("ERROR GETTING INVOICES", error);
      return new Response(JSON.stringify({ error }), {
        headers: { ...corsHeaders },
        status: 500,
      });
    }

    if (data.length === 0) {
      console.error("INVOICE NOT FOUND");
      return new Response(JSON.stringify({ message: "invoice not found" }), {
        headers: { ...corsHeaders },
        status: 404,
      });
    }

    if (data) {
      // Create Dinero invoice
      const { data: dineroInvoice, error: dineroError } =
        await createInvoiceDinero(data[0]);
      if (dineroError) {
        console.error("DINERO_ERROR: ", dineroError);
        return new Response(JSON.stringify({ error: dineroError }), {
          headers: { ...corsHeaders },
          status: 500,
        });
      }
      if (dineroInvoice) {
        const { error } = await supabase
          .from("invoices")
          .update({ dinero_id: dineroInvoice.Guid })
          .eq("id", invoices[i]);

        if (error) {
          console.error("SUPABASE_ERROR: ", error);
          return new Response(JSON.stringify({ error }), {
            headers: { ...corsHeaders },
            status: 500,
          });
        }
      }

      // Create Billwerk Invoice
      const { data: billwerkInvoice, error: billwerkError } =
        await createInvoiceBillwerk(data[0]);
      if (billwerkError) {
        console.error("BILLWERK_ERROR: ", billwerkError);
        return new Response(
          JSON.stringify({
            error: billwerkError.message,
            message: billwerkError.cause,
          }),
          {
            headers: { ...corsHeaders },
            status: 500,
          },
        );
      }

      if (billwerkInvoice) {
        const { error } = await supabase
          .from("invoices")
          .update({ billwerk_id: billwerkInvoice.id, status: "booked" })
          .eq("id", invoices[i]);

        if (error) {
          console.error("SUPABASE_ERROR: ", error);
          return new Response(JSON.stringify({ error }), {
            headers: { ...corsHeaders },
            status: 500,
          });
        }
      }
      responses.push({
        billwerk: billwerkInvoice as IBillwerkResponse,
        dinero: dineroInvoice!,
      });
    }
  }

  return new Response(JSON.stringify(responses), {
    status: 200,
    headers: { ...corsHeaders },
  });
};

export default processInvoiceDrafts;
