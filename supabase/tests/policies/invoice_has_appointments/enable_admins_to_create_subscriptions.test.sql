BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- Wipe data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('user_with_permission');
SELECT tests.create_supabase_user('user_without_permission');
SELECT tests.create_supabase_user('client');

-- Create roles with permissions
SELECT map_role_and_permissions('role_with_admin_permissions', ARRAY['organization:read','organization:admin', 'invoices:write']);
SELECT map_role_and_permissions('role_without_permissions', ARRAY['']);


-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, "role")
VALUES
    ((tests.get_supabase_uid('user_with_permission')), 'role_with_admin_permissions'),
    ((tests.get_supabase_uid('user_without_permission')), 'role_without_permissions');


-- disable RLS on all tables and enable on subscriptions table
SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.subscriptions
    ENABLE ROW LEVEL SECURITY;


SELECT plan(3);

-- 1: user has permission, information returned as expected
SELECT tests.authenticate_as('user_with_permission');

INSERT INTO subscriptions
    (id, created_at, last_paid, "status", client_id)
VALUES
    ('fake-sub-1', '2024-01-17 11:12:10.808706+00', '2024-01-05 15:12:38+00', 'ACTIVE', (tests.get_supabase_uid('client'))),
    ('fake-sub-2', '2024-01-18 11:12:10.808706+00', '2024-01-06 15:12:38+00', 'ACTIVE', (tests.get_supabase_uid('client'))),
    ('fake-sub-3', '2024-01-19 11:12:10.808706+00', '2024-01-07 15:12:38+00', 'ACTIVE', (tests.get_supabase_uid('client')));

SELECT results_eq(
    'SELECT count(*) FROM subscriptions',
    $$VALUES (3::bigint)$$,
    'confirm that admin can read all three subscriptions'
);

SELECT tests.clear_authentication();


-- 2: user does not have permission, information access denied
SELECT tests.authenticate_as('user_without_permission');

PREPARE user_without_permission_rls_thrower AS
INSERT INTO subscriptions
    (id, created_at, last_paid, "status", client_id)
VALUES
    ('fake-sub-4', '2024-01-16 11:12:10.808706+00', '2024-01-04 15:12:38+00', 'ACTIVE', (tests.get_supabase_uid('client')));
SELECT throws_ok(
    'user_without_permission_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "subscriptions"',
    'We should get a row-level security policy violation for insertion attempt'
);

SELECT tests.clear_authentication();

-- 3: unauthenticated, information access denied
PREPARE anon_rls_thrower AS
INSERT INTO subscriptions
    (id, created_at, last_paid, "status", client_id)
VALUES
    ('fake-sub-5', '2024-01-15 11:12:10.808706+00', '2024-01-03 15:12:38+00', 'ACTIVE', (tests.get_supabase_uid('client')));
SELECT throws_ok(
    'anon_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "subscriptions"',
    'We should get a row-level security policy violation for insertion attempt'
);

SELECT * from finish();
ROLLBACK;