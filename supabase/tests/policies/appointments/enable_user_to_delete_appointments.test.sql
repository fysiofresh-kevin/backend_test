BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('admin');
SELECT tests.create_supabase_user('employee');
SELECT tests.create_supabase_user('client');

-- Create roles
SELECT public.map_role_and_permissions('role_with_appointment_admin_permission', ARRAY['appointment:admin', 'appointment:read', 'appointment:delete']);
SELECT public.map_role_and_permissions('role_without_delete_permission', ARRAY['appointment:read']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_user('admin') ->> 'id')::uuid, 'role_with_appointment_admin_permission'),
    ((tests.get_supabase_user('employee') ->> 'id')::uuid, 'role_without_delete_permission'),
    ((tests.get_supabase_user('client') ->> 'id')::uuid, 'role_without_delete_permission');

SELECT public.create_appointment(1, (SELECT tests.get_supabase_uid('client')), (SELECT tests.get_supabase_uid('employee')), 'completed');
SELECT public.create_appointment(2, (SELECT tests.get_supabase_uid('client')), (SELECT tests.get_supabase_uid('employee')), 'completed');
SELECT public.create_appointment(3, (SELECT tests.get_supabase_uid('client')), (SELECT tests.get_supabase_uid('employee')), 'completed');
SELECT public.create_appointment(4, (SELECT tests.get_supabase_uid('client')), (SELECT tests.get_supabase_uid('employee')), 'completed');
SELECT public.create_appointment(5, (SELECT tests.get_supabase_uid('client')), (SELECT tests.get_supabase_uid('employee')), 'completed');


SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.appointments
    ENABLE ROW LEVEL SECURITY;

SELECT plan(4);

-- 1: admin has permission to insert appointments, rows deleted as expected
SELECT tests.authenticate_as('admin');

DELETE FROM appointments WHERE id = 4;
DELETE FROM appointments WHERE id = 5;

SELECT results_eq(
               ('SELECT count(*) FROM appointments'),
               $$VALUES (3::bigint)$$,
               'confirm that admin can delete appointments'
       );

SELECT tests.clear_authentication();

-- 2: client without permission cannot delete appointments, no rows deleted as expected
SELECT tests.authenticate_as('client');

DELETE FROM appointments WHERE id = 3;

SELECT tests.clear_authentication();
SELECT tests.authenticate_as('admin');

SELECT results_eq(
               ('SELECT count(*) FROM appointments'),
               $$VALUES (3::bigint)$$,
               'confirm that client without permission cannot delete appointments'
       );

SELECT tests.clear_authentication();

-- 3: employee without permission cannot delete appointments, no rows deleted as expected
SELECT tests.authenticate_as('employee');

DELETE FROM appointments WHERE id = 3;

SELECT results_eq(
               ('SELECT count(*) FROM appointments'),
               $$VALUES (3::bigint)$$,
               'confirm that employee without permission cannot delete appointments'
       );

SELECT tests.clear_authentication();

-- 4: anon user does not have permission to delete appointments, no rows deleted as expected

DELETE FROM appointments WHERE id = 3;

-- authenticating as admin to see all invoices
SELECT tests.authenticate_as('admin');

SELECT results_eq(
               ('SELECT count(*) FROM appointments'),
               $$VALUES (3::bigint)$$,
               'confirm that anon user cannot delete appointments'
       );

SELECT tests.clear_authentication();

SELECT * from finish();
ROLLBACK;