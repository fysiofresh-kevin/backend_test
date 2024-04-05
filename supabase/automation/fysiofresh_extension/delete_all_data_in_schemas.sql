CREATE FUNCTION public.delete_all_data_in_schemas() RETURNS void AS $$
DECLARE
    table_names TEXT := '';
BEGIN
    SELECT INTO table_names
        string_agg(quote_ident(schemaname) || '.' || quote_ident(tablename), ', ')
    FROM pg_tables
    WHERE schemaname IN ('auth', 'public');

    IF table_names <> '' THEN
        EXECUTE 'TRUNCATE TABLE ' || table_names || ' CASCADE';
    END IF;
END;
$$ LANGUAGE plpgsql;