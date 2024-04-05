CREATE OR REPLACE FUNCTION public.map_client_and_employee(client uuid, employee uuid) RETURNS void AS $$
BEGIN
    INSERT INTO employee_has_clients
    (client_id, employee_id)
    VALUES
        (client, employee);
END;
$$ language plpgsql;
