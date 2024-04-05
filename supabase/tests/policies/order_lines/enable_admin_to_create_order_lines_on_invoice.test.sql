BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

SELECT delete_all_data_in_schemas();

SELECT tests.create_supabase_user('user_with_admin_permission');
SELECT tests.create_supabase_user('user_without_admin_permission');
SELECT tests.create_supabase_user('client_with_appointment_1');
SELECT tests.create_supabase_user('client_with_appointment_2');
SELECT tests.create_supabase_user('employee');

SELECT map_role_and_permissions('role_with_admin_permissions', ARRAY['organization:admin', 'invoices:write']);
SELECT map_role_and_permissions('role_without_admin_permissions', ARRAY['']);

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


SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.order_lines
    ENABLE ROW LEVEL SECURITY;


SELECT plan(3);

-- 1: admin has permission to insert order_lines, rows inserted as expected
SELECT tests.authenticate_as('user_with_admin_permission');

INSERT INTO "public"."order_lines"
    (appointment_id, invoice_id, "service", price, discount)
VALUES
    (1, 1, 'Home Treatment', 490, 10),
    (2, 2, 'Video Treatment', 290, 10),
    (3, 3, 'Phone Treatment', 120, 10),
    (1, 1, 'Extra 15 minutes', 120, 10);

SELECT results_eq(
               ('SELECT count(*) FROM order_lines'),
               $$VALUES (4::bigint)$$,
               'confirm that admin can insert rows into order_lines'
       );

SELECT tests.clear_authentication();

-- 2: user without permission does not have permission to insert order_lines, no rows inserted as expected
SELECT tests.authenticate_as('user_without_admin_permission');

PREPARE user_without_permission_rls_thrower AS
INSERT INTO "public"."order_lines"
    (appointment_id, invoice_id, "service", price, discount)
VALUES
    (2, 2, 'Phone Treatment', 120, 10);
SELECT throws_ok(
    'user_without_permission_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "order_lines"',
    'We should get a row-level security policy violation for insertion attempt'
);

SELECT tests.clear_authentication();

-- 3: anon user does not have permission to insert order_lines, no rows inserted as expected
PREPARE anon_rls_thrower AS
INSERT INTO "public"."order_lines"
    (appointment_id, invoice_id, "service", price, discount)
VALUES
    (3, 3, 'Home Treatment', 490, 10);
SELECT throws_ok(
    'anon_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "order_lines"',
    'We should get a row-level security policy violation for insertion attempt'
);

-- Finish tests
SELECT *
FROM finish();
ROLLBACK;