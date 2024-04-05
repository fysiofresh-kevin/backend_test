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

SELECT create_appointment(10,
                          (SELECT tests.get_supabase_uid('client_with_appointment_1')),
                          (SELECT tests.get_supabase_uid('employee')),
                          'completed');

SELECT create_appointment(20,
                          (SELECT tests.get_supabase_uid('client_with_appointment_1')),
                          (SELECT tests.get_supabase_uid('employee')),
                          'completed');

SELECT create_appointment(30,
                          (SELECT tests.get_supabase_uid('client_with_appointment_2')),
                          (SELECT tests.get_supabase_uid('employee')),
                          'completed');

SELECT create_invoice_with_subscription(1,
                                        (SELECT tests.get_supabase_uid('client_with_appointment_1')),
                                        'test_sub_1');

SELECT create_invoice_with_subscription(2,
                                        (SELECT tests.get_supabase_uid('client_with_appointment_2')),
                                        'test_sub_2');

SELECT map_invoice_and_appointments(1, ARRAY[10,20]);
SELECT map_invoice_and_appointments(1, ARRAY[30]);

SELECT public.disable_all_rls_in_public_schema();


ALTER TABLE public.invoice_has_appointments
    ENABLE ROW LEVEL SECURITY;

SELECT plan(3);

SELECT tests.authenticate_as('user_with_admin_permission');
SELECT results_eq(
               ('SELECT count(*) FROM invoice_has_appointments'),
               $$VALUES (3::bigint)$$,
               'Confirm that admin can read their all 3 appointments and their mapped services'
       );
SELECT tests.clear_authentication();

SELECT tests.authenticate_as('user_without_admin_permission');
SELECT is_empty(
               $$ SELECT * FROM invoice_has_appointments $$,
               'User with no appointments or admin permission cannot see any appointments and their mapped services');
SELECT tests.clear_authentication();

SELECT is_empty(
               $$ SELECT * FROM invoice_has_appointments $$, 'Anon cannot see any appointments with mapped services');

-- Finish tests
SELECT *
FROM finish();
ROLLBACK;