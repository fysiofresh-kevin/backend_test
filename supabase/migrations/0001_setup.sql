CREATE EXTENSION IF NOT EXISTS pg_tle;
SELECT pgtle.install_extension
       (
               'fysiofresh_helper_functions',
               '0.1',
               'Helper functions for dummy data creation and testing purposes',
               $_pg_tle_$

CREATE OR REPLACE FUNCTION public.seed_user_auth(email TEXT, id UUID) RETURNS void AS $$
BEGIN
    INSERT INTO auth.users
    (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token,
     confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at,
     last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone,
     phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current,
     email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at)
    VALUES
        ('00000000-0000-0000-0000-000000000000', id, 'authenticated', 'authenticated',
         email, '$2a$10$33zG3o0nJZfFXQtl1nJe1.tzayAcAjhKrAbosJAsvVC8n3iGll5.K',
         '2023-10-29 14:24:49.807149+00', NULL, '', NULL, '', '2023-10-30 14:24:06.149227+00', '', '', NULL,
         '2024-01-08 15:41:00.819885+00', '{"provider":"email","providers":["email"]}', '{}', NULL,
         '2023-10-29 14:24:06.149227+00', '2024-01-11 20:01:51.345308+00', NULL, NULL, '', '', NULL, '', 0, NULL,
         '', NULL);

    insert into auth.identities (id, user_id, provider_id, identity_data, provider, created_at, last_sign_in_at, updated_at)
    values
        (id,
         id,
         id,
         jsonb_build_object('sub', id, 'email', email),
         'email',
         '2023-10-29 14:24:06.149227+00',
         '2024-01-08 15:41:00.819885+00',
         '2024-01-11 20:01:51.345308+00');
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION public.assign_user_profile(username TEXT, id UUID) RETURNS void AS $$
BEGIN
    INSERT INTO user_profile
    (user_id, "name")
    VALUES
        (id, username);

END;
$$ language plpgsql;
CREATE OR REPLACE FUNCTION public.assign_user_role(userRole TEXT, id UUID) RETURNS void AS $$
BEGIN
    INSERT INTO user_has_role
    (user_id, role)
    VALUES
        (id, userRole);
END;
$$ language plpgsql;
CREATE OR REPLACE FUNCTION public.assign_user_profile_and_role(username TEXT, userRole TEXT, id UUID) RETURNS void AS $$
BEGIN
    PERFORM public.assign_user_profile(username, id);
    PERFORM public.assign_user_role(userRole, id);
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION public.seed_user(username TEXT, email TEXT, userRole TEXT, id UUID) RETURNS void AS $$
BEGIN
    PERFORM public.seed_user_auth(email, id);
    PERFORM public.assign_user_profile_and_role(username, userRole, id);
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION public.create_appointment
    (input_appointment_id bigint, input_client_id UUID, input_employee_id UUID, input_status appointment_status)
    RETURNS void AS $$
BEGIN
    INSERT INTO appointments
    (id, client_id, employee_id, "status")
    VALUES
        (input_appointment_id, input_client_id, input_employee_id, input_status);
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION public.create_service
    (input_service_id bigint, input_title TEXT)
    RETURNS void AS $$
BEGIN
    INSERT INTO services
    (id, "status", title)
    VALUES
        (input_service_id, 'ACTIVE', input_title);
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION public.map_appointment_and_services
    (input_appointment_id bigint, input_client_id UUID, input_employee_id UUID, input_service_id bigint)
RETURNS void AS $$
BEGIN
    -- Insert the appointment into the public.appointments table if it does not exist
    IF NOT EXISTS (
        SELECT 1 FROM public.appointments WHERE id = input_appointment_id
        )
        THEN
            PERFORM public.create_appointment
                (input_appointment_id, input_client_id, input_employee_id, 'completed');
    END IF;

    -- Insert the service into the public.services table if it does not exist
    IF NOT EXISTS (
        SELECT 1 FROM public.services WHERE id = input_service_id
        )
        THEN
            PERFORM public.create_service
                (input_service_id, 'Test treatment');
    END IF;
    -- Insert input_appointment and input_service into the junction table appointment_has_services
    INSERT INTO public.appointment_has_services (appointment_id, service_id)
    VALUES (input_appointment_id, input_service_id);

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.create_subscription_for_client(client uuid, subscription_id TEXT) RETURNS void as $$
BEGIN
    INSERT INTO subscriptions
    (id, created_at, last_paid, status, client_id)
    VALUES
        (subscription_id, '2024-01-18 11:12:10.808706+00', '2024-01-05 15:12:38+00',
         'ACTIVE', client);
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION public.create_invoice_with_subscription
    (input_invoice_id bigint, input_client_id uuid, input_subscription_id TEXT)
    RETURNS void AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.subscriptions WHERE id = input_subscription_id
    )
    THEN
        PERFORM create_subscription_for_client(input_client_id, input_subscription_id);
    END IF;

    INSERT INTO invoices
    (id, "from", "to", subscription_id)
    VALUES
        (input_invoice_id, NOW(), NOW(), input_subscription_id);
END;
$$ language plpgsql;





CREATE OR REPLACE FUNCTION public.map_invoice_and_appointments
(input_invoice_id bigint, input_appointment_ids bigint[])
    RETURNS void AS $$
DECLARE appointment bigint;
BEGIN
    -- Insert invoice and appointments into the junction table invoice_has_appointments
    FOREACH appointment IN ARRAY input_appointment_ids LOOP
            INSERT INTO public.invoice_has_appointments (invoice_id, appointment_id)
            VALUES (input_invoice_id, appointment)
            ON CONFLICT (invoice_id, appointment_id) DO NOTHING;
        END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.map_role_and_permissions(input_role TEXT, permissions TEXT[]) RETURNS void AS $$
DECLARE perm text;
BEGIN
    -- Insert the role into the public.roles table if it does not exist
    INSERT INTO public.roles (role)
    SELECT input_role
    WHERE NOT EXISTS (
        SELECT 1 FROM public.roles WHERE role = input_role
    );

    -- Insert the permissions into the public.permissions table if they do not exist
    FOREACH perm IN ARRAY permissions LOOP
            INSERT INTO public.permissions (permission)
            SELECT perm
            WHERE NOT EXISTS (
                SELECT 1 FROM public.permissions WHERE permission = perm
            );
        END LOOP;

    -- Insert input_role and permissions into the junction table role_has_permissions
    FOREACH perm IN ARRAY permissions LOOP
            INSERT INTO public.role_has_permissions (role, permission)
            VALUES (input_role, perm)
            ON CONFLICT (role, permission) DO NOTHING;
        END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.map_client_and_employee(client uuid, employee uuid) RETURNS void AS $$
BEGIN
    INSERT INTO employee_has_clients
    (client_id, employee_id)
    VALUES
        (client, employee);
END;
$$ language plpgsql;

CREATE FUNCTION public.disable_all_rls_in_public_schema() RETURNS void AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
        LOOP
            EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' DISABLE ROW LEVEL SECURITY';
        END LOOP;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION public.delete_all_data_in_schemas() RETURNS void AS $$
DECLARE
    table_names TEXT := '';
BEGIN
    SELECT INTO table_names
        string_agg(quote_ident(schemaname) || '.' || quote_ident(tablename), ', ')
    FROM pg_tables
    WHERE schemaname IN ('auth', 'public');

    IF table_names <> '' THEN
        EXECUTE 'TRUNCATE TABLE ' || table_names || ' CASCADE';
    END IF;
END;
$$ LANGUAGE plpgsql;
$_pg_tle_$
       );
