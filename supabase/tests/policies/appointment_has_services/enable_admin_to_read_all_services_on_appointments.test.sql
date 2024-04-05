BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

SELECT delete_all_data_in_schemas();

SELECT tests.create_supabase_user('user_with_admin_permission');
SELECT tests.create_supabase_user('user_without_admin_permission');
SELECT tests.create_supabase_user('client_with_appointment_1');
SELECT tests.create_supabase_user('client_with_appointment_2');
SELECT tests.create_supabase_user('employee');

SELECT map_role_and_permissions('role_with_admin_permissions', ARRAY['organization:admin']);
SELECT map_role_and_permissions('role_without_admin_permissions', ARRAY['appointment:read']);

SELECT assign_user_profile_and_role('Test user with admin permission',
                                    'role_with_admin_permissions',
                                    (SELECT tests.get_supabase_uid('user_with_admin_permission')));

SELECT assign_user_profile_and_role('Test user without appointments',
                                    'role_without_admin_permissions',
                                    (SELECT tests.get_supabase_uid('user_without_admin_permission')));

SELECT map_appointment_and_services(1,
                                    (SELECT tests.get_supabase_uid('client_with_appointment_1')),
                                    (SELECT tests.get_supabase_uid('employee')),
                                    1);

SELECT map_appointment_and_services(2,
                                    (SELECT tests.get_supabase_uid('client_with_appointment_1')),
                                    (SELECT tests.get_supabase_uid('employee')),
                                    1);

SELECT map_appointment_and_services(3,
                                    (SELECT tests.get_supabase_uid('client_with_appointment_2')),
                                    (SELECT tests.get_supabase_uid('employee')),
                                    1);


SELECT public.disable_all_rls_in_public_schema();


ALTER TABLE public.appointment_has_services
    ENABLE ROW LEVEL SECURITY;

SELECT plan(3);

SELECT tests.authenticate_as('user_with_admin_permission');
SELECT results_eq(
               ('SELECT count(*) FROM appointment_has_services'),
               $$VALUES (3::bigint)$$,
               'Confirm that admin can read all 3 appointments and their mapped services'
       );
SELECT tests.clear_authentication();

SELECT tests.authenticate_as('user_without_admin_permission');
SELECT is_empty(
               $$ SELECT * FROM appointment_has_services $$,
               'User with no appointments or admin permission cannot see any appointments and their mapped services');
SELECT tests.clear_authentication();

SELECT is_empty(
               $$ SELECT * FROM appointment_has_services $$, 'Anon cannot see any appointments with mapped services');

-- Finish tests
SELECT *
FROM finish();
ROLLBACK;