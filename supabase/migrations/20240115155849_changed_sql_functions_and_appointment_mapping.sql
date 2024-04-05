drop policy "Enable client to read their own appointments" on "public"."appointments";

drop policy "Enable employee to read their own appointments" on "public"."appointments";

drop policy "Enable user to update their own appointments" on "public"."appointments";

drop policy "Enable user to upsert their own appointments" on "public"."appointments";

drop policy "allow user to insert their own appointments" on "public"."appointments";

drop policy "Enable read access if client/employee are connected" on "public"."user_has_role";

drop policy "Enable read access if client/employee are connected" on "public"."user_profile";

alter table "public"."employee_has_clients" drop constraint "employee_has_clients_client_id_fkey";

alter table "public"."employee_has_clients" drop constraint "employee_has_clients_employee_id_fkey";

alter table "public"."user_profile" drop constraint "user_profile_user_id_fkey";

drop function if exists "public"."check_are_users_connected"(user_id1_param text, user_id2_param text);

drop function if exists "public"."duplicate_check_are_users_connected"(user_id1_param uuid, user_id2_param uuid);

alter table "public"."appointment_has_services" drop constraint "appointment_has_services_pkey";

drop index if exists "public"."appointment_has_services_pkey";

alter table "public"."appointments" add column "client_id2" character varying;

alter table "public"."appointments" add column "employee_id2" character varying;

alter table "public"."appointments" alter column "client_id" set data type uuid using "client_id"::uuid;

alter table "public"."appointments" alter column "employee_id" set data type uuid using "employee_id"::uuid;

alter table "public"."user_profile" add column "email" character varying;

CREATE UNIQUE INDEX appointment_has_services_pkey ON public.appointment_has_services USING btree (appointment_id, service_id);

alter table "public"."appointment_has_services" add constraint "appointment_has_services_pkey" PRIMARY KEY using index "appointment_has_services_pkey";

alter table "public"."appointments" add constraint "appointments_client_id_fkey" FOREIGN KEY (client_id) REFERENCES user_profile(user_id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."appointments" validate constraint "appointments_client_id_fkey";

alter table "public"."appointments" add constraint "appointments_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES user_profile(user_id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."appointments" validate constraint "appointments_employee_id_fkey";

alter table "public"."user_has_role" add constraint "user_has_role_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."user_has_role" validate constraint "user_has_role_user_id_fkey";

alter table "public"."employee_has_clients" add constraint "employee_has_clients_client_id_fkey" FOREIGN KEY (client_id) REFERENCES user_profile(user_id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."employee_has_clients" validate constraint "employee_has_clients_client_id_fkey";

alter table "public"."employee_has_clients" add constraint "employee_has_clients_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES user_profile(user_id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."employee_has_clients" validate constraint "employee_has_clients_employee_id_fkey";

alter table "public"."user_profile" add constraint "user_profile_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."user_profile" validate constraint "user_profile_user_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.check_are_users_connected(user_id1_param uuid, user_id2_param uuid)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM employee_has_clients
        WHERE (employee_id = user_id1_param AND client_id = user_id2_param)
           OR (employee_id = user_id2_param AND client_id = user_id1_param)
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.old_check_are_users_connected(user_id1_param text, user_id2_param text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
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
$function$
;

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
  user_has_role.user_id::uuid = client_profile.user_id
  WHERE
    roles @> '["client"]' AND
    (check_are_users_connected(auth_id, client_profile.user_id) OR check_user_has_permission(auth_id, '["organization:read", "organization:admin"]'));
END;
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
    WHEN roles @> '["employee"]' AND auth_id = client_profile.user_id THEN true
    WHEN roles @> '["employee"]' AND check_are_users_connected(auth_id, client_profile.user_id) AND check_user_has_permission(auth_id, '["organization:read"]') THEN true
    WHEN roles @> '["employee"]' AND  check_user_has_permission(auth_id, '["organization:read", "organization:admin"]') THEN true
    ELSE false
  END;
END;
$function$
;

create policy "Enable client to read their own appointments"
on "public"."appointments"
as permissive
for select
to public
using ((((auth.uid())::text = (client_id2)::text) AND check_user_has_permission(auth.uid(), '["appointment:read"]'::jsonb)));


create policy "Enable employee to read their own appointments"
on "public"."appointments"
as permissive
for select
to public
using ((((auth.uid())::text = (employee_id2)::text) AND check_user_has_permission(auth.uid(), '["appointment:read"]'::jsonb)));


create policy "Enable user to update their own appointments"
on "public"."appointments"
as permissive
for update
to public
using (((((auth.uid())::text = (employee_id2)::text) AND check_user_has_permission(auth.uid(), '["appointment:write"]'::jsonb)) OR (((auth.uid())::text = (client_id2)::text) AND check_user_has_permission(auth.uid(), '["appointment:cancel"]'::jsonb)) OR check_user_has_permission(auth.uid(), '["appointment:write", "appointment:admin"]'::jsonb)))
with check (((((auth.uid())::text = (employee_id2)::text) AND check_user_has_permission(auth.uid(), '["appointment:write"]'::jsonb)) OR (((auth.uid())::text = (client_id2)::text) AND check_user_has_permission(auth.uid(), '["appointment:cancel"]'::jsonb)) OR check_user_has_permission(auth.uid(), '["appointment:write", "appointment:admin"]'::jsonb)));


create policy "Enable user to upsert their own appointments"
on "public"."appointments"
as permissive
for update
to public
using (((((auth.uid())::text = (employee_id2)::text) AND check_user_has_permission(auth.uid(), '["appointment:write"]'::jsonb)) OR (((auth.uid())::text = (client_id2)::text) AND check_user_has_permission(auth.uid(), '["appointment:cancel"]'::jsonb)) OR check_user_has_permission(auth.uid(), '["appointment:write", "appointment:admin"]'::jsonb)))
with check (((((auth.uid())::text = (employee_id2)::text) AND check_user_has_permission(auth.uid(), '["appointment:write"]'::jsonb)) OR (((auth.uid())::text = (client_id2)::text) AND check_user_has_permission(auth.uid(), '["appointment:cancel"]'::jsonb)) OR check_user_has_permission(auth.uid(), '["appointment:write", "appointment:admin"]'::jsonb)));


create policy "allow user to insert their own appointments"
on "public"."appointments"
as permissive
for insert
to public
with check (((((auth.uid())::text = (employee_id2)::text) AND check_user_has_permission(auth.uid(), '["appointment:write"]'::jsonb)) OR (((auth.uid())::text = (client_id2)::text) AND check_user_has_permission(auth.uid(), '["appointment:cancel"]'::jsonb)) OR check_user_has_permission(auth.uid(), '["appointment:write", "appointment:admin"]'::jsonb)));


create policy "Enable read access if client/employee are connected"
on "public"."user_has_role"
as permissive
for select
to public
using ((old_check_are_users_connected((auth.uid())::text, (user_id)::text) AND check_user_has_permission(auth.uid(), '["organization:read"]'::jsonb)));


create policy "Enable read access if client/employee are connected"
on "public"."user_profile"
as permissive
for select
to public
using ((old_check_are_users_connected((auth.uid())::text, user_id2) AND check_user_has_permission(auth.uid(), '["organization:read"]'::jsonb)));



