CREATE POLICY "Enable all access to authenticated users (temporary)" ON "public"."appointment_has_services"
    AS PERMISSIVE FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true)