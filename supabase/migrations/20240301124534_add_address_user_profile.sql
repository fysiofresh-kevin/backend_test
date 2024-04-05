CREATE OR REPLACE FUNCTION get_client_by_invoice(invoice_id_param BIGINT) RETURNS JSONB AS
$$
DECLARE
    v_client JSONB := '{}';
BEGIN
    SELECT JSONB_BUILD_OBJECT(
                   'id', u.user_id,
                   'email', get_user_email(u.user_id::TEXT),
                   'name', u.name,
                   'address', u.address
           )
    INTO v_client
    FROM invoices
             INNER JOIN public.subscriptions ON invoices.subscription_id = subscriptions.id
             INNER JOIN public.user_profile u ON subscriptions.client_id = u.user_id
    WHERE invoices.id = invoice_id_param;

    RETURN COALESCE(v_client, '{}');
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION public.get_all_users(target_role text)
    RETURNS SETOF jsonb
    LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
        SELECT JSONB_BUILD_OBJECT(
                       'id', client_profile.user_id,
                       'email', get_user_email(client_profile.user_id::text),
                       'name', client_profile.name,
                       'address', client_profile.address
               )
        FROM user_has_role
                 JOIN public.user_profile client_profile ON
                user_has_role.user_id = client_profile.user_id
        WHERE
                role = target_role;
END
$function$;