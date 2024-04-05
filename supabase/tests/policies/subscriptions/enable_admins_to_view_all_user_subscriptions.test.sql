-- ARRANGE

BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- Wipe data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('user_with_permission');
SELECT tests.create_supabase_user('user_without_permission');
SELECT tests.create_supabase_user('client_with_sub_1');
SELECT tests.create_supabase_user('client_with_sub_2');
SELECT tests.create_supabase_user('client_with_sub_3');

-- Create roles with permissions
SELECT map_role_and_permissions('role_with_admin_permissions', ARRAY['organization:read','organization:admin']);
SELECT map_role_and_permissions('role_without_permissions', ARRAY['']);


-- connect users with roles
INSERT INTO public.user_has_role
(user_id, role)
VALUES
    ((tests.get_supabase_user('user_with_permission') ->> 'id')::uuid, 'role_with_admin_permissions'),
    ((tests.get_supabase_user('user_without_permission') ->> 'id')::uuid, 'role_without_permissions');

-- create subscriptions
INSERT INTO subscriptions
(id, created_at, last_paid, status, client_id)
VALUES
    ('fake-sub-1', '2024-01-18 11:12:10.808706+00', '2024-01-05 15:12:38+00',
     'ACTIVE', (tests.get_supabase_user('client_with_sub_1') ->> 'id')::uuid),
    ('fake-sub-2', '2024-01-18 11:12:10.808706+00', '2024-01-05 15:12:38+00',
     'ACTIVE', (tests.get_supabase_user('client_with_sub_2') ->> 'id')::uuid),
    ('fake-sub-3', '2024-01-18 11:12:10.808706+00', '2024-01-05 15:12:38+00',
     'ACTIVE', (tests.get_supabase_user('client_with_sub_3') ->> 'id')::uuid);

-- disable RLS on all tables and enable on subscriptions table
SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.subscriptions
    ENABLE ROW LEVEL SECURITY;

-- ASSERT
SELECT plan(3);

-- 1: user has permission, information returned as expected
SELECT tests.authenticate_as('user_with_permission');

SELECT results_eq(
    ('SELECT count(*) FROM subscriptions'),
    $$VALUES (3::bigint)$$,
    'confirm that admin can read all three subscriptions'
);


SELECT tests.clear_authentication();

-- 2: user does not have permission, information access denied
SELECT tests.authenticate_as('user_without_permission');

SELECT is_empty(
               $$ SELECT * FROM subscriptions $$,
                'confirm that no rows are returned for user without permissions');

SELECT tests.clear_authentication();

-- 3: unauthenticated, information access denied
SELECT is_empty(
               $$ SELECT * FROM subscriptions $$,
               'confirm that no rows are returned for unauthenticated user');

SELECT * from finish();
ROLLBACK;