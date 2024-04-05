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
SELECT map_role_and_permissions('role_without_admin_permissions', ARRAY['invoices:read']);

SELECT assign_user_profile_and_role('Test user with admin permission',
                                    'role_with_admin_permissions',
                                    (SELECT tests.get_supabase_uid('user_with_admin_permission')));

SELECT assign_user_profile_and_role('Test user without order lines',
                                    'role_without_admin_permissions',
                                    (SELECT tests.get_supabase_uid('user_without_admin_permission')));


SELECT create_invoice_with_subscription(1,
                                        (SELECT tests.get_supabase_uid('client_with_appointment_1')),
                                        'test_sub_1');

SELECT create_invoice_with_subscription(2,
                                        (SELECT tests.get_supabase_uid('client_with_appointment_2')),
                                        'test_sub_2');

SELECT create_invoice_with_subscription(3,
                                        (SELECT tests.get_supabase_uid('client_with_appointment_2')),
                                        'test_sub_3');


SELECT map_appointment_and_services(1, (SELECT tests.get_supabase_uid('client_with_appointment_1')), (SELECT tests.get_supabase_uid('employee')), 1);
SELECT map_appointment_and_services(2, (SELECT tests.get_supabase_uid('client_with_appointment_2')), (SELECT tests.get_supabase_uid('employee')), 2);
SELECT map_appointment_and_services(3, (SELECT tests.get_supabase_uid('client_with_appointment_2')), (SELECT tests.get_supabase_uid('employee')), 3);


INSERT INTO "public"."order_lines"
    (appointment_id, invoice_id, "service", price, discount)
VALUES
    (1, 1, 'Home Treatment', 490, 10),
    (2, 2, 'Video Treatment', 290, 10),
    (3, 3, 'Phone Treatment', 120, 10),
    (1, 1, 'Extra 15 minutes', 120, 10);

SELECT public.disable_all_rls_in_public_schema();


ALTER TABLE public.order_lines
    ENABLE ROW LEVEL SECURITY;

SELECT plan(3);

SELECT tests.authenticate_as('user_with_admin_permission');
SELECT results_eq(
               ('SELECT count(*) FROM order_lines'),
               $$VALUES (4::bigint)$$,
               'Confirm that admin can read their all 4 order lines and their mapped services'
       );
SELECT tests.clear_authentication();

SELECT tests.authenticate_as('user_without_admin_permission');
SELECT is_empty(
               $$ SELECT * FROM order_lines $$,
               'User with no order lines or admin permission cannot see any order lines and their mapped services');
SELECT tests.clear_authentication();

SELECT is_empty(
               $$ SELECT * FROM order_lines $$, 'Anon cannot see any order lines with mapped services');

-- Finish tests
SELECT *
FROM finish();
ROLLBACK;