BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- disable RLS on all tables
SELECT public.disable_all_rls_in_public_schema();

-- Insert roles and permissions
SELECT public.map_role_and_permissions('client', ARRAY['appointment:read', 'appointment:cancel', 'organization:read', 'invoices:read', 'site:navigation:invoices']);
SELECT public.map_role_and_permissions('employee', ARRAY['appointment:read', 'appointment:cancel', 'journal:read', 'journal:write', 'organization:read', 'site:navigation:clients']);
SELECT public.map_role_and_permissions('role_without_permissions', ARRAY['']);


SELECT plan(3);

SELECT is(
       get_permissions_in_role('client'),
       ARRAY['appointment:read', 'appointment:cancel', 'organization:read', 'invoices:read', 'site:navigation:invoices'],
       'Function returns the correct client permissions'
);

SELECT is(
       get_permissions_in_role('employee'),
       ARRAY['appointment:read', 'appointment:cancel', 'journal:read', 'journal:write', 'organization:read', 'site:navigation:clients'],
       'Function returns the correct employee permissions'
);

SELECT is(
       get_permissions_in_role('role_without_permissions'),
       ARRAY[''],
       'Function returns no permissions'
);

SELECT *
FROM finish();
ROLLBACK;