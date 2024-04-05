BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

SELECT delete_all_data_in_schemas();

SELECT tests.create_supabase_user('client_with_appointments');
SELECT tests.create_supabase_user('client_without_appointments');
SELECT tests.create_supabase_user('employee');

SELECT map_role_and_permissions('client_with_appointments_role', ARRAY['appointment:read']);
SELECT map_role_and_permissions('client_without_appointments_role', ARRAY['appointment:read']);

SELECT assign_user_profile_and_role('Test client with appointments',
                                    'client_with_appointments_role',
                                    (SELECT tests.get_supabase_uid('client_with_appointments')));

SELECT assign_user_profile_and_role('Test client without appointments',
                                    'client_without_appointments_role',
                                    (SELECT tests.get_supabase_uid('client_without_appointments')));

SELECT create_appointment(10,
                          (SELECT tests.get_supabase_uid('client_with_appointments')),
                          (SELECT tests.get_supabase_uid('employee')),
                          'completed');

SELECT create_appointment(20,
                          (SELECT tests.get_supabase_uid('client_with_appointments')),
                          (SELECT tests.get_supabase_uid('employee')),
                          'completed');

SELECT create_invoice_with_subscription(1,
                                        (SELECT tests.get_supabase_uid('client_with_appointments')),
                                        'test_sub_1');

SELECT map_invoice_and_appointments(1, ARRAY[10,20]);


SELECT public.disable_all_rls_in_public_schema();


ALTER TABLE public.invoice_has_appointments
    ENABLE ROW LEVEL SECURITY;

SELECT plan(3);

SELECT tests.authenticate_as('client_with_appointments');
SELECT results_eq(
               ('SELECT count(*) FROM invoice_has_appointments'),
               $$VALUES (2::bigint)$$,
               'Confirm that client can read their 2 appointments and their mapped invoices'
       );
SELECT tests.clear_authentication();

SELECT tests.authenticate_as('client_without_appointments');
SELECT is_empty(
               $$ SELECT * FROM invoice_has_appointments $$,
               'Client with no appointments cannot see any appointments and their mapped invoices');
SELECT tests.clear_authentication();

SELECT is_empty(
               $$ SELECT * FROM invoice_has_appointments $$, 'Anon cannot see any appointments with mapped invoices');

-- Finish tests
SELECT *
FROM finish();
ROLLBACK;