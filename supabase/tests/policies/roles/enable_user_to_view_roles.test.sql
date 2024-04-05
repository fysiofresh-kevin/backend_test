-- ARRANGE

BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('user_with_permission');
SELECT tests.create_supabase_user('user_without_permission');

-- Create roles
SELECT public.map_role_and_permissions('role_with_permission', ARRAY['organization:read']);
SELECT public.map_role_and_permissions('role_without_permission', ARRAY['']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_user('user_with_permission') ->> 'id')::uuid, 'role_with_permission'),
    ((tests.get_supabase_user('user_without_permission') ->> 'id')::uuid, 'role_without_permission');


-- Creating 3 roles making a total of 5 roles incl. the 2 created during Create roles
INSERT INTO public.roles
    ("role")
VALUES
    ('test_client'),
    ('test_employee'),
    ('test_admin');

SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.roles
    ENABLE ROW LEVEL SECURITY;

SELECT plan(3);

-- 1: user has permission, information returned as expected
SELECT tests.authenticate_as('user_with_permission');

SELECT results_eq(
               ('SELECT count(*) FROM roles'),
               $$VALUES (5::bigint)$$,
               'confirm that user with permission can read all roles'
       );

SELECT tests.clear_authentication();

-- 2: user does not have permission, information access denied
SELECT tests.authenticate_as('user_without_permission');

SELECT is_empty(
               $$ SELECT * FROM roles $$,
               'confirm that no rows are returned for user without roles');

SELECT tests.clear_authentication();

-- 3: unauthenticated, information access denied
SELECT is_empty(
               $$ SELECT * FROM roles $$,
               'confirm that no rows are returned for unauthenticated user');

SELECT * from finish();
ROLLBACK;