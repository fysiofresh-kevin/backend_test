BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('admin');
SELECT tests.create_supabase_user('employee_with_permission');
SELECT tests.create_supabase_user('employee_without_permission');
SELECT tests.create_supabase_user('client');

-- Create roles
SELECT public.map_role_and_permissions('role_with_appointment_admin_permission', ARRAY['appointment:read', 'appointment:write', 'appointment:admin']);
SELECT public.map_role_and_permissions('role_with_appointment_write_permission', ARRAY['appointment:read', 'appointment:write']);
SELECT public.map_role_and_permissions('role_without_permission', ARRAY['appointment:read']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_user('admin') ->> 'id')::uuid, 'role_with_appointment_admin_permission'),
    ((tests.get_supabase_user('employee_with_permission') ->> 'id')::uuid, 'role_with_appointment_write_permission'),
    ((tests.get_supabase_user('employee_without_permission') ->> 'id')::uuid, 'role_without_permission');


SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.appointments
    ENABLE ROW LEVEL SECURITY;

SELECT plan(4);

-- 1: admin has permission to insert appointments, rows inserted as expected
SELECT tests.authenticate_as('admin');

SELECT public.create_appointment(1, (SELECT tests.get_supabase_uid('client')), (SELECT tests.get_supabase_uid('employee_without_permission')), 'completed');
SELECT public.create_appointment(2, (SELECT tests.get_supabase_uid('client')), (SELECT tests.get_supabase_uid('employee_without_permission')), 'completed');

SELECT results_eq(
               ('SELECT count(*) FROM appointments'),
               $$VALUES (2::bigint)$$,
               'confirm that admin can read all appointments'
       );

SELECT tests.clear_authentication();

-- 2: employee has permission to insert their own appointments, rows inserted as expected
SELECT tests.authenticate_as('employee_with_permission');

SELECT public.create_appointment(3, (SELECT tests.get_supabase_uid('client')), (SELECT tests.get_supabase_uid('employee_with_permission')), 'completed');
SELECT public.create_appointment(4, (SELECT tests.get_supabase_uid('client')), (SELECT tests.get_supabase_uid('employee_with_permission')), 'completed');
SELECT public.create_appointment(5, (SELECT tests.get_supabase_uid('client')), (SELECT tests.get_supabase_uid('employee_with_permission')), 'completed');

SELECT results_eq(
               ('SELECT count(*) FROM appointments'),
               $$VALUES (3::bigint)$$,
               'confirm that employee can read their three appointments'
       );

SELECT tests.clear_authentication();

-- 3: employee without permission does not have permission to insert their own appointments, no rows inserted as expected
SELECT tests.authenticate_as('employee_without_permission');


PREPARE employee_rls_thrower AS INSERT INTO appointments(id, client_id, employee_id, "status")
   VALUES(7, (SELECT tests.get_supabase_uid('client')),
             (SELECT tests.get_supabase_uid('employee_without_permission')), 'completed');
SELECT throws_ok(
    'employee_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "appointments"',
    'We should get a row-level security policy violation for insertion attempt'
);

SELECT tests.clear_authentication();


-- 4: anon user does not have permission to insert their own appointments, no rows inserted as expected
PREPARE anon_rls_thrower AS INSERT INTO appointments(id, client_id, employee_id, "status")
   VALUES(7, (SELECT tests.get_supabase_uid('client')),
             (SELECT tests.get_supabase_uid('employee_without_permission')), 'completed');
SELECT throws_ok(
    'anon_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "appointments"',
    'We should get a row-level security policy violation for insertion attempt'
);

SELECT * from finish();
ROLLBACK;