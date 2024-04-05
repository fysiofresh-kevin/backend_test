CREATE OR REPLACE FUNCTION upsert_appointment (
    p_appointment_json JSONB,
    p_service_ids integer[]
) RETURNS boolean AS $$
DECLARE
    _id integer;
    _client_id uuid;
    _employee_id uuid;
    _start timestamp;
    _end timestamp;
    _notes text;
    _status appointment_status;
    _service_ids int[] := '{}';
    _service_id int;
BEGIN
    _id := NULLIF(p_appointment_json ->> 'id', '')::integer;
    _client_id := (p_appointment_json ->> 'client_id')::uuid;
    _employee_id := (p_appointment_json ->> 'employee_id')::uuid;
    _start := (p_appointment_json ->> 'start')::timestamp;
    _end := (p_appointment_json ->> 'end')::timestamp;
    _notes := p_appointment_json ->> 'notes';
    _status := (p_appointment_json ->> 'status')::appointment_status;

    RAISE NOTICE 'Status %', _status;
    IF _status IS NULL THEN
        RAISE NOTICE 'Status is null. JSON input: %', p_appointment_json;
        RETURN false;
    END IF;

    IF _id IS NULL THEN
        INSERT INTO appointments (client_id, employee_id, "start", "end", notes, "status")
        VALUES (_client_id, _employee_id, _start, _end, _notes, _status)
        RETURNING id INTO _id;
    ELSE
        INSERT INTO appointments (id, client_id, employee_id, "start", "end", notes, "status")
        VALUES (_id, _client_id, _employee_id, _start, _end, _notes, _status)
        ON CONFLICT (id)
        DO
            UPDATE SET
                client_id = _client_id,
                employee_id = _employee_id,
                "start" = _start,
                "end" = _end,
                notes = _notes,
                "status" = _status;
    END IF;

    _service_ids := p_service_ids;
    FOREACH _service_id IN ARRAY _service_ids
        LOOP
            INSERT INTO appointment_has_services (appointment_id, service_id)
            VALUES (_id, _service_id)
            ON CONFLICT (appointment_id, service_id) DO NOTHING;
        END LOOP;

    DELETE FROM appointment_has_services
    WHERE appointment_id = _id AND service_id NOT IN (SELECT unnest(_service_ids));
    RETURN true;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS _notes = PG_EXCEPTION_CONTEXT;
        RAISE NOTICE 'Error: %, Context: %', SQLERRM, _notes;
        RETURN false;
END;
$$ LANGUAGE plpgsql;