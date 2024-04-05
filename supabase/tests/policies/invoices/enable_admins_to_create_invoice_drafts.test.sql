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
SELECT public.map_role_and_permissions('role_with_admin_permission', ARRAY['invoices:read', 'invoices:write', 'invoices:admin']);
SELECT public.map_role_and_permissions('role_without_write_permission', ARRAY['invoices:read']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_uid('admin')), 'role_with_admin_permission'),
    ((tests.get_supabase_uid('user_without_permission')), 'role_without_write_permission');

SELECT public.create_invoice_with_subscription(1, (tests.get_supabase_uid('client')), 'fake-sub-4');

SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.invoices
    ENABLE ROW LEVEL SECURITY;

SELECT plan(3);

-- 1: admin has permission to insert invoices, rows inserted as expected
SELECT tests.authenticate_as('admin');

INSERT INTO invoices
    (id, "from", "to", "status", subscription_id)
VALUES
    (2, NOW(), NOW(), 'draft', 'fake-sub-4'),
    (3, NOW(), NOW(), 'draft', 'fake-sub-4');

SELECT results_eq(
               ('SELECT count(*) FROM invoices'),
               $$VALUES (3::bigint)$$,
               'confirm that admin can insert rows into invoices'
       );

SELECT tests.clear_authentication();

-- 2: user_without_permission without permission does not have permission to insert their own invoices, no rows inserted as expected
SELECT tests.authenticate_as('user_without_permission');


PREPARE user_without_permission_rls_thrower AS
INSERT INTO invoices
    (id, "from", "to", "status", subscription_id)
VALUES
    (4, NOW(), NOW(), 'draft', 'fake-sub-4');
SELECT throws_ok(
    'user_without_permission_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "invoices"',
    'We should get a row-level security policy violation for insertion attempt'
);

SELECT tests.clear_authentication();


-- 3: anon user does not have permission to insert invoices, no rows inserted as expected
PREPARE anon_rls_thrower AS
INSERT INTO invoices
    (id, "from", "to", "status", subscription_id)
VALUES
    (4, NOW(), NOW(), 'draft', 'fake-sub-4');
SELECT throws_ok(
    'anon_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "invoices"',
    'We should get a row-level security policy violation for insertion attempt'
);

SELECT * from finish();
ROLLBACK;