DROP FUNCTION public.collect_draft_invoice_data_for_processing(p_invoice_ids INTEGER[]);
CREATE OR REPLACE FUNCTION public.collect_draft_invoice_data_for_processing(
    p_invoice_ids INTEGER[]
) RETURNS JSONB AS
$$
DECLARE
    v_subscription_id TEXT;
    v_appointments    APPOINTMENTS[];
    v_appointment     APPOINTMENTS;
    v_services        JSONB = '[]';
    v_invoices        INVOICES[];
    v_invoice         INVOICES;
    drafts            JSONB = '[]';
    draft_instance    JSONB = '{}';
BEGIN
    SELECT ARRAY_AGG(invoices.*)
    INTO v_invoices
    FROM invoices
    WHERE id = ANY (p_invoice_ids)
      AND status = 'draft';

    FOR i IN 1..ARRAY_LENGTH(v_invoices, 1)
        LOOP
            draft_instance := '{}'::JSONB;
            v_invoice := v_invoices[i];

            SELECT subscription_id
            INTO v_subscription_id
            FROM subscription_has_invoices
            WHERE invoice_id = v_invoice.id;

            SELECT ARRAY_AGG(a.*)
            INTO v_appointments
            FROM appointments a
                     INNER JOIN
                 invoice_has_appointments iha ON a.id = iha.appointment_id
            WHERE iha.invoice_id = v_invoice.id;

            FOR j IN 1..ARRAY_LENGTH(v_appointments, 1)
                LOOP
                    v_appointment := v_appointments[j];

                    SELECT JSONB_AGG(
                                   JSONB_BUILD_OBJECT(
                                           'title', title,
                                           'description', description,
                                           'price', price
                                   )
                           )
                    INTO v_services
                    FROM services s
                             INNER JOIN
                         appointment_has_services ahs ON s.id = ahs.service_id
                    WHERE appointment_id = v_appointment.id;

--                     RAISE NOTICE 'SERVICES: %', v_services;
--                     RAISE NOTICE 'Invoice: %', v_invoice;
--                     RAISE NOTICE 'lb';
                    draft_instance := JSON_BUILD_OBJECT(
                            'from', v_invoice."from",
                            'to', v_invoice."to",
                            'order_lines', v_services);
                    drafts := drafts || draft_instance;
                END LOOP;
        END LOOP;
    RETURN drafts;
    -- chatGPT:IGNORE, exception handling, store errors in jsonObject.errors for logging/flagging
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.mark_invoice_as_pending(
    invoice_ids INTEGER[]
) RETURNS VOID AS
$$ --return successful
DECLARE
BEGIN
    --loop through all invoice_ids
    --update invoice as pending, by invoice_id
    --end loop
END;
$$ LANGUAGE plpgsql;