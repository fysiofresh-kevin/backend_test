BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

SELECT delete_all_data_in_schemas();

-- Insert test data
DELETE FROM public.user_profile;
DELETE FROM public.invoices;
DELETE FROM public.subscriptions;
DELETE FROM public.user_has_role;
DELETE FROM public.role_has_permissions;
DELETE FROM public.roles;

SELECT tests.create_supabase_user('user_with_permission');
SELECT tests.create_supabase_user('user_without_permission');

INSERT INTO public.roles (role)
VALUES ('test_user_with_permission'),
       ('test_user_without_permission');

DELETE FROM public.user_has_role;
INSERT INTO public.user_has_role (user_id, role)
VALUES ((SELECT tests.get_supabase_user('user_with_permission') ->> 'id')::UUID, 'test_user_with_permission');

SELECT public.map_role_and_permissions('test_user_with_permission', ARRAY['organization:read', 'organization:admin', 'invoices:read', 'invoices:admin']);

DELETE FROM public.user_profile;
INSERT INTO public.user_profile (user_id, name)
VALUES ((SELECT tests.get_supabase_user('user_with_permission') ->> 'id')::UUID, 'Test client with permission');

DELETE FROM public.subscriptions;
INSERT INTO subscriptions (id, created_at, last_paid, status, client_id)
VALUES ('sub_001', NOW(), NOW(), 'active', (SELECT tests.get_supabase_user('user_with_permission') ->> 'id')::UUID),
       ('sub_002', NOW(), NOW(), 'pending', (SELECT tests.get_supabase_user('user_with_permission') ->> 'id')::UUID),
       ('sub_003', NOW(), NOW(), 'active', (SELECT tests.get_supabase_user('user_with_permission') ->> 'id')::UUID),
       ('sub_004', NOW(), NOW(), 'cancelled', (SELECT tests.get_supabase_user('user_with_permission') ->> 'id')::UUID),
       ('sub_005', NOW(), NOW(), 'expired', (SELECT tests.get_supabase_user('user_with_permission') ->> 'id')::UUID);

DELETE FROM public.invoices;
INSERT INTO invoices (id, created_at, "from", "to", billwerk_id, dinero_id, status, change_log, subscription_id)
VALUES (1, '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z', '2024-01-10T00:00:00Z', 'BW001', 'DN001', 'draft',
        '{"note": "Initial creation"}', 'sub_001'),
       (2, '2024-01-02T00:00:00Z', '2024-01-02T00:00:00Z', '2024-01-12T00:00:00Z', 'BW002', 'DN002', 'booked',
        '{"note": "Paid on 2024-01-02"}', 'sub_002'),
       (3, '2024-01-03T00:00:00Z', '2024-01-03T00:00:00Z', '2024-01-13T00:00:00Z', 'BW003', 'DN003', 'settled',
        '{"note": "Reminder sent on 2024-01-10"}', 'sub_003'),
       (4, '2024-01-04T00:00:00Z', '2024-01-04T00:00:00Z', '2024-01-14T00:00:00Z', 'BW004', 'DN004', 'booked',
        '{"note": "Cancelled due to error"}', 'sub_004'),
       (5, '2024-01-05T00:00:00Z', '2024-01-05T00:00:00Z', '2024-01-15T00:00:00Z', 'BW005', 'DN005', 'draft',
        '{"note": "Waiting for approval"}', 'sub_005');


-- Define test plan
SELECT plan(2);

-- Authenticate as user with permission and test function output
SELECT tests.authenticate_as('user_with_permission');
SELECT isnt(get_client_by_invoice(1), '{}', 'Client is found by invoice id');
SELECT tests.clear_authentication();

-- Test function without authentication
SELECT is(get_client_by_invoice(1), '{}', 'Anon cannot see invoices (empty array returned)');

-- Finish tests
SELECT *
FROM finish();
ROLLBACK;


