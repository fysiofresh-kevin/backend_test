BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('admin');
SELECT tests.create_supabase_user('user_without_permission');
SELECT tests.create_supabase_user('client');

-- Create roles
SELECT public.map_role_and_permissions('role_with_admin_permission', ARRAY['invoices:read', 'invoices:admin']);
SELECT public.map_role_and_permissions('role_without_write_permission', ARRAY['invoices:read']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_uid('admin')), 'role_with_admin_permission'),
    ((tests.get_supabase_uid('user_without_permission')), 'role_without_write_permission');

SELECT public.create_invoice_with_subscription(1, (tests.get_supabase_uid('client')), 'fake-sub-4');
SELECT public.create_invoice_with_subscription(2, (tests.get_supabase_uid('client')), 'fake-sub-5');
SELECT public.create_invoice_with_subscription(3, (tests.get_supabase_uid('client')), 'fake-sub-6');
SELECT public.create_invoice_with_subscription(4, (tests.get_supabase_uid('client')), 'fake-sub-7');

SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.invoices
    ENABLE ROW LEVEL SECURITY;

SELECT plan(6);

-- 1: admin has permission to update appointments, rows updated as expected
SELECT tests.authenticate_as('admin');

UPDATE invoices
SET subscription_id = 'fake-sub-5'
WHERE id = 1;

UPDATE invoices
SET "status" = 'booked'::invoice_status
WHERE id = 2;

SELECT results_eq(
               $$SELECT subscription_id FROM invoices WHERE id = 1$$,
               $$VALUES ('fake-sub-5')$$,
               'confirm that admin can update invoices'
       );

SELECT results_eq(
               $$SELECT "status" FROM invoices WHERE id = 2$$,
               $$VALUES ('booked'::invoice_status)$$,
               'confirm that admin can update invoice status'
       );

SELECT throws_ok(
    $$UPDATE invoices SET "status" = 'pending' WHERE id = 2;$$,
    '22P02',
    'invalid input value for enum invoice_status: "pending"',
    'Test for invalid enum value update should fail'
);

SELECT throws_ok(
    $$UPDATE invoices SET "status" = 'draft'::text WHERE id = 2;$$,
    '42804',
    'column "status" is of type invoice_status but expression is of type text',
    'Test for invalid status data type should fail'
);

SELECT tests.clear_authentication();

-- 2: user without permission does not have permission to update invoices, no rows updated as expected
SELECT tests.authenticate_as('user_without_permission');

UPDATE invoices
SET subscription_id = 'fake-sub-7'
WHERE id = 3;

-- authenticating as admin to see if the invoice was updated
SELECT tests.clear_authentication();
SELECT tests.authenticate_as('admin');

-- invoice should not have been updated
SELECT results_eq(
               $$SELECT subscription_id FROM invoices WHERE id = 3$$,
               $$VALUES ('fake-sub-6')$$,
               'confirm that user_without_permission cannot update invoices'
       );

SELECT tests.clear_authentication();

-- 3: anon user does not have permission to update invoices, no rows inserted as expected
UPDATE invoices
SET subscription_id = 'fake-sub-6'
WHERE id = 4;

-- authenticating as admin to see if the invoice was updated
SELECT tests.authenticate_as('admin');

-- invoice should not have been updated
SELECT results_eq(
               $$SELECT subscription_id FROM invoices WHERE id = 4$$,
               $$VALUES ('fake-sub-7')$$,
               'confirm that anon user cannot update invoices'
       );

SELECT tests.clear_authentication();

SELECT * from finish();
ROLLBACK;