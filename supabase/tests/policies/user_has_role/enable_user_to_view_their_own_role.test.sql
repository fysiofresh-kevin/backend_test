-- ARRANGE

BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('user_with_role');
SELECT tests.create_supabase_user('user_without_role');

-- Create roles
SELECT public.map_role_and_permissions('role_without_permission', ARRAY['']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_user('user_with_role') ->> 'id')::uuid, 'role_without_permission');
SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.user_has_role
    ENABLE ROW LEVEL SECURITY;

SELECT plan(3);

-- 1: user has permission, information returned as expected
SELECT tests.authenticate_as('user_with_role');

SELECT results_eq(
               ('SELECT count(*) FROM user_has_role'),
               $$VALUES (1::bigint)$$,
               'confirm that user can read their own role from user_has_role'
       );

SELECT tests.clear_authentication();

-- 2: user does not have permission to access all user_has_role rows, can only access their own user_has_role
SELECT tests.authenticate_as('user_without_role');

SELECT is_empty(
               $$ SELECT * FROM user_has_role $$,
               'confirm that no rows are returned for user without roles');

SELECT tests.clear_authentication();

-- 3: unauthenticated, information access denied
SELECT is_empty(
               $$ SELECT * FROM user_has_role $$,
               'confirm that no rows are returned for unauthenticated user');

SELECT * from finish();
ROLLBACK;