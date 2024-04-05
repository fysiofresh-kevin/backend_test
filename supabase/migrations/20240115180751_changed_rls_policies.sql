drop policy "Enable client to read their own appointments" on "public"."appointments";

drop policy "Enable employee to read their own appointments" on "public"."appointments";

drop policy "Enable user to update their own appointments" on "public"."appointments";

drop policy "Enable user to upsert their own appointments" on "public"."appointments";

drop policy "allow user to insert their own appointments" on "public"."appointments";

drop policy "Enable clients to read their employees" on "public"."employee_has_clients";

drop policy "Enable employee to read their clients" on "public"."employee_has_clients";

drop policy "Enable read access if client/employee are connected" on "public"."user_has_role";

drop policy "Enable read access if client/employee are connected" on "public"."user_profile";

drop policy "allow user to read their own profile" on "public"."user_profile";

alter table "public"."employee_has_clients" drop constraint "employee_has_clients_employee_key";

alter table "public"."user_profile" drop constraint "user_profile_user_id_key";

drop index if exists "public"."employee_has_clients_employee_key";

drop index if exists "public"."user_profile_user_id_key";

alter table "public"."appointments" drop column "client_id2";

alter table "public"."appointments" drop column "employee_id2";

alter table "public"."employee_has_clients" drop column "clients";

alter table "public"."employee_has_clients" drop column "employee_id2";

alter table "public"."user_profile" drop column "user_id2";

create policy "Enable client to read their own appointments"
on "public"."appointments"
as permissive
for select
to public
using (((auth.uid() = client_id) AND check_user_has_permission(auth.uid(), '["appointment:read"]'::jsonb)));


create policy "Enable employee to read their own appointments"
on "public"."appointments"
as permissive
for select
to public
using (((auth.uid() = employee_id) AND check_user_has_permission(auth.uid(), '["appointment:read"]'::jsonb)));


create policy "Enable user to update their own appointments"
on "public"."appointments"
as permissive
for update
to public
using ((((auth.uid() = employee_id) AND check_user_has_permission(auth.uid(), '["appointment:write"]'::jsonb)) OR ((auth.uid() = client_id) AND check_user_has_permission(auth.uid(), '["appointment:cancel"]'::jsonb)) OR check_user_has_permission(auth.uid(), '["appointment:write", "appointment:admin"]'::jsonb)))
with check ((((auth.uid() = employee_id) AND check_user_has_permission(auth.uid(), '["appointment:write"]'::jsonb)) OR ((auth.uid() = client_id) AND check_user_has_permission(auth.uid(), '["appointment:cancel"]'::jsonb)) OR check_user_has_permission(auth.uid(), '["appointment:write", "appointment:admin"]'::jsonb)));


create policy "Enable user to upsert their own appointments"
on "public"."appointments"
as permissive
for update
to public
using ((((auth.uid() = employee_id) AND check_user_has_permission(auth.uid(), '["appointment:write"]'::jsonb)) OR ((auth.uid() = client_id) AND check_user_has_permission(auth.uid(), '["appointment:cancel"]'::jsonb)) OR check_user_has_permission(auth.uid(), '["appointment:write", "appointment:admin"]'::jsonb)))
with check ((((auth.uid() = employee_id) AND check_user_has_permission(auth.uid(), '["appointment:write"]'::jsonb)) OR ((auth.uid() = client_id) AND check_user_has_permission(auth.uid(), '["appointment:cancel"]'::jsonb)) OR check_user_has_permission(auth.uid(), '["appointment:write", "appointment:admin"]'::jsonb)));


create policy "allow user to insert their own appointments"
on "public"."appointments"
as permissive
for insert
to public
with check ((((auth.uid() = employee_id) AND check_user_has_permission(auth.uid(), '["appointment:write"]'::jsonb)) OR ((auth.uid() = client_id) AND check_user_has_permission(auth.uid(), '["appointment:cancel"]'::jsonb)) OR check_user_has_permission(auth.uid(), '["appointment:write", "appointment:admin"]'::jsonb)));


create policy "Enable clients to read their employees"
on "public"."employee_has_clients"
as permissive
for select
to public
using (((client_id = auth.uid()) AND check_user_has_permission(auth.uid(), '["organization:read"]'::jsonb)));


create policy "Enable employee to read their clients"
on "public"."employee_has_clients"
as permissive
for select
to public
using (((auth.uid() = employee_id) AND check_user_has_permission(auth.uid(), '["organization:read"]'::jsonb)));


create policy "Enable read access if client/employee are connected"
on "public"."user_has_role"
as permissive
for select
to public
using ((check_are_users_connected(auth.uid(), user_id) AND check_user_has_permission(auth.uid(), '["organization:read"]'::jsonb)));


create policy "Enable read access if client/employee are connected"
on "public"."user_profile"
as permissive
for select
to public
using ((check_are_users_connected(auth.uid(), user_id) AND check_user_has_permission(auth.uid(), '["organization:read"]'::jsonb)));


create policy "allow user to read their own profile"
on "public"."user_profile"
as permissive
for select
to public
using (((auth.uid() = user_id) AND check_user_has_permission(auth.uid(), '["organization:read"]'::jsonb)));



