-- ARRANGE

BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- Wipe data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('user_with_permission');
SELECT tests.create_supabase_user('user_without_permission');

-- Create roles with permissions
SELECT map_role_and_permissions('test_user_with_permission', ARRAY['invoices:read','invoices:admin']);
SELECT map_role_and_permissions('test_user_without_permission', ARRAY['']);


-- connect users with roles
INSERT INTO public.user_has_role
(user_id, role)
VALUES
    ((tests.get_supabase_user('user_with_permission') ->> 'id')::uuid, 'test_user_with_permission'),
    ((tests.get_supabase_user('user_without_permission') ->> 'id')::uuid, 'test_user_without_permission');

-- create subscriptions
INSERT INTO subscriptions
(id, created_at, last_paid, status, client_id)
VALUES
    ('fake-sub-2', '2024-01-18 11:12:10.808706+00', '2024-01-05 15:12:38+00',
     'ACTIVE', (tests.get_supabase_user('user_with_permission') ->> 'id')::uuid);

-- create invoices
INSERT INTO invoices
    (id, created_at, "from", "to", billwerk_id, dinero_id, status, change_log, subscription_id)
VALUES
    (100, '2024-01-24 12:39:46+00', '2024-01-24 12:39:46+00', '2024-01-31 12:39:51+00',
     'bw1', 'dn1', 'draft', NULL, 'fake-sub-2'),
    (101, '2023-01-24 12:39:46+00', '2023-01-24 12:39:46+00', '2023-01-31 12:39:51+00',
     'bw2', 'dn2', 'booked', NULL, 'fake-sub-2');

-- disable RLS on all tables and enable on invoices
SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.invoices
    ENABLE ROW LEVEL SECURITY;

-- ASSERT
SELECT plan(3);

-- 1: user has permission, information returned as expected
SELECT tests.authenticate_as('user_with_permission');

SELECT results_eq(
    ('SELECT count(*) FROM invoices'),
    $$VALUES (2::bigint)$$,
    'confirm that admin can read all invoices'
);


SELECT tests.clear_authentication();

-- 2: user does not have permission, information access denied
SELECT tests.authenticate_as('user_without_permission');

SELECT is_empty(
               $$ SELECT * FROM invoices $$,
               'confirm that no rows are returned for user without permissions');

SELECT tests.clear_authentication();

-- 3: unauthenticated, information access denied
SELECT is_empty(
               $$ SELECT * FROM invoices $$,
               'confirm that no rows are returned for unauthenticated user');

SELECT * from finish();
ROLLBACK;