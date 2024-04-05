BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

SELECT delete_all_data_in_schemas();

SELECT tests.create_supabase_user('client_with_invoices');
SELECT tests.create_supabase_user('client_without_invoices');

SELECT map_role_and_permissions('test_client_with_invoices', ARRAY['invoices:read']);
SELECT map_role_and_permissions('test_client_without_invoices', ARRAY['invoices:read']);

INSERT INTO public.user_has_role (user_id, "role") VALUES
((SELECT tests.get_supabase_user('client_with_invoices') ->> 'id')::UUID, 'test_client_with_invoices'),
((SELECT tests.get_supabase_user('client_without_invoices') ->> 'id')::UUID, 'test_client_without_invoices');

INSERT INTO public.user_profile (user_id, "name") VALUES
((SELECT tests.get_supabase_user('client_with_invoices') ->> 'id')::UUID, 'Test client with invoices'),
((SELECT tests.get_supabase_user('client_without_invoices') ->> 'id')::UUID, 'Test client without invoices');

INSERT INTO subscriptions (id, created_at, last_paid, "status", client_id)
VALUES ('sub_001', NOW(), NOW(), 'active', (SELECT tests.get_supabase_user('client_with_invoices') ->> 'id')::UUID),
       ('sub_002', NOW(), NOW(), 'pending', (SELECT tests.get_supabase_user('client_with_invoices') ->> 'id')::UUID),
       ('sub_003', NOW(), NOW(), 'active', (SELECT tests.get_supabase_user('client_with_invoices') ->> 'id')::UUID),
       ('sub_004', NOW(), NOW(), 'cancelled', (SELECT tests.get_supabase_user('client_with_invoices') ->> 'id')::UUID),
       ('sub_005', NOW(), NOW(), 'expired', (SELECT tests.get_supabase_user('client_with_invoices') ->> 'id')::UUID);

INSERT INTO invoices (id, created_at, "from", "to", billwerk_id, dinero_id, "status", change_log, subscription_id)
VALUES (999, '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z', '2024-01-10T00:00:00Z', 'BW001', 'DN001', 'draft',
        '{"note": "Initial creation"}', 'sub_001'),
       (888, '2024-01-02T00:00:00Z', '2024-01-02T00:00:00Z', '2024-01-12T00:00:00Z', 'BW002', 'DN002', 'booked',
        '{"note": "Paid on 2024-01-02"}', 'sub_002'),
       (777, '2024-01-03T00:00:00Z', '2024-01-03T00:00:00Z', '2024-01-13T00:00:00Z', 'BW003', 'DN003', 'settled',
        '{"note": "Reminder sent on 2024-01-10"}', 'sub_003'),
       (666, '2024-01-04T00:00:00Z', '2024-01-04T00:00:00Z', '2024-01-14T00:00:00Z', 'BW004', 'DN004', 'booked',
        '{"note": "Cancelled due to error"}', 'sub_004'),
       (555, '2024-01-05T00:00:00Z', '2024-01-05T00:00:00Z', '2024-01-15T00:00:00Z', 'BW005', 'DN005', 'draft',
        '{"note": "Waiting for approval"}', 'sub_005');

SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.invoices
    ENABLE ROW LEVEL SECURITY;

SELECT plan(3);

SELECT tests.authenticate_as('client_with_invoices');
SELECT is(
       can_client_access_invoice('sub_001', (SELECT tests.get_supabase_user('client_with_invoices') ->> 'id')::UUID)::boolean,
       TRUE,
       'Confirm that client has access to their invoices'
);
SELECT tests.clear_authentication();

SELECT tests.authenticate_as('client_without_invoices');
SELECT is(
       can_client_access_invoice('sub_001', (SELECT tests.get_supabase_user('client_without_invoices') ->> 'id')::UUID)::boolean,
       FALSE,
       'Client with no invoices cannot access any invoices'
);
SELECT tests.clear_authentication();

SELECT is(
       can_client_access_invoice('sub_001', NULL::UUID)::boolean,
       FALSE,
       'Anon cannot access any invoices'
);

-- Finish tests
SELECT *
FROM finish();
ROLLBACK;
