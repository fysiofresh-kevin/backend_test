-- ARRANGE

BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- Wipe data
SELECT delete_all_data_in_schemas();

-- Create test users
SELECT tests.create_supabase_user('employee_with_permission');
SELECT tests.create_supabase_user('employee_without_permission');
SELECT tests.create_supabase_user('employee_without_clients');
SELECT tests.create_supabase_user('client');
SELECT tests.create_supabase_user('client2');

-- Create roles with permissions
SELECT map_role_and_permissions('test_user_with_write_permission', ARRAY['journal:read', 'journal:write']);
SELECT map_role_and_permissions('test_user_without_write_permission', ARRAY['journal:read']);


-- connect users with roles
INSERT INTO public.user_has_role
(user_id, role)
VALUES
    ((tests.get_supabase_uid('employee_with_permission')), 'test_user_with_write_permission'),
    ((tests.get_supabase_uid('employee_without_clients')), 'test_user_with_write_permission'),
    ((tests.get_supabase_uid('employee_without_permission')), 'test_user_without_write_permission');

-- create employee_has_clients
INSERT INTO employee_has_clients
(employee_id, client_id)
VALUES
    ((tests.get_supabase_uid('employee_with_permission')), (tests.get_supabase_uid('client'))),
    ((tests.get_supabase_uid('employee_without_permission')), (tests.get_supabase_uid('client2')));

-- disable RLS on all tables and enable on journals
SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.journals
    ENABLE ROW LEVEL SECURITY;

-- ASSERT
SELECT plan(4);

-- 1: user has permission, information returned as expected
SELECT tests.authenticate_as('employee_with_permission');

INSERT INTO journals (
        id,
        journal_id,
        appointment_id,
        author_id,
        client_id,
        published,
        content,
        title
    )
VALUES (
        'c5dc30ba-e43d-4b20-be82-d21be785f24e',
        'c5dc30ba-e43d-4b20-be82-d21be785f24e',
        1,
        (tests.get_supabase_uid('employee_with_permission')),
        (tests.get_supabase_uid('client')),
        'true',
        'Gitte lavede 36 rejse/sættelser, men fik ondt i knæet',
        'Smerter i knæet'
    );

SELECT results_eq(
    ('SELECT count(*) FROM journals'),
    $$VALUES (1::bigint)$$,
    'confirm that employee with permission can read only their clients three journals'
);

SELECT tests.clear_authentication();

-- 2: employee user does not have permission, insert attempt denied
SELECT tests.authenticate_as('employee_without_permission');

PREPARE employee_without_permission_rls_thrower AS
INSERT INTO journals
    (
        id,
        journal_id,
        appointment_id,
        author_id,
        client_id,
        published,
        content,
        title
    )
VALUES (
        '67853490-f073-4bd6-912a-bec6699e5123',
        '67853490-f073-4bd6-912a-bec6699e5123',
        2,
        (tests.get_supabase_uid('employee_without_permission')),
        (tests.get_supabase_uid('client2')),
        'true',
        'Karl lavede 36 rejse/sættelser, men fik ondt i knæet',
        'Smerter i knæet'
    );
SELECT throws_ok(
    'employee_without_permission_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "journals"',
    'We should get a row-level security policy violation for insertion attempt'
);

SELECT tests.clear_authentication();

-- 3: employee user does not have clients, information access denied
SELECT tests.authenticate_as('employee_without_clients');

PREPARE employee_rls_thrower AS
INSERT INTO journals
    (
        id,
        journal_id,
        appointment_id,
        author_id,
        client_id,
        published,
        content,
        title
    )
VALUES (
        '67853490-f073-4bd6-912a-bec6699e5123',
        '67853490-f073-4bd6-912a-bec6699e5123',
        2,
        (tests.get_supabase_uid('employee_without_clients')),
        (tests.get_supabase_uid('client2')),
        'true',
        'Karl gik 4 ture rundt',
        'Forløb helt uden problemer'
    );
SELECT throws_ok(
    'employee_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "journals"',
    'We should get a row-level security policy violation for insertion attempt'
);

SELECT tests.clear_authentication();

-- 4: unauthenticated, information access denied

PREPARE anon_rls_thrower AS
INSERT INTO journals
    (
        id,
        journal_id,
        appointment_id,
        author_id,
        client_id,
        published,
        content,
        title
    )
VALUES (
        '67853490-f073-4bd6-912a-bec6699e5123',
        '67853490-f073-4bd6-912a-bec6699e5123',
        2,
        (tests.get_supabase_uid('employee_without_clients')),
        (tests.get_supabase_uid('client2')),
        'true',
        'Karl gik 4 ture rundt',
        'Forløb helt uden problemer'
    );
SELECT throws_ok(
    'anon_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "journals"',
    'We should get a row-level security policy violation for insertion attempt'
);

SELECT * from finish();
ROLLBACK;