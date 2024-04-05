BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- disable RLS on all tables
SELECT public.disable_all_rls_in_public_schema();

-- Create test users
SELECT tests.create_supabase_user('client');
SELECT tests.create_supabase_user('employee');
SELECT tests.create_supabase_user('user_without_permissions');

-- Insert roles
SELECT public.map_role_and_permissions('client', ARRAY['appointment:read', 'appointment:cancel', 'organization:read', 'invoices:read', 'site:navigation:invoices']);
SELECT public.map_role_and_permissions('employee', ARRAY['appointment:read', 'appointment:cancel', 'journal:read', 'journal:write', 'organization:read', 'site:navigation:clients']);
SELECT public.map_role_and_permissions('role_without_permissions', ARRAY['']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_uid('client')), 'client'),
    ((tests.get_supabase_uid('employee')), 'employee'),
    ((tests.get_supabase_uid('user_without_permissions')), 'role_without_permissions');


SELECT plan(3);

SELECT is(
       get_user_permissions((SELECT tests.get_supabase_uid('client'))),
       ARRAY['appointment:read', 'appointment:cancel', 'organization:read', 'invoices:read', 'site:navigation:invoices'],
       'Function returns the correct client permissions'
);

SELECT is(
       get_user_permissions((SELECT tests.get_supabase_uid('employee'))),
       ARRAY['appointment:read', 'appointment:cancel', 'journal:read', 'journal:write', 'organization:read', 'site:navigation:clients'],
       'Function returns the correct employee permissions'
);

SELECT is(
       get_user_permissions((SELECT tests.get_supabase_uid('user_without_permissions'))),
       ARRAY[''],
       'Function returns no permissions'
);

SELECT *
FROM finish();
ROLLBACK;