DROP POLICY IF EXISTS "Enable user to add services to appointments"
    ON "public"."appointment_has_services";

DROP POLICY IF EXISTS "Enable user to remove services from appointments"
    ON "public"."appointment_has_services";


CREATE POLICY "Enable user to add services to appointments"
    ON "public"."appointment_has_services"
    AS PERMISSIVE
    FOR INSERT
    TO AUTHENTICATED
    WITH CHECK (
        (EXISTS (
            SELECT 1
            FROM "public"."appointments"
            WHERE "appointments".id = appointment_id
            AND "appointments".employee_id = auth.uid()
            AND check_user_has_permission(auth.uid(), ARRAY['appointment:write'])
        ))
        OR check_user_has_permission(auth.uid(), ARRAY['appointment:write', 'organization:admin'])
    );

CREATE POLICY "Enable user to remove services from appointments"
    ON "public"."appointment_has_services"
    AS PERMISSIVE
    FOR DELETE
    TO AUTHENTICATED
    USING (
        (EXISTS (
            SELECT 1
            FROM "public"."appointments"
            WHERE "appointments".id = appointment_id
            AND "appointments".employee_id = auth.uid()
            AND check_user_has_permission(auth.uid(), ARRAY['appointment:write'])
        ))
        OR check_user_has_permission(auth.uid(), ARRAY['appointment:write', 'organization:admin'])
    );