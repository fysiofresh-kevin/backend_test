BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('client_without_role');
SELECT tests.create_supabase_user('client_with_role_1');
SELECT tests.create_supabase_user('client_with_role_2');

SELECT tests.create_supabase_user('employee_without_role');
SELECT tests.create_supabase_user('employee_with_role_1');
SELECT tests.create_supabase_user('employee_with_role_2');

-- Create roles
SELECT public.map_role_and_permissions('role_with_role', ARRAY['organization:read']);
SELECT public.map_role_and_permissions('role_without_role', ARRAY['']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_uid('client_with_role_1')), 'role_with_role'),
    ((tests.get_supabase_uid('client_with_role_2')), 'role_with_role'),
    ((tests.get_supabase_uid('employee_with_role_1')), 'role_with_role'),
    ((tests.get_supabase_uid('employee_with_role_2')), 'role_with_role');
;

-- connect clients with employees
SELECT map_client_and_employee(
               (tests.get_supabase_uid('client_without_role')),
                (tests.get_supabase_uid('employee_without_role')));

SELECT map_client_and_employee(
               (tests.get_supabase_uid('client_with_role_1')),
               (tests.get_supabase_uid('employee_with_role_1')));

SELECT map_client_and_employee(
               (tests.get_supabase_uid('client_with_role_1')),
               (tests.get_supabase_uid('employee_with_role_2')));

SELECT map_client_and_employee(
               (tests.get_supabase_uid('client_with_role_2')),
               (tests.get_supabase_uid('employee_with_role_2')));


SELECT plan(7);

-- 1: client does not have role but is connected to one employee
SELECT tests.authenticate_as('client_without_role');

SELECT results_eq(
               ('SELECT count(*) FROM user_has_role'),
               $$VALUES (0::bigint)$$,
               'confirm that client does not have role and can not view any user_has_role'
       );

SELECT tests.clear_authentication();

-- 2: client has role and is connected to two employees
SELECT tests.authenticate_as('client_with_role_1');

SELECT results_eq(
               ('SELECT count(*) FROM user_has_role'),
               $$VALUES (3::bigint)$$,
               'confirm that client can view their own and both of their therapists user_has_role row'
       );

SELECT tests.clear_authentication();

-- 3: client has role and is connected to one employee
SELECT tests.authenticate_as('client_with_role_2');

SELECT results_eq(
               ('SELECT count(*) FROM user_has_role'),
               $$VALUES (2::bigint)$$,
               'confirm that client can view their own and their therapists user_has_role row'
       );

SELECT tests.clear_authentication();

-- 4: employee does not have role but is connected to one client
SELECT tests.authenticate_as('employee_without_role');

SELECT results_eq(
               ('SELECT count(*) FROM user_has_role'),
               $$VALUES (0::bigint)$$,
               'confirm that employee does not have role and can not view any user_has_role rows'
       );

SELECT tests.clear_authentication();

-- 5: employee has role and is connected to one client
SELECT tests.authenticate_as('employee_with_role_1');

SELECT results_eq(
               ('SELECT count(*) FROM user_has_role'),
               $$VALUES (2::bigint)$$,
               'confirm that employee can view their own and their clients user_has_role row'
       );

SELECT tests.clear_authentication();

-- 6: employee has role and is connected to two clients
SELECT tests.authenticate_as('employee_with_role_2');

SELECT results_eq(
               ('SELECT count(*) FROM user_has_role'),
               $$VALUES (3::bigint)$$,
               'confirm that employee can view their own and both of their clients user_has_role row'
       );

SELECT tests.clear_authentication();

-- 7: unauthenticated, information access denied
SELECT is_empty(
               $$ SELECT * FROM user_has_role $$,
               'confirm that no rows are returned for unauthenticated user');

SELECT * from finish();
ROLLBACK;