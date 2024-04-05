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
SELECT tests.create_supabase_user('employee');

-- Create roles
SELECT public.map_role_and_permissions('role_with_admin_permission', ARRAY['organization:read', 'organization:write', 'organization:admin']);
SELECT public.map_role_and_permissions('role_without_write_permission', ARRAY['organization:read']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_uid('admin')), 'role_with_admin_permission'),
    ((tests.get_supabase_uid('user_without_permission')), 'role_without_write_permission');


SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.employee_has_clients
    ENABLE ROW LEVEL SECURITY;

SELECT plan(3);

-- 1: admin has permission to insert appointments, rows inserted as expected
SELECT tests.authenticate_as('admin');

INSERT INTO employee_has_clients
    (client_id, employee_id)
VALUES
   ((SELECT tests.get_supabase_uid('client1')), (SELECT tests.get_supabase_uid('employee'))),
   ((SELECT tests.get_supabase_uid('client2')), (SELECT tests.get_supabase_uid('employee')));

SELECT results_eq(
               ('SELECT count(*) FROM employee_has_clients'),
               $$VALUES (2::bigint)$$,
               'confirm that admin can insert rows into employee_has_clients'
       );

SELECT tests.clear_authentication();

-- 2: user without permission does not have permission to insert employee_has_clients, no rows inserted as expected
SELECT tests.authenticate_as('user_without_permission');


PREPARE user_without_permission_rls_thrower AS INSERT INTO employee_has_clients(client_id, employee_id)
   VALUES((SELECT tests.get_supabase_uid('client3')), (SELECT tests.get_supabase_uid('employee')));
SELECT throws_ok(
    'user_without_permission_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "employee_has_clients"',
    'We should get a row-level security policy violation for insertion attempt'
);

SELECT tests.clear_authentication();


-- 3: anon user does not have permission to insert employee_has_clients, no rows inserted as expected
PREPARE anon_rls_thrower AS INSERT INTO employee_has_clients(client_id, employee_id)
   VALUES((SELECT tests.get_supabase_uid('client4')), (SELECT tests.get_supabase_uid('employee')));
SELECT throws_ok(
    'anon_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "employee_has_clients"',
    'We should get a row-level security policy violation for insertion attempt'
);

SELECT * from finish();
ROLLBACK;