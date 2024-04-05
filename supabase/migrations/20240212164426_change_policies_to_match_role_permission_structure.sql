drop policy "Enable user to delete appointments" on "public"."appointments";

drop policy "Enable admin to read all appointments" on "public"."appointments";

drop policy "Enable client to read their own appointments" on "public"."appointments";

drop policy "Enable employee to read their own appointments" on "public"."appointments";

drop policy "Enable user to update their own appointments" on "public"."appointments";

drop policy "Enable user to upsert their own appointments" on "public"."appointments";

drop policy "allow user to insert their own appointments" on "public"."appointments";

drop policy "Enable clients to read their employees" on "public"."employee_has_clients";

drop policy "Enable employee to read their clients" on "public"."employee_has_clients";

drop policy "Enables Admins to read all rows" on "public"."employee_has_clients";

drop policy "Enable Admins to insert new rows" on "public"."employee_has_clients";

drop policy "Enable Admins to write Employee Client connections" on "public"."employee_has_clients";

drop policy "Enable user to view roles" on "public"."roles";

drop policy "Enable admin to read all user roles" on "public"."roles";

drop policy "Enable user to view their own permissions" ON "public"."user_has_role";

drop policy "Enable read access if client/employee are connected" on "public"."user_has_role";

drop policy "Enable admin to view all user roles" on "public"."user_has_role";

drop policy "Enable read access if client/employee are connected" on "public"."user_profile";

drop policy "allow user to read their own profile" on "public"."user_profile";

drop policy "Enable admin access to all user profiles" on "public"."user_profile";

drop policy "Enable Admins to read all invoices" on "public"."invoices";

-- appointments
CREATE POLICY "Enable user to delete appointments"
    ON "public"."appointments"
    FOR DELETE
    USING ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['appointment:delete', 'appointment:admin']));

CREATE POLICY "Enable admin to read all appointments"
    ON "public"."appointments"
    FOR SELECT
    USING ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['appointment:read', 'appointment:admin']));


create policy "Enable client to read their own appointments"
    on "public"."appointments"
    as permissive
    for select
    to authenticated
    using (((auth.uid() = client_id) AND "public"."check_user_has_permission"(auth.uid(), ARRAY['appointment:read'])));


create policy "Enable employee to read their own appointments"
    on "public"."appointments"
    as permissive
    for select
    to authenticated
    using (((auth.uid() = employee_id) AND "public"."check_user_has_permission"(auth.uid(), ARRAY['appointment:read'])));


create policy "Enable user to update their own appointments"
    on "public"."appointments"
    as permissive
    for update
    to authenticated
    using ((((auth.uid() = employee_id) AND check_user_has_permission(auth.uid(), ARRAY['appointment:write']))
            OR ((auth.uid() = client_id) AND check_user_has_permission(auth.uid(), ARRAY['appointment:cancel']))
            OR check_user_has_permission(auth.uid(), ARRAY['appointment:write', 'appointment:admin'])))
    with check ((((auth.uid() = employee_id) AND check_user_has_permission(auth.uid(), ARRAY['appointment:write']))
            OR ((auth.uid() = client_id) AND check_user_has_permission(auth.uid(), ARRAY['appointment:cancel']))
            OR check_user_has_permission(auth.uid(), ARRAY['appointment:write', 'appointment:admin'])));


create policy "Enable user to upsert their own appointments"
    on "public"."appointments"
    as permissive
    for update
    to authenticated
    using ((((auth.uid() = employee_id) AND check_user_has_permission(auth.uid(), ARRAY['appointment:write']))
            OR ((auth.uid() = client_id) AND check_user_has_permission(auth.uid(), ARRAY['appointment:cancel']))
            OR check_user_has_permission(auth.uid(), ARRAY['appointment:write', 'appointment:admin'])))
    with check ((((auth.uid() = employee_id) AND check_user_has_permission(auth.uid(), ARRAY['appointment:write']))
            OR ((auth.uid() = client_id) AND check_user_has_permission(auth.uid(), ARRAY['appointment:cancel']))
            OR check_user_has_permission(auth.uid(), ARRAY['appointment:write', 'appointment:admin'])));


create policy "allow user to insert their own appointments"
    on "public"."appointments"
    as permissive
    for insert
    to authenticated
    with check ((((auth.uid() = employee_id) AND check_user_has_permission(auth.uid(), ARRAY['appointment:write']))
                OR ((auth.uid() = client_id) AND check_user_has_permission(auth.uid(), ARRAY['appointment:cancel']))
                OR check_user_has_permission(auth.uid(), ARRAY['appointment:write', 'appointment:admin'])));

-- employee_has_clients

create policy "Enable clients to read their employees"
    on "public"."employee_has_clients"
    as permissive
    for select
    to authenticated
    using (((client_id = auth.uid()) AND check_user_has_permission(auth.uid(), ARRAY['organization:read'])));

create policy "Enable employee to read their clients"
    on "public"."employee_has_clients"
    as permissive
    for select
    to authenticated
    using (((auth.uid() = employee_id) AND check_user_has_permission(auth.uid(), ARRAY['organization:read'])));

CREATE POLICY "Enables Admins to read all rows"
    ON "public"."employee_has_clients"
    FOR SELECT
    to authenticated
    USING ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['organization:read', 'organization:admin']));

CREATE POLICY "Enable Admins to write Employee Client connections"
    ON "public"."employee_has_clients"
    FOR UPDATE
    to authenticated
    USING ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['organization:write', 'organization:admin']))
    WITH CHECK ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['organization:write', 'organization:admin']));

CREATE POLICY "Enable Admins to insert new rows"
    ON "public"."employee_has_clients"
    FOR INSERT
    to authenticated
    WITH CHECK ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['organization:write', 'organization:admin']));

CREATE POLICY "Enable Admins to delete rows"
    ON "public"."employee_has_clients"
    FOR DELETE
    to authenticated
    USING ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['organization:write', 'organization:admin']));

-- roles

CREATE POLICY "Enable user to view roles"
    ON "public"."roles"
    FOR SELECT
    USING ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['organization:read']));

-- user_has_role

CREATE POLICY "Enable user to view their own role"
    ON "public"."user_has_role"
    FOR SELECT
    USING (("auth"."uid"() = "user_id"));


CREATE POLICY "Enable admin to view all user roles"
    ON "public"."user_has_role"
    FOR SELECT
    USING ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['organization:read', 'organization:admin']));


create policy "Enable read access if client/employee are connected"
    on "public"."user_has_role"
    as permissive
    for select
    to authenticated
    using ((check_are_users_connected(auth.uid(), user_id) AND check_user_has_permission(auth.uid(), ARRAY['organization:read'])));



-- user_profile

create policy "Enable admin access to all user profiles"
    ON "public"."user_profile"
    FOR SELECT
    USING ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['organization:read', 'organization:admin']));


create policy "Enable read access if client/employee are connected"
    on "public"."user_profile"
    as permissive
    for select
    to authenticated
    using ((check_are_users_connected(auth.uid(), user_id) AND check_user_has_permission(auth.uid(), ARRAY['organization:read'])));


create policy "allow user to read their own profile"
    on "public"."user_profile"
    as permissive
    for select
    to authenticated
    using (((auth.uid() = user_id) AND check_user_has_permission(auth.uid(), ARRAY['organization:read'])));


-- invoices

CREATE POLICY "Enable Admins to read all invoices"
    ON "public"."invoices"
    FOR SELECT
    USING
    ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['invoices:read', 'invoices:admin']));

DROP FUNCTION check_user_has_permission(uuid, jsonb);




