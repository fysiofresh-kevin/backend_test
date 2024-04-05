CREATE OR REPLACE FUNCTION public.create_invoice_with_subscription
    (input_invoice_id bigint, input_client_id uuid, input_subscription_id TEXT)
    RETURNS void AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.subscriptions WHERE id = input_subscription_id
    )
    THEN
        PERFORM create_subscription_for_client(input_client_id, input_subscription_id);
    END IF;

    INSERT INTO invoices
    (id, "from", "to", subscription_id)
    VALUES
        (input_invoice_id, NOW(), NOW(), input_subscription_id);
END;
$$ language plpgsql;




