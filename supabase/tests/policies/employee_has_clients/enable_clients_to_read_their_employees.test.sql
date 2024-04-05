BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('client_with_employees');
SELECT tests.create_supabase_user('client_without_employees');
SELECT tests.create_supabase_user('client_without_permission');
SELECT tests.create_supabase_user('employee1');
SELECT tests.create_supabase_user('employee2');
SELECT tests.create_supabase_user('employee3');
SELECT tests.create_supabase_user('employee4');

-- Create roles
SELECT public.map_role_and_permissions('role_with_permission', ARRAY['organization:read']);
SELECT public.map_role_and_permissions('role_without_permission', ARRAY['']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((SELECT tests.get_supabase_uid('client_with_employees')), 'role_with_permission'),
    ((SELECT tests.get_supabase_uid('client_without_employees')), 'role_with_permission'),
    ((SELECT tests.get_supabase_uid('client_without_permission')), 'role_without_permission');

-- map clients and employees
SELECT public.map_client_and_employee((SELECT tests.get_supabase_uid('client_with_employees')), (SELECT tests.get_supabase_uid('employee1')));
SELECT public.map_client_and_employee((SELECT tests.get_supabase_uid('client_with_employees')), (SELECT tests.get_supabase_uid('employee2')));
SELECT public.map_client_and_employee((SELECT tests.get_supabase_uid('client_with_employees')), (SELECT tests.get_supabase_uid('employee3')));
SELECT public.map_client_and_employee((SELECT tests.get_supabase_uid('client_without_permission')), (SELECT tests.get_supabase_uid('employee4')));


SELECT plan(4);

-- 1: user has permission, information returned as expected
SELECT tests.authenticate_as('client_with_employees');

SELECT results_eq(
               ('SELECT count(*) FROM employee_has_clients'),
               $$VALUES (3::bigint)$$,
               'confirm that client can read their two employees'
       );

SELECT tests.clear_authentication();

-- 2: client does not have any employees, no rows returned
SELECT tests.authenticate_as('client_without_employees');

SELECT is_empty(
               $$ SELECT * FROM employee_has_clients $$,
               'confirm that no rows are returned for client without employees');

SELECT tests.clear_authentication();

-- 3: client does not have permission, no rows returned
SELECT tests.authenticate_as('client_without_permission');

SELECT is_empty(
               $$ SELECT * FROM employee_has_clients $$,
               'confirm that no rows are returned for client without permissions');

SELECT tests.clear_authentication();

-- 4: unauthenticated, no rows returned
SELECT is_empty(
               $$ SELECT * FROM employee_has_clients $$,
               'confirm that no rows are returned for unauthenticated user');

SELECT * from finish();
ROLLBACK;