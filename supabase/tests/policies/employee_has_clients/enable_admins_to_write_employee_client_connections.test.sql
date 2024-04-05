BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('admin');
SELECT tests.create_supabase_user('client1');
SELECT tests.create_supabase_user('client2');
SELECT tests.create_supabase_user('client3');
SELECT tests.create_supabase_user('client4');
SELECT tests.create_supabase_user('employee1');
SELECT tests.create_supabase_user('employee2');

-- Create roles
SELECT public.map_role_and_permissions('role_with_admin_permission', ARRAY['organization:read', 'organization:write', 'organization:admin']);
SELECT public.map_role_and_permissions('role_without_permission', ARRAY['organization:read']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_uid('admin')), 'role_with_admin_permission'),
    ((tests.get_supabase_uid('employee1')), 'role_without_permission');

INSERT INTO employee_has_clients
    (client_id, employee_id)
VALUES
   ((SELECT tests.get_supabase_uid('client1')), (SELECT tests.get_supabase_uid('employee1'))),
   ((SELECT tests.get_supabase_uid('client2')), (SELECT tests.get_supabase_uid('employee1'))),
   ((SELECT tests.get_supabase_uid('client3')), (SELECT tests.get_supabase_uid('employee1'))),
   ((SELECT tests.get_supabase_uid('client4')), (SELECT tests.get_supabase_uid('employee2')));

SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.employee_has_clients
    ENABLE ROW LEVEL SECURITY;

SELECT plan(4);

-- 1: admin has permission to update appointments, rows updated as expected
SELECT tests.authenticate_as('admin');

UPDATE employee_has_clients
SET employee_id = (SELECT tests.get_supabase_uid('employee2'))
WHERE employee_id = (SELECT tests.get_supabase_uid('employee1'))
AND client_id = (SELECT tests.get_supabase_uid('client1'));

UPDATE employee_has_clients
SET employee_id = (SELECT tests.get_supabase_uid('employee2'))
WHERE employee_id = (SELECT tests.get_supabase_uid('employee1'))
AND client_id = (SELECT tests.get_supabase_uid('client2'));

SELECT results_eq(
               $$SELECT employee_id FROM employee_has_clients WHERE client_id = (SELECT tests.get_supabase_uid('client1'))$$,
               $$VALUES ((SELECT tests.get_supabase_uid('employee2')))$$,
               'confirm that admin can insert rows into employee_has_clients'
       );
SELECT results_eq(
               $$SELECT employee_id FROM employee_has_clients WHERE client_id = (SELECT tests.get_supabase_uid('client2'))$$,
               $$VALUES ((SELECT tests.get_supabase_uid('employee2')))$$,
               'confirm that admin can insert rows into employee_has_clients'
       );

SELECT tests.clear_authentication();

-- 2: user without permission does not have permission to update employee_has_clients, no rows updated as expected
SELECT tests.authenticate_as('employee1');

UPDATE employee_has_clients
SET client_id = (SELECT tests.get_supabase_uid('client1'))
WHERE employee_id = (SELECT tests.get_supabase_uid('employee1'))
AND client_id = (SELECT tests.get_supabase_uid('client3'));

-- client should not have been updated -> still client3
SELECT results_eq(
               'SELECT client_id FROM employee_has_clients WHERE employee_id = (SELECT tests.get_supabase_uid(''employee1''))',
               $$VALUES ((SELECT tests.get_supabase_uid('client3')))$$,
               'confirm that user without write permission cannot update rows in employee_has_clients'
       );

SELECT tests.clear_authentication();

-- 3: anon user does not have permission to update employee_has_clients, no rows inserted as expected
UPDATE employee_has_clients
SET employee_id = (SELECT tests.get_supabase_uid('employee1'))
WHERE employee_id = (SELECT tests.get_supabase_uid('employee2'))
AND client_id = (SELECT tests.get_supabase_uid('client4'));

SELECT is_empty(
               $$ SELECT * FROM employee_has_clients $$,
               'confirm that no rows are returned for unauthenticated user');

SELECT * from finish();
ROLLBACK;