DROP FUNCTION public.update_client_to_employees_relationships(p_client_id text, p_employee_ids text[]);

CREATE OR REPLACE FUNCTION update_client_to_employees_relationships(
    p_client_id UUID,
    p_employee_ids UUID[]
) RETURNS TEXT AS $$

DECLARE
    v_employee_ids UUID[];
    v_employee_id UUID;
BEGIN

    v_employee_ids := p_employee_ids;
    -- Insert added employees
    FOREACH v_employee_id IN ARRAY v_employee_ids
        LOOP
            INSERT INTO employee_has_clients (client_id, employee_id)
            VALUES (p_client_id, v_employee_id)
            ON CONFLICT (client_id, employee_id) DO NOTHING;
        END LOOP;

    -- Cleanup unmapped entries
    DELETE FROM employee_has_clients
    WHERE client_id = p_client_id AND employee_id NOT IN (SELECT unnest(p_employee_ids));
    return 'ok';
EXCEPTION
    WHEN OTHERS THEN
        -- Error handling (log the error, perhaps)
        RETURN SQLERRM;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_employee_to_clients_relationships(
    p_employee_id UUID,
    p_client_ids UUID[]
) RETURNS TEXT AS $$

DECLARE
    v_client_ids UUID[];
    v_client_id UUID;
BEGIN

    v_client_ids := p_client_ids;
    -- Insert added employees
    FOREACH v_client_id IN ARRAY v_client_ids
        LOOP
            INSERT INTO employee_has_clients (employee_id, client_id)
            VALUES (p_employee_id, v_client_id)
            ON CONFLICT (employee_id, client_id) DO NOTHING;
        END LOOP;

    -- Cleanup unmapped entries
    DELETE FROM employee_has_clients
    WHERE employee_id = p_employee_id AND client_id NOT IN (SELECT unnest(p_client_ids));
    return 'ok';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'error: %', SQLERRM;
        -- Error handling (log the error, perhaps)
        RETURN SQLERRM;
END;
$$ LANGUAGE plpgsql;