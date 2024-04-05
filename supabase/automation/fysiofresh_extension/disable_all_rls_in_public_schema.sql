CREATE FUNCTION public.disable_all_rls_in_public_schema() RETURNS void AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
        LOOP
            EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' DISABLE ROW LEVEL SECURITY';
        END LOOP;
END;
$$ LANGUAGE plpgsql;

