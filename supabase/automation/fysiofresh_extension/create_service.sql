CREATE OR REPLACE FUNCTION public.create_service
    (input_service_id bigint, input_title TEXT)
    RETURNS void AS $$
BEGIN
    INSERT INTO services
    (id, "status", title)
    VALUES
        (input_service_id, 'ACTIVE', input_title);
END;
$$ language plpgsql;
