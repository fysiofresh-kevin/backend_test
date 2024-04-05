BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

SELECT delete_all_data_in_schemas();

-- Insert test data
SELECT tests.create_supabase_user('user_with_permission');
SELECT tests.create_supabase_user('user_without_permission');

INSERT INTO public.roles (role)
VALUES ('test_user_with_permission'),
       ('test_user_without_permission');

INSERT INTO public.user_has_role (user_id, role)
VALUES ((SELECT tests.get_supabase_user('user_with_permission') ->> 'id')::UUID, 'test_user_with_permission'),
       ((SELECT tests.get_supabase_user('user_without_permission') ->> 'id')::UUID, 'test_user_without_permission');

SELECT public.map_role_and_permissions('test_user_with_permission', ARRAY['organization:read', 'organization:admin', 'invoices:read', 'invoices:admin']);

INSERT INTO public.user_profile (user_id, name)
VALUES ((SELECT tests.get_supabase_user('user_with_permission') ->> 'id')::UUID, 'Test client with permission'),
       ((SELECT tests.get_supabase_user('user_without_permission') ->> 'id')::UUID, 'Test client without permission');

INSERT INTO subscriptions (id, created_at, last_paid, status, client_id)
VALUES ('sub_001', NOW(), NOW(), 'active', (SELECT tests.get_supabase_user('user_with_permission') ->> 'id')::UUID),
       ('sub_002', NOW(), NOW(), 'pending', (SELECT tests.get_supabase_user('user_with_permission') ->> 'id')::UUID),
       ('sub_003', NOW(), NOW(), 'active', (SELECT tests.get_supabase_user('user_with_permission') ->> 'id')::UUID),
       ('sub_004', NOW(), NOW(), 'cancelled', (SELECT tests.get_supabase_user('user_with_permission') ->> 'id')::UUID),
       ('sub_005', NOW(), NOW(), 'expired', (SELECT tests.get_supabase_user('user_with_permission') ->> 'id')::UUID);

INSERT INTO invoices (id, created_at, "from", "to", billwerk_id, dinero_id, status, change_log, subscription_id)
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


-- DO
-- $$
--     BEGIN
--         RAISE NOTICE 'Invoices: %', (SELECT COUNT(*) FROM invoices);
--         RAISE NOTICE 'subscriptions: %', (SELECT COUNT(*) FROM subscriptions);
--         RAISE NOTICE 'user_profile: %', (SELECT COUNT(*) FROM user_profile);
--     END
-- $$;


-- Define test plan
SELECT plan(7);

-- Test for existence of table
SELECT has_table('public', 'invoices', 'Table: invoices exists');
SELECT has_table('public', 'subscriptions', 'Table: subscriptions exists');
SELECT has_table('public', 'user_profile', 'Table: user_profile exists');

-- Authenticate as user with permission and test function output
SELECT tests.authenticate_as('user_with_permission');
SELECT isnt(get_all_client_invoices(), '{}', 'Authorized user gets all invoices');
SELECT tests.clear_authentication();

-- Authenticate as user without permission and test function output
SELECT tests.authenticate_as('user_without_permission');
SELECT is(get_all_client_invoices(), '{}', 'Unauthorized user cannot see invoices (empty array returned)');
SELECT tests.clear_authentication();

-- Test function without authentication
SELECT is(get_all_client_invoices(), '{}', 'Anon cannot see invoices (empty array returned)');
SELECT isnt(get_all_client_invoices(), NULL, 'function does not return null');

-- Finish tests
SELECT *
FROM finish();
ROLLBACK;


