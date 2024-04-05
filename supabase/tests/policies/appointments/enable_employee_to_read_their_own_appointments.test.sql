BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('employee_with_appointments');
SELECT tests.create_supabase_user('employee_without_appointments');
SELECT tests.create_supabase_user('employee_without_permission');
SELECT tests.create_supabase_user('client');

-- Create roles
SELECT public.map_role_and_permissions('role_with_appointment_read_permission', ARRAY['appointment:read']);
SELECT public.map_role_and_permissions('role_without_permission', ARRAY['']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_user('employee_with_appointments') ->> 'id')::uuid, 'role_with_appointment_read_permission'),
    ((tests.get_supabase_user('employee_without_appointments') ->> 'id')::uuid, 'role_with_appointment_read_permission'),
    ((tests.get_supabase_user('employee_without_permission') ->> 'id')::uuid, 'role_without_permission');


SELECT public.create_appointment(1, (SELECT tests.get_supabase_uid('client')), (SELECT tests.get_supabase_uid('employee_with_appointments')), 'completed');
SELECT public.create_appointment(2, (SELECT tests.get_supabase_uid('client')), (SELECT tests.get_supabase_uid('employee_with_appointments')), 'completed');
SELECT public.create_appointment(3, (SELECT tests.get_supabase_uid('client')), (SELECT tests.get_supabase_uid('employee_without_permission')), 'completed');
SELECT public.create_appointment(4, (SELECT tests.get_supabase_uid('client')), (SELECT tests.get_supabase_uid('employee_without_permission')), 'completed');

SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.appointments
    ENABLE ROW LEVEL SECURITY;

SELECT plan(4);

-- 1: user has permission, information returned as expected
SELECT tests.authenticate_as('employee_with_appointments');

SELECT results_eq(
               ('SELECT count(*) FROM appointments'),
               $$VALUES (2::bigint)$$,
               'confirm that employee can read their two appointments'
       );

SELECT tests.clear_authentication();

-- 2: user does not have appointments, no information available
SELECT tests.authenticate_as('employee_without_appointments');

SELECT is_empty(
               $$ SELECT * FROM appointments $$,
               'confirm that no rows are returned for user without permissions');

SELECT tests.clear_authentication();

-- 3: user does not have permission, information access denied
SELECT tests.authenticate_as('employee_without_permission');

SELECT is_empty(
               $$ SELECT * FROM appointments $$,
               'confirm that no rows are returned for user without permissions');

SELECT tests.clear_authentication();

-- 4: unauthenticated, information access denied
SELECT is_empty(
               $$ SELECT * FROM appointments $$,
               'confirm that no rows are returned for unauthenticated user');

SELECT * from finish();
ROLLBACK;