CREATE OR REPLACE FUNCTION get_all_client_invoices() RETURNS JSONB[] AS
$$
DECLARE
    v_invoices JSONB[] := '{}';
BEGIN
    SELECT ARRAY_AGG(JSONB_BUILD_OBJECT(
            'id', invoices.id,
            'created_at', invoices.created_at,
            'from', invoices.from,
            'to', invoices.to,
            'billwerk_id', invoices.billwerk_id,
            'dinero_id', invoices.dinero_id,
            'status', invoices.status,
            'change_log', invoices.change_log,
            'subscription_id', subscription_has_invoices.subscription_id,
            'client', get_client_by_invoice(invoices.id)
                     ))
    INTO v_invoices
    FROM invoices
             INNER JOIN public.subscription_has_invoices subscription_has_invoices
                        ON invoices.id = subscription_has_invoices.invoice_id;
    RETURN COALESCE(v_invoices, '{}');
END;
$$ LANGUAGE plpgsql;

CREATE POLICY "Enable Admins to read all invoices" ON "public"."invoices" FOR SELECT USING
    ("public"."check_user_has_permission"("auth"."uid"(), '["invoices:read", "invoices:admin"]'::"jsonb"));

ALTER TABLE "public"."invoices"
    ENABLE ROW LEVEL SECURITY;


CREATE OR REPLACE FUNCTION get_client_by_invoice(invoice_id_param BIGINT) RETURNS JSONB AS
$$
DECLARE
    v_client JSONB := '{}';
BEGIN
    SELECT JSONB_BUILD_OBJECT(
                   'id', u.user_id,
                   'email', get_user_email(u.user_id::TEXT),
                   'name', u.name
           )
    INTO v_client
    FROM invoices
             INNER JOIN public.subscription_has_invoices ON invoices.id = subscription_has_invoices.invoice_id
             INNER JOIN public.subscriptions ON subscription_has_invoices.subscription_id = subscriptions.id
             INNER JOIN public.user_profile u ON subscriptions.client_id = u.user_id
    WHERE invoices.id = invoice_id_param;

    RETURN COALESCE(v_client, '{}');
END;
$$ LANGUAGE plpgsql;