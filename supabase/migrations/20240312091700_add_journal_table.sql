CREATE TABLE public.journals
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_id UUID NOT NULL,
    appointment_id INTEGER,
    author_id UUID NOT NULL,
    client_id UUID NOT NULL,
    published BOOLEAN DEFAULT false,
    content TEXT NOT NULL,
    title TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);


CREATE OR REPLACE FUNCTION ensure_same_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.journal_id IS NULL THEN
        NEW.journal_id := NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ensure_same_id
BEFORE INSERT ON journals
FOR EACH ROW EXECUTE FUNCTION ensure_same_id();


CREATE POLICY "Enable admin to read all journals"
    ON "public"."journals"
    AS permissive
    FOR SELECT
    TO authenticated
    USING ((check_user_has_permission(auth.uid(), ARRAY['organization:admin'])));

CREATE POLICY "Enable employee to read their clients journals"
    ON "public"."journals"
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM public.employee_has_clients
            WHERE
                public.employee_has_clients.client_id = journals.client_id
                AND public.employee_has_clients.employee_id = auth.uid()
                AND check_user_has_permission(auth.uid(), ARRAY['journal:read'])
        )
    );

CREATE POLICY "Enable employee to create their clients journals"
    ON "public"."journals"
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM public.employee_has_clients
            WHERE
                public.employee_has_clients.client_id = journals.client_id
                AND public.employee_has_clients.employee_id = auth.uid()
                AND check_user_has_permission(auth.uid(), ARRAY['journal:write'])
        )
    );

CREATE POLICY "Enable admin to create journals"
    ON "public"."journals"
    AS permissive
    FOR INSERT
    TO authenticated
    WITH CHECK (
        ((check_user_has_permission(auth.uid(), ARRAY['organization:admin', 'journal:write'])))
    );


ALTER TABLE public.journals
    ENABLE ROW LEVEL SECURITY;
