CREATE OR REPLACE FUNCTION public.create_subscription_for_client(client uuid, subscription_id TEXT) RETURNS void as $$
BEGIN
    INSERT INTO subscriptions
    (id, created_at, last_paid, status, client_id)
    VALUES
        (subscription_id, '2024-01-18 11:12:10.808706+00', '2024-01-05 15:12:38+00',
         'ACTIVE', client);
END;
$$ language plpgsql;
