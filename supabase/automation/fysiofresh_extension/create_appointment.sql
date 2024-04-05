CREATE OR REPLACE FUNCTION public.create_appointment
    (input_appointment_id bigint, input_client_id UUID, input_employee_id UUID, input_status appointment_status)
    RETURNS void AS $$
BEGIN
    INSERT INTO appointments
    (id, client_id, employee_id, "status")
    VALUES
        (input_appointment_id, input_client_id, input_employee_id, input_status);
END;
$$ language plpgsql;
