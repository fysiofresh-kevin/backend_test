CREATE POLICY "Enable user to view permissions"
    ON "public"."permissions"
    FOR SELECT
    TO AUTHENTICATED
    USING ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['organization:read']));

CREATE POLICY "Enable user to view permissions for roles"
    ON "public"."role_has_permissions"
    FOR SELECT
    TO AUTHENTICATED
    USING ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['organization:read']));

ALTER TABLE "public"."permissions"
    ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."role_has_permissions"
    ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable update for users based on user_id" ON "public"."invoices"
AS PERMISSIVE FOR UPDATE
TO public
USING (check_user_has_permission(auth.uid(), ARRAY['invoices:read'::text, 'invoices:admin'::text]))
WITH CHECK (check_user_has_permission(auth.uid(), ARRAY['invoices:read'::text, 'invoices:admin'::text]))