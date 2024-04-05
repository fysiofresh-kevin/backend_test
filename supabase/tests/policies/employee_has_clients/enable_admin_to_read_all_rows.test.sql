-- ARRANGE

BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('admin');
SELECT tests.create_supabase_user('user_without_permission');
SELECT tests.create_supabase_user('client1');
SELECT tests.create_supabase_user('client2');
SELECT tests.create_supabase_user('client3');
SELECT tests.create_supabase_user('client4');
SELECT tests.create_supabase_user('employee1');
SELECT tests.create_supabase_user('employee2');


-- Create roles
SELECT public.map_role_and_permissions('role_with_permission', ARRAY['organization:read', 'organization:admin']);
SELECT public.map_role_and_permissions('role_without_permission', ARRAY['']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_uid('admin')), 'role_with_permission'),
    ((tests.get_supabase_uid('user_without_permission')), 'role_without_permission');

-- mapping clients and employees
SELECT public.map_client_and_employee((SELECT tests.get_supabase_uid('client1')), (SELECT tests.get_supabase_uid('employee1')));
SELECT public.map_client_and_employee((SELECT tests.get_supabase_uid('client2')), (SELECT tests.get_supabase_uid('employee1')));
SELECT public.map_client_and_employee((SELECT tests.get_supabase_uid('client3')), (SELECT tests.get_supabase_uid('employee1')));
SELECT public.map_client_and_employee((SELECT tests.get_supabase_uid('client3')), (SELECT tests.get_supabase_uid('employee2')));
SELECT public.map_client_and_employee((SELECT tests.get_supabase_uid('client4')), (SELECT tests.get_supabase_uid('employee2')));

SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.employee_has_clients
    ENABLE ROW LEVEL SECURITY;

SELECT plan(3);

-- 1: user has permission, information returned as expected
SELECT tests.authenticate_as('admin');

SELECT results_eq(
               ('SELECT count(*) FROM employee_has_clients'),
               $$VALUES (5::bigint)$$,
               'confirm that user with permission can read all employee_has_clients rows'
       );

SELECT tests.clear_authentication();

-- 2: user does not have permission to access all employee_has_clients rows
SELECT tests.authenticate_as('user_without_permission');

SELECT is_empty(
               $$ SELECT * FROM employee_has_clients $$,
               'confirm that no rows are returned for user without permission');

SELECT tests.clear_authentication();

-- 3: unauthenticated, information access denied
SELECT is_empty(
               $$ SELECT * FROM employee_has_clients $$,
               'confirm that no rows are returned for unauthenticated user');

SELECT * from finish();
ROLLBACK;