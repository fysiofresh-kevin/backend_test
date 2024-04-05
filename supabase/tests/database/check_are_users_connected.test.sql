BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- disable RLS on all tables
SELECT public.disable_all_rls_in_public_schema();

-- Insert test data
SELECT tests.create_supabase_user('client1');
SELECT tests.create_supabase_user('client2');
SELECT tests.create_supabase_user('employee1');
SELECT tests.create_supabase_user('employee2');

-- map client1 and employee1
SELECT public.map_client_and_employee((SELECT tests.get_supabase_uid('client1')), (SELECT tests.get_supabase_uid('employee1')));


SELECT plan(4);

SELECT is(
       check_are_users_connected((SELECT tests.get_supabase_uid('client1')), (SELECT tests.get_supabase_uid('employee1')))::boolean,
       TRUE,
       'Confirm that users are connected'
);

SELECT is(
       check_are_users_connected((SELECT tests.get_supabase_uid('client1')), (SELECT tests.get_supabase_uid('employee2')))::boolean,
       FALSE,
       'Confirm that users are not connected'
);

SELECT is(
       check_are_users_connected((SELECT tests.get_supabase_uid('client2')), (SELECT tests.get_supabase_uid('employee1')))::boolean,
       FALSE,
       'Confirm that users are not connected'
);

SELECT is(
       check_are_users_connected((SELECT tests.get_supabase_uid('client2')), (SELECT tests.get_supabase_uid('employee2')))::boolean,
       FALSE,
       'Confirm that users are not connected'
);

-- Finish tests
SELECT *
FROM finish();
ROLLBACK;