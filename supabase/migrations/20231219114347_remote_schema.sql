
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgtap" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

CREATE TYPE "public"."appointment_status" AS ENUM (
    'pending',
    'cancelled',
    'completed'
);

ALTER TYPE "public"."appointment_status" OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."check_are_users_connected"("user_id1_param" "text", "user_id2_param" "text") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    are_connected BOOLEAN;
BEGIN
    are_connected := false;

    SELECT
        CASE
            WHEN (employee_has_clients.employee_id = user_id1_param AND employee_has_clients.clients @> ('["' || user_id2_param || '"]')::jsonb) THEN true
            WHEN (employee_has_clients.employee_id = user_id2_param AND employee_has_clients.clients @> ('["' || user_id1_param || '"]')::jsonb) THEN true
            ELSE false
        END
    INTO are_connected
    FROM employee_has_clients;
    RETURN are_connected;
END;
$$;

ALTER FUNCTION "public"."check_are_users_connected"("user_id1_param" "text", "user_id2_param" "text") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."check_user_has_permission"("p_user_id" "uuid", "p_permissions" "jsonb") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_roles jsonb;
    v_roles_array text[];
    v_permissions jsonb := '[]'::jsonb;
    v_permission_exists BOOLEAN := FALSE;
    all_permissions jsonb := '[]'::jsonb;
BEGIN
    -- Get roles for the given user_id
    v_roles := get_user_roles(p_user_id);

    -- If no roles found, return false
    IF v_roles IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Convert jsonb array to text array
    -- This simplifies the for loop and json comparison.
    SELECT ARRAY(SELECT jsonb_array_elements_text(v_roles)) INTO v_roles_array;

      -- Check if any of the roles have all the given permissions
    FOR i IN 1..array_length(v_roles_array, 1) LOOP
        -- Extract permissions for each role
        v_permissions := get_permissions_in_role(v_roles_array[i]::text);

        -- Combine permissions for each role
        all_permissions := all_permissions || v_permissions;

        -- Check if current role has all the given permissions
        IF (all_permissions @> p_permissions::jsonb) THEN
            v_permission_exists := TRUE;
            EXIT; -- Exit if any role has the permissions
        END IF;
    END LOOP;

    RETURN v_permission_exists;
END;
$$;

ALTER FUNCTION "public"."check_user_has_permission"("p_user_id" "uuid", "p_permissions" "jsonb") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_all_clients"("auth_id" "uuid") RETURNS SETOF "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT JSONB_BUILD_OBJECT(
    'id', client_profile.user_id,
    'email', get_user_email(client_profile.user_id::text),
    'name', client_profile.name
  )
  FROM user_has_role
  JOIN public.user_profile client_profile ON
  user_has_role.user_id::text = client_profile.user_id
  WHERE
    roles @> '["client"]' AND
    (check_are_users_connected(auth_id::text, client_profile.user_id) OR check_user_has_permission(auth_id, '["organization:read", "organization:admin"]'));
END;
$$;

ALTER FUNCTION "public"."get_all_clients"("auth_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_all_employees"("auth_id" "uuid") RETURNS SETOF "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT JSONB_BUILD_OBJECT(
    'id', client_profile.user_id,
    'email', get_user_email(client_profile.user_id::text),
    'name', client_profile.name
  )
  FROM user_has_role
  JOIN public.user_profile client_profile ON
  user_has_role.user_id::text = client_profile.user_id
  WHERE
    CASE
    WHEN roles @> '["employee"]' AND auth_id::text = client_profile.user_id THEN true
    WHEN roles @> '["employee"]' AND check_are_users_connected(auth_id::text, client_profile.user_id) AND check_user_has_permission(auth_id, '["organization:read"]') THEN true
    WHEN roles @> '["employee"]' AND  check_user_has_permission(auth_id, '["organization:read", "organization:admin"]') THEN true
    ELSE false
  END;
END;
$$;

ALTER FUNCTION "public"."get_all_employees"("auth_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_appointments_for_user"("user_id_param" "uuid") RETURNS TABLE("appointment" "jsonb")
    LANGUAGE "plpgsql"
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
    WHEN appointments.client_id = user_id_param::text THEN true
    WHEN appointments.employee_id = user_id_param::text THEN true
    ELSE check_user_has_permission(user_id_param, '["appointment:read", "appointment:admin"]')
  END;
END;
$$;

ALTER FUNCTION "public"."get_appointments_for_user"("user_id_param" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_permissions_in_role"("role_title" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN (
        SELECT permissions
        FROM roles
        WHERE title = role_title
  );
END;
$$;

ALTER FUNCTION "public"."get_permissions_in_role"("role_title" "text") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_user_email"("user_id" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN (
    SELECT email
    FROM auth.users
    WHERE id::text = user_id
  );
END;
$$;

ALTER FUNCTION "public"."get_user_email"("user_id" "text") OWNER TO "postgres";

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

CREATE OR REPLACE FUNCTION "public"."get_user_roles"("p_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN (
    SELECT roles
    FROM public.user_has_role
    WHERE user_id = p_user_id
  );
END;
$$;

ALTER FUNCTION "public"."get_user_roles"("p_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."update_client_to_employees_relationships"("p_client_id" "text", "p_employee_ids" "text"[]) RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$

DECLARE
    emp_id TEXT;
    existing_clients JSONB;
    existing_clients_array TEXT[];
BEGIN
    -- Check if employee_ids is null
    IF p_employee_ids IS NULL THEN
        RETURN 'employee_ids cannot be null';
    END IF;

    -- Check if client_id is null or empty
    IF p_client_id IS NULL OR p_client_id = '' THEN
        RETURN 'client_id cannot be null or empty';
    END IF;

    -- Iterate through each employee_id
    FOREACH emp_id IN ARRAY p_employee_ids
    LOOP
        -- Check if the row exists for the given employee_id
        SELECT clients INTO existing_clients
        FROM employee_has_clients
        WHERE employee_id = emp_id;

        existing_clients_array := array_agg(arr)::text[] FROM jsonb_array_elements_text(COALESCE(existing_clients, '[]'::JSONB)) AS arr;

        -- If the row exists, update or do nothing
        IF FOUND THEN
            IF p_client_id = ANY(existing_clients_array) THEN
                -- Do nothing if client_id already exists in the list
            ELSE
                -- Update the row by adding the client_id to the list
                UPDATE employee_has_clients
                SET clients = COALESCE(existing_clients, '[]'::JSONB) || JSONB_BUILD_ARRAY(p_client_id)
                WHERE employee_id = emp_id;
            END IF;
        ELSE
            -- Insert a new row with the employee_id and client_id
            INSERT INTO employee_has_clients(employee_id, clients)
            VALUES (emp_id, JSONB_BUILD_ARRAY(p_client_id));
        END IF;
    END LOOP;

 -- Clean up rows where employee_id is not in the provided list
    UPDATE employee_has_clients
    SET clients = COALESCE(clients, '[]'::JSONB) - p_client_id
    WHERE employee_id NOT IN (SELECT unnest(p_employee_ids));

    return 'ok';

END;
$$;

ALTER FUNCTION "public"."update_client_to_employees_relationships"("p_client_id" "text", "p_employee_ids" "text"[]) OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."appointments" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "client_id" character varying,
    "employee_id" character varying,
    "start" timestamp with time zone,
    "end" timestamp with time zone,
    "notes" "text",
    "status" "public"."appointment_status" DEFAULT 'pending'::"public"."appointment_status" NOT NULL
);

ALTER TABLE "public"."appointments" OWNER TO "postgres";

ALTER TABLE "public"."appointments" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."Appointments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."employee_has_clients" (
    "clients" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "employee_id" "text" NOT NULL
);

ALTER TABLE "public"."employee_has_clients" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."roles" (
    "title" "text" NOT NULL,
    "permissions" "jsonb" NOT NULL
);

ALTER TABLE "public"."roles" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."user_has_role" (
    "user_id" "uuid" NOT NULL,
    "roles" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL
);

ALTER TABLE "public"."user_has_role" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."user_profile" (
    "user_id" "text" NOT NULL,
    "name" "text"
);

ALTER TABLE "public"."user_profile" OWNER TO "postgres";

ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "Appointments_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."employee_has_clients"
    ADD CONSTRAINT "employee_has_clients_employee_key" UNIQUE ("employee_id");

ALTER TABLE ONLY "public"."employee_has_clients"
    ADD CONSTRAINT "employee_has_clients_pkey" PRIMARY KEY ("employee_id");

ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("title");

ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_user_id_key" UNIQUE ("title");

ALTER TABLE ONLY "public"."user_has_role"
    ADD CONSTRAINT "user_has_role_pkey" PRIMARY KEY ("user_id");

ALTER TABLE ONLY "public"."user_has_role"
    ADD CONSTRAINT "user_has_role_user_id_key" UNIQUE ("user_id");

ALTER TABLE ONLY "public"."user_profile"
    ADD CONSTRAINT "user_profile_pkey" PRIMARY KEY ("user_id");

ALTER TABLE ONLY "public"."user_profile"
    ADD CONSTRAINT "user_profile_user_id_key" UNIQUE ("user_id");

CREATE POLICY "Enable Admins to insert new rows" ON "public"."employee_has_clients" FOR INSERT WITH CHECK ("public"."check_user_has_permission"("auth"."uid"(), '["organization:write", "organization:admin"]'::"jsonb"));

CREATE POLICY "Enable Admins to write Employee Client connections" ON "public"."employee_has_clients" FOR UPDATE USING ("public"."check_user_has_permission"("auth"."uid"(), '["organization:write", "organization:admin"]'::"jsonb")) WITH CHECK ("public"."check_user_has_permission"("auth"."uid"(), '["organization:write", "organization:admin"]'::"jsonb"));

CREATE POLICY "Enable admin access to all user profiles" ON "public"."user_profile" FOR SELECT USING ("public"."check_user_has_permission"("auth"."uid"(), '["organization:read", "organization:admin"]'::"jsonb"));

CREATE POLICY "Enable admin to read all appointments" ON "public"."appointments" FOR SELECT USING ("public"."check_user_has_permission"("auth"."uid"(), '["appointment:read", "appointment:admin"]'::"jsonb"));

CREATE POLICY "Enable admin to read all user roles" ON "public"."roles" FOR SELECT USING ("public"."check_user_has_permission"("auth"."uid"(), '["organization:read", "organization:admin"]'::"jsonb"));

CREATE POLICY "Enable admin to view all user roles" ON "public"."user_has_role" FOR SELECT USING ("public"."check_user_has_permission"("auth"."uid"(), '["organization:read", "organization:admin"]'::"jsonb"));

CREATE POLICY "Enable client to read their own appointments" ON "public"."appointments" FOR SELECT USING (((("auth"."uid"())::"text" = ("client_id")::"text") AND "public"."check_user_has_permission"("auth"."uid"(), '["appointment:read"]'::"jsonb")));

CREATE POLICY "Enable clients to read their employees" ON "public"."employee_has_clients" FOR SELECT USING ((("clients" @> ((('["'::"text" || ("auth"."uid"())::"text") || '"]'::"text"))::"jsonb") AND "public"."check_user_has_permission"("auth"."uid"(), '["organization:read"]'::"jsonb")));

CREATE POLICY "Enable employee to read their clients" ON "public"."employee_has_clients" FOR SELECT USING (((("auth"."uid"())::"text" = "employee_id") AND "public"."check_user_has_permission"("auth"."uid"(), '["organization:read"]'::"jsonb")));

CREATE POLICY "Enable employee to read their own appointments" ON "public"."appointments" FOR SELECT USING (((("auth"."uid"())::"text" = ("employee_id")::"text") AND "public"."check_user_has_permission"("auth"."uid"(), '["appointment:read"]'::"jsonb")));

CREATE POLICY "Enable read access if client/employee are connected" ON "public"."user_profile" FOR SELECT USING (("public"."check_are_users_connected"(("auth"."uid"())::"text", "user_id") AND "public"."check_user_has_permission"("auth"."uid"(), '["organization:read"]'::"jsonb")));

CREATE POLICY "Enable user to delete appointments" ON "public"."appointments" FOR DELETE USING ("public"."check_user_has_permission"("auth"."uid"(), '["appointment:delete", "appointment:admin"]'::"jsonb"));

CREATE POLICY "Enable user to update their own appointments" ON "public"."appointments" FOR UPDATE USING ((((("auth"."uid"())::"text" = ("employee_id")::"text") AND "public"."check_user_has_permission"("auth"."uid"(), '["appointment:write"]'::"jsonb")) OR ((("auth"."uid"())::"text" = ("client_id")::"text") AND "public"."check_user_has_permission"("auth"."uid"(), '["appointment:cancel"]'::"jsonb")) OR "public"."check_user_has_permission"("auth"."uid"(), '["appointment:write", "appointment:admin"]'::"jsonb"))) WITH CHECK ((((("auth"."uid"())::"text" = ("employee_id")::"text") AND "public"."check_user_has_permission"("auth"."uid"(), '["appointment:write"]'::"jsonb")) OR ((("auth"."uid"())::"text" = ("client_id")::"text") AND "public"."check_user_has_permission"("auth"."uid"(), '["appointment:cancel"]'::"jsonb")) OR "public"."check_user_has_permission"("auth"."uid"(), '["appointment:write", "appointment:admin"]'::"jsonb")));

CREATE POLICY "Enable user to upsert their own appointments" ON "public"."appointments" FOR UPDATE USING ((((("auth"."uid"())::"text" = ("employee_id")::"text") AND "public"."check_user_has_permission"("auth"."uid"(), '["appointment:write"]'::"jsonb")) OR ((("auth"."uid"())::"text" = ("client_id")::"text") AND "public"."check_user_has_permission"("auth"."uid"(), '["appointment:cancel"]'::"jsonb")) OR "public"."check_user_has_permission"("auth"."uid"(), '["appointment:write", "appointment:admin"]'::"jsonb"))) WITH CHECK ((((("auth"."uid"())::"text" = ("employee_id")::"text") AND "public"."check_user_has_permission"("auth"."uid"(), '["appointment:write"]'::"jsonb")) OR ((("auth"."uid"())::"text" = ("client_id")::"text") AND "public"."check_user_has_permission"("auth"."uid"(), '["appointment:cancel"]'::"jsonb")) OR "public"."check_user_has_permission"("auth"."uid"(), '["appointment:write", "appointment:admin"]'::"jsonb")));

CREATE POLICY "Enable user to view roles" ON "public"."roles" FOR SELECT USING ("public"."check_user_has_permission"("auth"."uid"(), '["organization:read"]'::"jsonb"));

CREATE POLICY "Enable user to view their own permissions" ON "public"."user_has_role" FOR SELECT USING (("auth"."uid"() = "user_id"));

CREATE POLICY "Enables Admins to read all rows" ON "public"."employee_has_clients" FOR SELECT USING ("public"."check_user_has_permission"("auth"."uid"(), '["organization:read", "organization:admin"]'::"jsonb"));

CREATE POLICY "allow user to insert their own appointments" ON "public"."appointments" FOR INSERT WITH CHECK ((((("auth"."uid"())::"text" = ("employee_id")::"text") AND "public"."check_user_has_permission"("auth"."uid"(), '["appointment:write"]'::"jsonb")) OR ((("auth"."uid"())::"text" = ("client_id")::"text") AND "public"."check_user_has_permission"("auth"."uid"(), '["appointment:cancel"]'::"jsonb")) OR "public"."check_user_has_permission"("auth"."uid"(), '["appointment:write", "appointment:admin"]'::"jsonb")));

CREATE POLICY "allow user to read their own profile" ON "public"."user_profile" FOR SELECT USING ((("auth"."uid"())::"text" = "user_id"));

ALTER TABLE "public"."appointments" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."employee_has_clients" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."user_has_role" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."user_profile" ENABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."check_are_users_connected"("user_id1_param" "text", "user_id2_param" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."check_are_users_connected"("user_id1_param" "text", "user_id2_param" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_are_users_connected"("user_id1_param" "text", "user_id2_param" "text") TO "service_role";

GRANT ALL ON FUNCTION "public"."check_user_has_permission"("p_user_id" "uuid", "p_permissions" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."check_user_has_permission"("p_user_id" "uuid", "p_permissions" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_user_has_permission"("p_user_id" "uuid", "p_permissions" "jsonb") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_all_clients"("auth_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_all_clients"("auth_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_all_clients"("auth_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_all_employees"("auth_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_all_employees"("auth_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_all_employees"("auth_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_appointments_for_user"("user_id_param" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_appointments_for_user"("user_id_param" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_appointments_for_user"("user_id_param" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_permissions_in_role"("role_title" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_permissions_in_role"("role_title" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_permissions_in_role"("role_title" "text") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_user_email"("user_id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_email"("user_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_email"("user_id" "text") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_user_permissions"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_permissions"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_permissions"("p_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_user_roles"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_roles"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_roles"("p_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."update_client_to_employees_relationships"("p_client_id" "text", "p_employee_ids" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."update_client_to_employees_relationships"("p_client_id" "text", "p_employee_ids" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_client_to_employees_relationships"("p_client_id" "text", "p_employee_ids" "text"[]) TO "service_role";

GRANT ALL ON TABLE "public"."appointments" TO "anon";
GRANT ALL ON TABLE "public"."appointments" TO "authenticated";
GRANT ALL ON TABLE "public"."appointments" TO "service_role";

GRANT ALL ON SEQUENCE "public"."Appointments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."Appointments_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."Appointments_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."employee_has_clients" TO "anon";
GRANT ALL ON TABLE "public"."employee_has_clients" TO "authenticated";
GRANT ALL ON TABLE "public"."employee_has_clients" TO "service_role";

GRANT ALL ON TABLE "public"."roles" TO "anon";
GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";

GRANT ALL ON TABLE "public"."user_has_role" TO "anon";
GRANT ALL ON TABLE "public"."user_has_role" TO "authenticated";
GRANT ALL ON TABLE "public"."user_has_role" TO "service_role";

GRANT ALL ON TABLE "public"."user_profile" TO "anon";
GRANT ALL ON TABLE "public"."user_profile" TO "authenticated";
GRANT ALL ON TABLE "public"."user_profile" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
