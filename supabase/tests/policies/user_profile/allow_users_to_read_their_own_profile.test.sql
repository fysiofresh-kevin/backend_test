-- create dummy user
-- add role to user
-- add permission to users role

-- assert that it returns true for authenticated user with permission
-- assert that it returns false for authenticated user but no permission
-- assert that it returns false for anon user

BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('user_with_permission');
SELECT tests.create_supabase_user('user_without_permission');

-- Create roles
SELECT public.map_role_and_permissions('test_user_with_permission', ARRAY['organization:read']);
SELECT public.map_role_and_permissions('test_user_without_permission', ARRAY['']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_user('user_with_permission') ->> 'id')::uuid, 'test_user_with_permission'),
    ((tests.get_supabase_user('user_without_permission') ->> 'id')::uuid, 'test_user_without_permission');


-- Connect user with profile
INSERT INTO public.user_profile
    (user_id, name)
VALUES
    ((tests.get_supabase_user('user_with_permission') ->> 'id')::uuid, 'Test client with permission'),
    ((tests.get_supabase_user('user_without_permission') ->> 'id')::uuid, 'Test client without permission');

SELECT plan(3);

-- 1: user has permission, information returned as expected
SELECT tests.authenticate_as('user_with_permission');

SELECT results_eq(
               ('SELECT count(*) FROM user_profile'),
               $$VALUES (1::bigint)$$,
               'confirm that client can read their own single profile'
       );

SELECT tests.clear_authentication();

-- 2: user does not have permission, information access denied
SELECT tests.authenticate_as('user_without_permission');

SELECT is_empty(
               $$ SELECT * FROM user_profile $$,
               'confirm that no rows are returned for user without permissions');

SELECT tests.clear_authentication();

-- 3: unauthenticated, information access denied
SELECT is_empty(
               $$ SELECT * FROM user_profile $$,
               'confirm that no rows are returned for unauthenticated user');

SELECT * from finish();
ROLLBACK;