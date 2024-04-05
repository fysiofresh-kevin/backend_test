drop policy "Enable employee to read their clients" on "public"."employee_has_clients";

drop policy "Enable read access if client/employee are connected" on "public"."user_profile";

drop policy "allow user to read their own profile" on "public"."user_profile";

alter table "public"."employee_has_clients" drop constraint "employee_has_clients_employee_key";

alter table "public"."user_profile" drop constraint "user_profile_user_id_key";

alter table "public"."employee_has_clients" drop constraint "employee_has_clients_pkey";

drop index if exists "public"."employee_has_clients_employee_key";

drop index if exists "public"."employee_has_clients_pkey";

drop index if exists "public"."user_profile_user_id_key";

alter table "public"."employee_has_clients" add column "client_id" uuid not null;

alter table "public"."employee_has_clients" add column "employee_id2" text not null;

alter table "public"."employee_has_clients" alter column "employee_id" set data type uuid using "employee_id"::uuid;

alter table "public"."user_profile" add column "user_id2" text not null;

alter table "public"."user_profile" alter column "user_id" set data type uuid using "user_id"::uuid;

CREATE UNIQUE INDEX employee_has_clients_employee_key ON public.employee_has_clients USING btree (employee_id2);

CREATE UNIQUE INDEX employee_has_clients_pkey ON public.employee_has_clients USING btree (client_id, employee_id);

CREATE UNIQUE INDEX user_profile_user_id_key ON public.user_profile USING btree (user_id2);

alter table "public"."employee_has_clients" add constraint "employee_has_clients_pkey" PRIMARY KEY using index "employee_has_clients_pkey";

alter table "public"."employee_has_clients" add constraint "employee_has_clients_client_id_fkey" FOREIGN KEY (client_id) REFERENCES user_profile(user_id) not valid;

alter table "public"."employee_has_clients" validate constraint "employee_has_clients_client_id_fkey";

alter table "public"."employee_has_clients" add constraint "employee_has_clients_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES user_profile(user_id) not valid;

alter table "public"."employee_has_clients" validate constraint "employee_has_clients_employee_id_fkey";

alter table "public"."user_profile" add constraint "user_profile_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."user_profile" validate constraint "user_profile_user_id_fkey";

alter table "public"."employee_has_clients" add constraint "employee_has_clients_employee_key" UNIQUE using index "employee_has_clients_employee_key";

alter table "public"."user_profile" add constraint "user_profile_user_id_key" UNIQUE using index "user_profile_user_id_key";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.duplicate_check_are_users_connected(user_id1_param uuid, user_id2_param uuid)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM duplicate_employee_has_clients
        WHERE (employee_id = user_id1_param AND client_id = user_id2_param)
           OR (employee_id = user_id2_param AND client_id = user_id1_param)
    );
END;
$function$
;

create policy "Enable employee to read their clients"
on "public"."employee_has_clients"
as permissive
for select
to public
using ((((auth.uid())::text = employee_id2) AND check_user_has_permission(auth.uid(), '["organization:read"]'::jsonb)));


create policy "Enable read access if client/employee are connected"
on "public"."user_profile"
as permissive
for select
to public
using ((check_are_users_connected((auth.uid())::text, user_id2) AND check_user_has_permission(auth.uid(), '["organization:read"]'::jsonb)));


create policy "allow user to read their own profile"
on "public"."user_profile"
as permissive
for select
to public
using ((((auth.uid())::text = user_id2) AND check_user_has_permission(auth.uid(), '["organization:read"]'::jsonb)));



