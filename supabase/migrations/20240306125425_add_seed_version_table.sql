CREATE TABLE public.seed_version
(
    version INTEGER PRIMARY KEY
);

CREATE POLICY "Enable read access for all users" ON "public"."seed_version"
    AS PERMISSIVE FOR SELECT
    TO anon
    USING (TRUE);

ALTER TABLE public.seed_version
    ENABLE ROW LEVEL SECURITY;

drop policy "Enable all access to authenticated users (temporary)" on "public"."appointment_has_services";

