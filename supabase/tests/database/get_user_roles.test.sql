BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
-- Insert test data
SELECT tests.create_supabase_user('user_1');
SELECT tests.create_supabase_user('user_2');

INSERT INTO public.roles (role)
VALUES ('test_client'),
       ('test_admin'),
       ('test_employee');

INSERT INTO public.user_has_role
    (user_id, role)
VALUES
    ((tests.get_supabase_user('user_1') ->> 'id')::uuid, 'test_client');
INSERT INTO public.user_has_role VALUES
    ((tests.get_supabase_user('user_2') ->> 'id')::uuid, 'test_admin');
INSERT INTO public.user_has_role VALUES
    ((tests.get_supabase_user('user_2') ->> 'id')::uuid, 'test_employee');


SELECT plan(4);
-- Test case: Function returns the roles field as jsonb
SELECT has_table('public', 'user_has_role', 'Table: user_has_role exists');

-- Test case: Function exists
SELECT has_function('public', 'get_user_roles', ARRAY['uuid'], 'Function: get_user_roles exists with uuid argument');

-- Test function with test user and expected return of test_client
SELECT is(
    get_user_roles((tests.get_supabase_user('user_1') ->> 'id')::uuid),
    ARRAY['test_client'],
    'Function returns the roles field as an array'
);

-- Test function with test user and expected return of test_client, test_employee
SELECT is(
    get_user_roles((tests.get_supabase_user('user_2') ->> 'id')::uuid),
    ARRAY['test_admin', 'test_employee'],
    'Function returns the roles field as an array'
);
SELECT * FROM finish(true);
ROLLBACK;