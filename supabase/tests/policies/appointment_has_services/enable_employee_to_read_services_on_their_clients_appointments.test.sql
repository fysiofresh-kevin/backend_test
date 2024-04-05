BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

SELECT delete_all_data_in_schemas();

SELECT tests.create_supabase_user('client_with_appointments_1');
SELECT tests.create_supabase_user('client_with_appointments_2');

SELECT tests.create_supabase_user('employee_with_appointments_1');
SELECT tests.create_supabase_user('employee_with_appointments_2');
SELECT tests.create_supabase_user('employee_without_appointments');

SELECT map_role_and_permissions('appointment_read_role', ARRAY['appointment:read']);

SELECT assign_user_role('appointment_read_role',
                        (SELECT tests.get_supabase_uid('client_with_appointments_1')));

SELECT assign_user_role('appointment_read_role',
                        (SELECT tests.get_supabase_uid('client_with_appointments_2')));

SELECT assign_user_role('appointment_read_role',
                        (SELECT tests.get_supabase_uid('employee_with_appointments_1')));

SELECT assign_user_role('appointment_read_role',
                        (SELECT tests.get_supabase_uid('employee_with_appointments_2')));

SELECT assign_user_role('appointment_read_role',
                        (SELECT tests.get_supabase_uid('employee_without_appointments')));


SELECT map_appointment_and_services(1,
                                    (SELECT tests.get_supabase_uid('client_with_appointments_1')),
                                    (SELECT tests.get_supabase_uid('employee_with_appointments_1')),
                                    1);

SELECT map_appointment_and_services(2,
                                    (SELECT tests.get_supabase_uid('client_with_appointments_1')),
                                    (SELECT tests.get_supabase_uid('employee_with_appointments_2')),
                                    1);

SELECT map_appointment_and_services(3,
                                    (SELECT tests.get_supabase_uid('client_with_appointments_2')),
                                    (SELECT tests.get_supabase_uid('employee_with_appointments_2')),
                                    1);

SELECT map_client_and_employee((SELECT tests.get_supabase_uid('client_with_appointments_1')),
                              (SELECT tests.get_supabase_uid('employee_with_appointments_1')));


SELECT map_client_and_employee((SELECT tests.get_supabase_uid('client_with_appointments_1')),
                               (SELECT tests.get_supabase_uid('employee_with_appointments_2')));

SELECT map_client_and_employee((SELECT tests.get_supabase_uid('client_with_appointments_2')),
                               (SELECT tests.get_supabase_uid('employee_with_appointments_2')));


SELECT public.disable_all_rls_in_public_schema();


ALTER TABLE public.appointment_has_services
    ENABLE ROW LEVEL SECURITY;

SELECT plan(4);

SELECT tests.authenticate_as('employee_with_appointments_1');
SELECT results_eq(
       ('SELECT count(*) FROM appointment_has_services'),
       $$VALUES (2::bigint)$$,
       'Confirm that employee can read both of client_1s appointments and their mapped service'
);
SELECT tests.clear_authentication();

SELECT tests.authenticate_as('employee_with_appointments_2');
SELECT results_eq(
               ('SELECT count(*) FROM appointment_has_services'),
               $$VALUES (3::bigint)$$,
               'Confirm that employee can read both client_1 and -2s appointments and their mapped services'
       );
SELECT tests.clear_authentication();

SELECT tests.authenticate_as('employee_without_appointments');
SELECT is_empty(
               $$ SELECT * FROM appointment_has_services $$,
               'Employee with no appointments cannot see any appointments and their mapped services');
SELECT tests.clear_authentication();

SELECT is_empty(
               $$ SELECT * FROM appointment_has_services $$, 'Anon cannot see any appointments with mapped services');

-- Finish tests
SELECT *
FROM finish();
ROLLBACK;