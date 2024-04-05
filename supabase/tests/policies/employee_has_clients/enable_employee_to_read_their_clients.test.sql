BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('employee_with_clients');
SELECT tests.create_supabase_user('employee_without_clients');
SELECT tests.create_supabase_user('employee_without_permission');
SELECT tests.create_supabase_user('client1');
SELECT tests.create_supabase_user('client2');
SELECT tests.create_supabase_user('client3');

-- Create roles
SELECT public.map_role_and_permissions('role_with_permission', ARRAY['organization:read']);
SELECT public.map_role_and_permissions('role_without_permission', ARRAY['']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((SELECT tests.get_supabase_uid('employee_with_clients')), 'role_with_permission'),
    ((SELECT tests.get_supabase_uid('employee_without_clients')), 'role_with_permission'),
    ((SELECT tests.get_supabase_uid('employee_without_permission')), 'role_without_permission');

-- map clients and employees
SELECT public.map_client_and_employee((SELECT tests.get_supabase_uid('client1')), (SELECT tests.get_supabase_uid('employee_with_clients')));
SELECT public.map_client_and_employee((SELECT tests.get_supabase_uid('client2')), (SELECT tests.get_supabase_uid('employee_with_clients')));
SELECT public.map_client_and_employee((SELECT tests.get_supabase_uid('client3')), (SELECT tests.get_supabase_uid('employee_without_permission')));


SELECT plan(4);

-- 1: user has permission, information returned as expected
SELECT tests.authenticate_as('employee_with_clients');

SELECT results_eq(
               ('SELECT count(*) FROM employee_has_clients'),
               $$VALUES (2::bigint)$$,
               'confirm that employee can read their two clients'
       );

SELECT tests.clear_authentication();

-- 2: employee does not have any clients, no rows returned
SELECT tests.authenticate_as('employee_without_clients');

SELECT is_empty(
               $$ SELECT * FROM employee_has_clients $$,
               'confirm that no rows are returned for employee without clients');

SELECT tests.clear_authentication();

-- 3: employee does not have permission, no rows returned
SELECT tests.authenticate_as('employee_without_permission');

SELECT is_empty(
               $$ SELECT * FROM employee_has_clients $$,
               'confirm that no rows are returned for employee without permissions');

SELECT tests.clear_authentication();

-- 4: unauthenticated, no rows returned
SELECT is_empty(
               $$ SELECT * FROM employee_has_clients $$,
               'confirm that no rows are returned for unauthenticated user');

SELECT * from finish();
ROLLBACK;