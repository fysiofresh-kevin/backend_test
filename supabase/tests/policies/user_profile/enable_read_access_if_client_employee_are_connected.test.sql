-- create dummy user
-- add role to user
-- add permission to users role

-- assert that it returns true for authenticated user with permission
-- assert that it returns false for authenticated user but no permission
-- assert that it returns false for anon user

BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('client_without_permission');
SELECT tests.create_supabase_user('client_with_permission_1');
SELECT tests.create_supabase_user('client_with_permission_2');

SELECT tests.create_supabase_user('employee_without_permission');
SELECT tests.create_supabase_user('employee_with_permission_1');
SELECT tests.create_supabase_user('employee_with_permission_2');

-- Create roles
SELECT public.map_role_and_permissions('role_with_permission', ARRAY['organization:read']);
SELECT public.map_role_and_permissions('role_without_permission', ARRAY['']);

-- connect users with roles
INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_user('client_without_permission') ->> 'id')::uuid, 'role_without_permission'),
    ((tests.get_supabase_user('employee_without_permission') ->> 'id')::uuid, 'role_without_permission'),

    ((tests.get_supabase_user('client_with_permission_1') ->> 'id')::uuid, 'role_with_permission'),
    ((tests.get_supabase_user('client_with_permission_2') ->> 'id')::uuid, 'role_with_permission'),
    ((tests.get_supabase_user('employee_with_permission_1') ->> 'id')::uuid, 'role_with_permission'),
    ((tests.get_supabase_user('employee_with_permission_2') ->> 'id')::uuid, 'role_with_permission');
;

-- connect clients with employees
SELECT map_client_and_employee(
               (tests.get_supabase_user('client_without_permission') ->> 'id')::uuid,
                (tests.get_supabase_user('employee_without_permission') ->> 'id')::uuid);

SELECT map_client_and_employee(
               (tests.get_supabase_user('client_with_permission_1') ->> 'id')::uuid,
               (tests.get_supabase_user('employee_with_permission_1') ->> 'id')::uuid);

SELECT map_client_and_employee(
               (tests.get_supabase_user('client_with_permission_1') ->> 'id')::uuid,
               (tests.get_supabase_user('employee_with_permission_2') ->> 'id')::uuid);

SELECT map_client_and_employee(
               (tests.get_supabase_user('client_with_permission_2') ->> 'id')::uuid,
               (tests.get_supabase_user('employee_with_permission_2') ->> 'id')::uuid);


-- Connect user with profile
INSERT INTO public.user_profile
    (user_id, name)
VALUES
    ((tests.get_supabase_user('client_without_permission') ->> 'id')::uuid, 'Client Has No Permissions'),
    ((tests.get_supabase_user('client_with_permission_1') ->> 'id')::uuid, 'Client Two Has Two Employees'),
    ((tests.get_supabase_user('client_with_permission_2') ->> 'id')::uuid, 'Client Three Has One Employee'),
    ((tests.get_supabase_user('employee_without_permission') ->> 'id')::uuid, 'Employee Has No Permissions'),
    ((tests.get_supabase_user('employee_with_permission_1') ->> 'id')::uuid, 'Employee Two Has One Client'),
    ((tests.get_supabase_user('employee_with_permission_2') ->> 'id')::uuid, 'Employee Three Has Two Clients');

SELECT plan(7);

-- 1: client does not have permission but is connected to one employee
SELECT tests.authenticate_as('client_without_permission');

SELECT results_eq(
               ('SELECT count(*) FROM user_profile'),
               $$VALUES (0::bigint)$$,
               'confirm that client does not have permission and can not view any profiles'
       );

SELECT tests.clear_authentication();

-- 2: client has permission and is connected to two employees
SELECT tests.authenticate_as('client_with_permission_1');

SELECT results_eq(
               ('SELECT count(*) FROM user_profile'),
               $$VALUES (3::bigint)$$,
               'confirm that client can view their own and both of their therapists profile'
       );

SELECT tests.clear_authentication();

-- 3: client has permission and is connected to one employee
SELECT tests.authenticate_as('client_with_permission_2');

SELECT results_eq(
               ('SELECT count(*) FROM user_profile'),
               $$VALUES (2::bigint)$$,
               'confirm that client can view their own and their therapists profile'
       );

SELECT tests.clear_authentication();

-- 4: employee does not have permission but is connected to one client
SELECT tests.authenticate_as('employee_without_permission');

SELECT results_eq(
               ('SELECT count(*) FROM user_profile'),
               $$VALUES (0::bigint)$$,
               'confirm that employee does not have permission and can not view any profiles'
       );

SELECT tests.clear_authentication();

-- 5: employee has permission and is connected to one client
SELECT tests.authenticate_as('employee_with_permission_1');

SELECT results_eq(
               ('SELECT count(*) FROM user_profile'),
               $$VALUES (2::bigint)$$,
               'confirm that employee can view their own and their clients profile'
       );

SELECT tests.clear_authentication();

-- 6: employee has permission and is connected to two clients
SELECT tests.authenticate_as('employee_with_permission_2');

SELECT results_eq(
               ('SELECT count(*) FROM user_profile'),
               $$VALUES (3::bigint)$$,
               'confirm that employee can view their own and both of their clients profile'
       );

SELECT tests.clear_authentication();

-- 7: unauthenticated, information access denied
SELECT is_empty(
               $$ SELECT * FROM user_profile $$,
               'confirm that no rows are returned for unauthenticated user');

SELECT * from finish();
ROLLBACK;