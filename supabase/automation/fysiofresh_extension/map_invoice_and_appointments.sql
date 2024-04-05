CREATE OR REPLACE FUNCTION public.map_invoice_and_appointments
(input_invoice_id bigint, input_appointment_ids bigint[])
    RETURNS void AS $$
DECLARE appointment bigint;
BEGIN
    -- Insert invoice and appointments into the junction table invoice_has_appointments
    FOREACH appointment IN ARRAY input_appointment_ids LOOP
            INSERT INTO public.invoice_has_appointments (invoice_id, appointment_id)
            VALUES (input_invoice_id, appointment)
            ON CONFLICT (invoice_id, appointment_id) DO NOTHING;
        END LOOP;
END;
$$ LANGUAGE plpgsql;
