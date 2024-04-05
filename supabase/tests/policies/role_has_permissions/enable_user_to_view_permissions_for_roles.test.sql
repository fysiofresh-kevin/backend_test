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
SELECT public.map_role_and_permissions('role_with_client_permissions', ARRAY['appointment:read', 'appointment:cancel', 'organization:read', 'invoices:read', 'site:navigation:invoices']);
SELECT public.map_role_and_permissions('role_with_employee_permissions', ARRAY['appointment:read', 'appointment:cancel', 'organization:read', 'site:navigation:clients']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((SELECT tests.get_supabase_uid('user_with_permission')), 'role_with_permission'),
    ((SELECT tests.get_supabase_uid('user_without_permission')), 'role_without_permission');


SELECT plan(3);

-- 1: user has permission, information returned as expected
SELECT tests.authenticate_as('user_with_permission');

SELECT results_eq(
               ('SELECT count(*) FROM role_has_permissions'),
               $$VALUES (11::bigint)$$,
               'confirm that client can read permissions for roles'
       );

SELECT tests.clear_authentication();

-- 2: user does not have permission, information access denied
SELECT tests.authenticate_as('user_without_permission');

SELECT is_empty(
               $$ SELECT * FROM role_has_permissions $$,
               'confirm that no rows are returned for user without permissions');

SELECT tests.clear_authentication();

-- 3: unauthenticated, information access denied
SELECT is_empty(
               $$ SELECT * FROM role_has_permissions $$,
               'confirm that no rows are returned for unauthenticated user');

SELECT * from finish();
ROLLBACK;