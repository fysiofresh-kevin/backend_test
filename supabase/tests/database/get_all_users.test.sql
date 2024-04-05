BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- disable RLS on all tables
SELECT public.disable_all_rls_in_public_schema();

-- Insert roles
SELECT public.map_role_and_permissions('client', ARRAY['']);
SELECT public.map_role_and_permissions('employee', ARRAY['']);
SELECT public.map_role_and_permissions('admin', ARRAY['']);

-- Insert test data
SELECT public.seed_user('client1', 'client1@gmail.com', 'client', '4e8546b7-0f19-4f13-a9a4-154163c6b655');
SELECT public.seed_user('client2', 'client2@gmail.com', 'client', 'e147a6bb-5c9a-4d1c-9ad1-aa4aa2596447');
SELECT public.seed_user('client3', 'client3@gmail.com', 'client', 'df03260f-0aa9-4006-a7c0-b974222257d1');
SELECT public.seed_user('employee1', 'employee1@gmail.com', 'employee', '48cc7515-d22b-43d6-a0d1-4b4ef3a481b3');
SELECT public.seed_user('employee2', 'employee2@gmail.com', 'employee', '585b4abe-d4c5-491c-9a3b-515f3c281c38');


SELECT plan(3);

SELECT is(
       (SELECT count(*) FROM get_all_users('client')),
       3::bigint,
       'Confirm function returns the three clients'
);

SELECT is(
       (SELECT count(*) FROM get_all_users('employee')),
       2::bigint,
       'Confirm function returns the two employees'
);

SELECT is(
       (SELECT count(*) FROM get_all_users('admin')),
       0::bigint,
       'Confirm function returns no users'
);


-- Finish tests
SELECT *
FROM finish();
ROLLBACK;