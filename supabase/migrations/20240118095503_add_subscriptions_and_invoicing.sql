create table
public.subscriptions (
    id text not null,
    created_at timestamp with time zone not null default now(),
    last_paid timestamp with time zone null,
    status text not null default 'draft'::text,
    client_id uuid not null,
    constraint subscriptions_pkey primary key (id),
    constraint subscriptions_client_id_fkey foreign key (client_id) references auth.users (id) on update cascade
) tablespace pg_default;

create table
public.invoices (
    id bigint generated by default as identity,
    created_at timestamp with time zone not null default now(),
    "from" timestamp with time zone not null,
    "to" timestamp with time zone not null,
    billwerk_id text null,
    dinero_id text null,
    status text null,
    change_log jsonb null,
    constraint invoices_pkey primary key (id),
    constraint invoices_billwerk_id_key unique (billwerk_id),
    constraint invoices_dinero_id_key unique (dinero_id)
) tablespace pg_default;

create table
public.invoice_has_appointments (
    invoice_id bigint not null,
    appointment_id bigint not null,
    constraint invoice_has_appointments_pkey primary key (invoice_id, appointment_id),
    constraint invoice_has_appointments_invoice_id_fkey foreign key (invoice_id) references invoices (id) on update cascade on delete cascade,
    constraint invoice_has_appointments_appointment_id_fkey foreign key (appointment_id) references appointments (id) on update cascade on delete cascade
) tablespace pg_default;

create table
public.subscription_has_invoices (
    subscription_id text not null,
    invoice_id bigint not null,
    constraint subscription_has_invoices_pkey primary key (subscription_id, invoice_id),
    constraint subscription_has_invoices_invoice_id_fkey foreign key (invoice_id) references invoices (id) on update cascade on delete cascade,
    constraint subscription_has_invoices_subscription_id_fkey foreign key (subscription_id) references subscriptions (id) on update cascade on delete cascade
) tablespace pg_default;

create function public.draft_invoices_for_period
(
    period_start date,
    period_end date
) RETURNS jsonb[] AS $$
    --return a json object with what's been processed and whether it was considered successful or not.
DECLARE
    clients uuid[];
    reports jsonb[];
    --exception handling - return list of reports.
BEGIN
    SELECT array_agg(user_id) into clients
    FROM user_has_role
    WHERE
    roles @> '["client"]';

    reports := '{}';

    FOR i IN 1..array_length(clients, 1) LOOP
        reports := array_append(
                reports,
                draft_invoice_for_client
                (
        period_start,
        period_end,
            clients[i]
                )
        );
        RAISE NOTICE 'creating for client: %', reports;
        end loop;
    return reports;
END;
$$ language plpgsql;

create function public.draft_invoice_for_client
(
    period_start date,
    period_end date,
    client uuid
) RETURNS jsonb as $$
    --return a json object with what's been processed and whether it was considered successful or not.
DECLARE
    v_appointment_ids integer[];
    v_loop_id integer;
    v_invoice_id integer;
    v_subscription_id text;
    v_success bool := false;
    report jsonb;
BEGIN

    --collect all client-appointments for period, that are not already invoiced
    SELECT array_agg(a.id) into v_appointment_ids
    FROM appointments a
    WHERE
        a.start <= period_end AND
        a.end >= period_start AND
        a.status = 'completed' AND
        a.client_id = client AND
        a.id NOT IN (SELECT appointment_id FROM invoice_has_appointments);

    --if no appointments found, return report.
    IF v_appointment_ids IS NULL THEN
        report := jsonb_build_object(
                  'client', client,
                  'success', v_success,
                  'message', 'no eligible appointments found for period'
                  );
        return report;
    END IF;

    --collect subscription by client id
    SELECT id INTO v_subscription_id
    FROM subscriptions
    WHERE client_id = client AND subscriptions.status = 'ACTIVE';

    --if no subscription set flag.
    IF v_subscription_id IS NULL THEN
        report := jsonb_build_object(
                'client', client,
                'success', v_success,
                'message', 'No subscription found'
                );
        return report;
    END IF;

    --create entry in invoices, status:draft
    INSERT INTO invoices
        (status, "from", "to")
    VALUES
        ('draft', period_start, period_end)
    RETURNING id INTO v_invoice_id;

    --create entry in subscription_has_invoices, mapping new invoice to subscription
    INSERT INTO subscription_has_invoices
        (subscription_id, invoice_id)
    VALUES
        (v_subscription_id, v_invoice_id);

    --create entry in invoice_has_appointments, mapping collected appointments to new invoice
    FOREACH v_loop_id IN ARRAY v_appointment_ids
        LOOP
            INSERT INTO invoice_has_appointments (invoice_id, appointment_id)
            VALUES (v_invoice_id, v_loop_id);
        END LOOP;

    v_success := true;
    report := jsonb_build_object(
            'client', client,
            'subscription_id', v_subscription_id,
            'invoice_id', v_invoice_id,
            'success', v_success,
            'appointments_linked', v_appointment_ids);
    return report;
EXCEPTION
    WHEN OTHERS THEN
        report := jsonb_build_object('client', client, 'success', v_success, 'error', SQLERRM);
        RETURN report;
END;
$$ language plpgsql;

create function public.collect_draft_invoice_data_for_processing
(
    invoice_ids integer[]
) RETURNS void as $$ --return a json object with the data necessary to build BW and Dinero object.
DECLARE
BEGIN
    --declare json list to recieve data
        --collect all services
    --loop through all invoice_ids
        --data collection
            --collect invoice from invoices, by invoice_id
            --collect subscription_id from subscription_has_invoices by invoice_id
            --collect appointment_ids from invoice_has_appointments, by appointment_id
            --collect appointments by appointment_ids
            --collect service_ids from appointment_has_services, by appointment_ids
            --map service information from services, by service_id
            --map period from invoice
        --pack information in json object
    --end loop
    --return json list;
    --exception handling, store errors in jsonObject.errors for logging/flagging
END;
$$ language plpgsql;

create function public.mark_invoice_as_pending
(
    invoice_ids integer[]
) RETURNS void as $$ --return successful
DECLARE
BEGIN
    --loop through all invoice_ids
        --update invoice as pending, by invoice_id
    --end loop
END;
$$ language plpgsql;
