BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- disable RLS on all tables
SELECT public.disable_all_rls_in_public_schema();

-- Insert test data
SELECT tests.create_supabase_user('admin');
SELECT tests.create_supabase_user('client');
SELECT tests.create_supabase_user('employee');
SELECT tests.create_supabase_user('user_without_permissions');
SELECT tests.create_supabase_user('user_without_role');

-- Insert roles and permissions
SELECT public.map_role_and_permissions('admin_role',
    ARRAY['appointment:read', 'appointment:write', 'appointment:delete', 'appointment:cancel', 'appointment:admin',
    'invoices:read', 'invoices:write', 'invoices:admin', 'journal:read', 'journal:write', 'journal:admin',
    'organization:read', 'organization:write', 'organization:admin',
    'site:navigation:clients', 'site:navigation:employees', 'site:navigation:services', 'site:navigation:invoices']);

SELECT public.map_role_and_permissions('client_role',
    ARRAY['appointment:read', 'appointment:cancel', 'organization:read',
    'invoices:read', 'site:navigation:invoices']);

SELECT public.map_role_and_permissions('employee_role',
    ARRAY['appointment:read', 'appointment:cancel', 'journal:read',
    'journal:write', 'organization:read', 'site:navigation:clients']);

SELECT public.map_role_and_permissions('role_without_permissions',
    ARRAY['']);

INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((SELECT tests.get_supabase_uid('admin')), 'admin_role'),
    ((SELECT tests.get_supabase_uid('client')), 'client_role'),
    ((SELECT tests.get_supabase_uid('employee')), 'employee_role'),
    ((SELECT tests.get_supabase_uid('user_without_permissions')), 'role_without_permissions');


SELECT plan(7);

-- Test case 1: Admin role has admin permissions
SELECT is(
    check_user_has_permission((SELECT tests.get_supabase_uid('admin')), ARRAY['appointment:admin', 'invoices:admin', 'journal:admin', 'organization:admin'])::boolean,
    TRUE,
    'Admin role has admin permissions'
);

-- Test case 2: Client has read appointment permission
SELECT is(
    check_user_has_permission((SELECT tests.get_supabase_uid('client')), ARRAY['appointment:read'])::boolean,
    TRUE,
    'Client has read appointment permission'
);

-- Test case 3: Client does not have journal write permission
SELECT is(
    check_user_has_permission((SELECT tests.get_supabase_uid('client')), ARRAY['journal:write'])::boolean,
    FALSE,
    'Client does not have journal write permission'
);

-- Test case 4: Employee has journal write permission
SELECT is(
    check_user_has_permission((SELECT tests.get_supabase_uid('employee')), ARRAY['journal:write'])::boolean,
    TRUE,
    'Employee has journal write permission'
);

-- Test case 5: Employee does not have invoices write permission
SELECT is(
    check_user_has_permission((SELECT tests.get_supabase_uid('employee')), ARRAY['invoices:write'])::boolean,
    FALSE,
    'Employee has invoices write permission'
);

-- Test case 6: User with no permissions does not have permission
SELECT is(
    check_user_has_permission((SELECT tests.get_supabase_uid('user_without_permissions')), ARRAY['organization:read'])::boolean,
    FALSE,
    'User with no permissions does not have permission'
);

-- Test case 7: User with no role does not have permission
SELECT is(
    check_user_has_permission((SELECT tests.get_supabase_uid('user_without_role')), ARRAY['organization:read'])::boolean,
    FALSE,
    'User with no role does not have permission'
);

-- Finish tests
SELECT finish();
ROLLBACK;