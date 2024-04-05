DROP FUNCTION get_user_roles(uuid);

CREATE OR REPLACE FUNCTION "public"."get_user_roles"("p_user_id" "uuid") RETURNS text[]
    LANGUAGE "plpgsql" SECURITY DEFINER
AS $$
BEGIN
    RETURN (
        SELECT ARRAY_AGG(role)
        FROM public.user_has_role
        WHERE user_id = p_user_id
    );
END;
$$;

ALTER FUNCTION "public"."get_user_roles"("p_user_id" "uuid") OWNER TO "postgres";


DROP FUNCTION get_permissions_in_role(text);

CREATE OR REPLACE FUNCTION "public"."get_permissions_in_role"("role_title" "text") RETURNS text[]
    LANGUAGE "plpgsql" SECURITY DEFINER
AS $$
BEGIN
    RETURN (
        SELECT ARRAY_AGG(permission)
        FROM role_has_permissions
        WHERE role = role_title
    );
END;
$$;

ALTER FUNCTION "public"."get_permissions_in_role"("role_title" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_user_has_permission"("p_user_id" "uuid", "p_permissions" text[]) RETURNS boolean
    LANGUAGE "plpgsql"
AS $$
DECLARE
    v_roles text[];
    v_permissions text[];
    v_permission_exists BOOLEAN := FALSE;
    all_permissions text[];
BEGIN
    -- Get roles for the given user_id
    v_roles := get_user_roles(p_user_id);

    -- If no roles found, return false
    IF v_roles IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Check if any of the roles have all the given permissions
    FOR i IN 1..array_length(v_roles, 1) LOOP
            -- Extract permissions for each role
            v_permissions := get_permissions_in_role(v_roles[i]::text);

            -- Combine permissions for each role
            all_permissions := all_permissions || v_permissions;

            -- Check if current role has all the given permissions
            IF all_permissions @> p_permissions THEN
                v_permission_exists := TRUE;
                EXIT; -- Exit if any role has the permissions
            END IF;
        END LOOP;

    RETURN v_permission_exists;
END;
$$;

ALTER FUNCTION "public"."check_user_has_permission"("p_user_id" "uuid", "p_permissions" text[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION public.get_all_clients(auth_id uuid)
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
            role = 'client' AND
            (check_are_users_connected(auth_id, client_profile.user_id) OR check_user_has_permission(auth_id, ARRAY['organization:read', 'organization:admin']));
END
$function$
;


CREATE OR REPLACE FUNCTION public.get_all_employees(auth_id uuid)
    RETURNS SETOF jsonb
    LANGUAGE plpgsql
    SECURITY DEFINER
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
            CASE
                WHEN role = 'employee' AND auth_id = client_profile.user_id THEN true
                WHEN role = 'employee' AND check_are_users_connected(auth_id, client_profile.user_id) AND check_user_has_permission(auth_id, ARRAY['organization:read']) THEN true
                WHEN role = 'employee' AND  check_user_has_permission(auth_id, ARRAY['organization:read', 'organization:admin']) THEN true
                ELSE false
                END;
END;
$function$
;

CREATE OR REPLACE function public.draft_invoices_for_period
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
        role = 'client';

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
        end loop;
    return reports;
END;
$$ language plpgsql;


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
                    'start', appointments.start,
                    'end', appointments.end,
                    'status', appointments.status,
                    'notes', appointments.notes) as appointment
        FROM appointments
                 JOIN
             public.user_profile client_profile ON appointments.client_id = client_profile.user_id
                 JOIN
             public.user_profile employee_profile ON appointments.employee_id = employee_profile.user_id
        WHERE
            CASE
                WHEN appointments.client_id = user_id_param THEN true
                WHEN appointments.employee_id = user_id_param THEN true
                ELSE check_user_has_permission(user_id_param, ARRAY['appointment:read', 'appointment:admin'])
                END;
END;
$$;


CREATE OR REPLACE FUNCTION "public"."get_user_permissions"("p_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql"
AS $$
DECLARE
    v_roles jsonb;
    v_roles_array text[];
    v_permissions jsonb := '[]'::jsonb;
    all_permissions jsonb := '[]'::jsonb;
BEGIN
    -- Get roles for the given user_id
    v_roles := get_user_roles(p_user_id);

    -- If no roles found, return false
    IF v_roles IS NULL THEN
        RETURN all_permissions;
    END IF;

    -- Convert jsonb array to text array
    SELECT ARRAY(SELECT jsonb_array_elements_text(v_roles)) INTO v_roles_array;

    -- Check if any of the roles have all the given permissions
    FOR i IN 1..array_length(v_roles_array, 1) LOOP
            -- Extract permissions for each role
            v_permissions := get_permissions_in_role(v_roles_array[i]::text);

            -- Combine permissions for each role
            all_permissions := all_permissions || v_permissions;
        END LOOP;

    RETURN all_permissions;
END;
$$;

ALTER FUNCTION "public"."get_user_permissions"("p_user_id" "uuid") OWNER TO "postgres";


DROP FUNCTION get_user_permissions(uuid);

CREATE OR REPLACE FUNCTION "public"."get_user_permissions"("p_user_id" "uuid") RETURNS text[]
    LANGUAGE "plpgsql"
AS $$
DECLARE
    v_roles text[];
    v_permissions text[];
    all_permissions text[];
BEGIN
    -- Get roles for the given user_id
    v_roles := get_user_roles(p_user_id);

    -- If no roles found, return false
    IF v_roles IS NULL THEN
        RETURN all_permissions;
    END IF;

    -- Check if any of the roles have all the given permissions
    FOR i IN 1..array_length(v_roles, 1) LOOP
            -- Extract permissions for each role
            v_permissions := get_permissions_in_role(v_roles[i]::text);

            -- Combine permissions for each role
            all_permissions := all_permissions || v_permissions;
        END LOOP;

    RETURN all_permissions;
END;
$$;

ALTER FUNCTION "public"."get_user_permissions"("p_user_id" "uuid") OWNER TO "postgres";