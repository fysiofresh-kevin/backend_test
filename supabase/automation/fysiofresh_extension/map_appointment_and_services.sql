CREATE OR REPLACE FUNCTION public.map_appointment_and_services
    (input_appointment_id bigint, input_client_id UUID, input_employee_id UUID, input_service_id bigint)
RETURNS void AS $$
BEGIN
    -- Insert the appointment into the public.appointments table if it does not exist
    IF NOT EXISTS (
        SELECT 1 FROM public.appointments WHERE id = input_appointment_id
        )
        THEN
            PERFORM public.create_appointment
                (input_appointment_id, input_client_id, input_employee_id, 'completed');
    END IF;

    -- Insert the service into the public.services table if it does not exist
    IF NOT EXISTS (
        SELECT 1 FROM public.services WHERE id = input_service_id
        )
        THEN
            PERFORM public.create_service
                (input_service_id, 'Test treatment');
    END IF;
    -- Insert input_appointment and input_service into the junction table appointment_has_services
    INSERT INTO public.appointment_has_services (appointment_id, service_id)
    VALUES (input_appointment_id, input_service_id);

END;
$$ LANGUAGE plpgsql;
