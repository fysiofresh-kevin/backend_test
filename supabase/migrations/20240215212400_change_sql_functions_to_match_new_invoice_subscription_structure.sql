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
            'subscription_id', invoices.subscription_id,
            'client', get_client_by_invoice(invoices.id)
                     ))
    INTO v_invoices
    FROM invoices;
    RETURN COALESCE(v_invoices, '{}');
END;
$$ LANGUAGE plpgsql;


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
             INNER JOIN public.subscriptions ON invoices.subscription_id = subscriptions.id
             INNER JOIN public.user_profile u ON subscriptions.client_id = u.user_id
    WHERE invoices.id = invoice_id_param;

    RETURN COALESCE(v_client, '{}');
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION draft_invoices_for_period(DATE, DATE);
DROP FUNCTION mark_invoice_as_pending(INTEGER[]);
DROP FUNCTION draft_invoice_for_client(DATE, DATE, UUID);
DROP FUNCTION collect_draft_invoice_data_for_processing(INTEGER[]);

DROP FUNCTION public.get_all_employees(UUID);
DROP FUNCTION public.get_all_clients(UUID);
CREATE OR REPLACE FUNCTION public.get_all_users(target_role text)
    RETURNS SETOF jsonb
    LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
        SELECT JSONB_BUILD_OBJECT(
                       'id', client_profile.user_id,
                       'email', get_user_email(client_profile.user_id::text),
                       'name', client_profile.name
               )
        FROM user_has_role
                 JOIN public.user_profile client_profile ON
                user_has_role.user_id = client_profile.user_id
        WHERE
                role = target_role;
END
$function$;

CREATE OR REPLACE FUNCTION public.get_appointments_for_user(user_id_param uuid)
    RETURNS TABLE(appointment jsonb)
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
        SELECT
            JSONB_BUILD_OBJECT(
                    'id', appointments.id,
                    'client', JSONB_BUILD_OBJECT('id', appointments.client_id, 'email', get_user_email(appointments.client_id::text), 'name', client_profile.name),
                    'employee', JSONB_BUILD_OBJECT('id', appointments.employee_id, 'email', get_user_email(appointments.employee_id::text), 'name', employee_profile.name),
                    'services', (
                        SELECT jsonb_agg(service_id)
                        FROM public.appointment_has_services
                        WHERE appointment_id = appointments.id
                    ),
                    'start', appointments.start,
                    'end', appointments.end,
                    'status', appointments.status,
                    'notes', appointments.notes) as appointment
        FROM appointments
             JOIN public.user_profile client_profile ON appointments.client_id = client_profile.user_id
             JOIN public.user_profile employee_profile ON appointments.employee_id = employee_profile.user_id
        WHERE
            CASE
                WHEN appointments.client_id = user_id_param THEN true
                WHEN appointments.employee_id = user_id_param THEN true
                ELSE check_user_has_permission(user_id_param, ARRAY['appointment:read', 'appointment:admin'])
                END;
END;
$$;

CREATE or REPLACE FUNCTION upsert_appointment (
    p_appointment_json JSONB,
    p_service_ids integer[]
) returns boolean as $$
DECLARE
    _id integer;
    _client_id uuid;
    _employee_id uuid;
    _start timestamp;
    _end timestamp;
    _notes text;
    _status appointment_status;
    _service_ids  int[] := '{}';
    _service_id int;
BEGIN
    _id := (p_appointment_json ->> 'id')::integer;
    _client_id := (p_appointment_json ->> 'client_id')::uuid;
    _employee_id := (p_appointment_json ->> 'employee_id')::uuid;
    _start := (p_appointment_json ->> 'start')::timestamp;
    _end := (p_appointment_json ->> 'end')::timestamp;
    _notes := p_appointment_json ->> 'notes';
    _status := p_appointment_json ->> 'status';

    -- Upsert appointment in db
    INSERT INTO appointments (id, client_id, employee_id, "start", "end", notes, "status")
    VALUES (
               _id,
               _client_id,
               _employee_id,
               _start,
               _end,
               _notes,
               _status)
    ON CONFLICT (id)
        DO
            UPDATE SET
                       client_id =_client_id,
                       employee_id = _employee_id,
                       "start" = _start,
                       "end" = _end,
                       notes = _notes,
                       "status" = _status;

    _service_ids := p_service_ids;
    -- Insert added services
    FOREACH _service_id IN ARRAY _service_ids
        LOOP
            INSERT INTO appointment_has_services (appointment_id, service_id)
            VALUES (_id, _service_id)
            ON CONFLICT (appointment_id, service_id) DO NOTHING;
        END LOOP;

    -- Delete removed services
    DELETE FROM appointment_has_services
    WHERE appointment_id = _id AND service_id NOT IN (SELECT unnest(p_service_ids));
    RETURN true;
EXCEPTION
    WHEN OTHERS THEN
        -- Error handling (log the error, perhaps)
        RETURN SQLERRM;
END;
$$ language plpgsql;