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
SELECT map_role_and_permissions('test_user_with_permission', ARRAY['journal:read']);
SELECT map_role_and_permissions('test_user_without_permission', ARRAY['']);


-- connect users with roles
INSERT INTO public.user_has_role
(user_id, role)
VALUES
    ((tests.get_supabase_uid('employee_with_permission')), 'test_user_with_permission'),
    ((tests.get_supabase_uid('employee_without_clients')), 'test_user_with_permission'),
    ((tests.get_supabase_uid('employee_without_permission')), 'test_user_without_permission');

-- create employee_has_clients
INSERT INTO employee_has_clients
(employee_id, client_id)
VALUES
    ((tests.get_supabase_uid('employee_with_permission')), (tests.get_supabase_uid('client'))),
    ((tests.get_supabase_uid('employee_without_permission')), (tests.get_supabase_uid('client')));

-- create journals
INSERT INTO journals (
        id,
        journal_id,
        appointment_id,
        author_id,
        client_id,
        published,
        content,
        title,
        created_at
    )
VALUES (
        'c5dc30ba-e43d-4b20-be82-d21be785f24e',
        'c5dc30ba-e43d-4b20-be82-d21be785f24e',
        1,
        (tests.get_supabase_uid('employee_with_permission')),
        (tests.get_supabase_uid('client')),
        'true',
        'Gitte lavede 36 rejse/sættelser, men fik ondt i knæet',
        'Smerter i knæet',
        '2025-01-24 12:39:46+00'
    ),
    (
        '67853490-f073-4bd6-912a-bec6699e5123',
        'c5dc30ba-e43d-4b20-be82-d21be785f24e',
        1,
        (tests.get_supabase_uid('employee_with_permission')),
        (tests.get_supabase_uid('client')),
        'true',
        'Gitte lavede 36 rejse/sættelser, men fik ondt i knæet',
        'Smerter i knæet',
        '2025-01-24 12:39:46+00'
    ),
    (
        '5278df54-14a3-41f2-b41a-b99eb4aa02e3',
        '5278df54-14a3-41f2-b41a-b99eb4aa02e3',
        2,
        (tests.get_supabase_uid('employee_without_permission')),
        (tests.get_supabase_uid('client')),
        'true',
        'Karl har ondt i ryggen',
        NULL,
        '2025-01-24 12:39:48+00'
    ),
    (
        '56c03efc-f9be-492b-ad70-4abd8297bb8d',
        '5278df54-14a3-41f2-b41a-b99eb4aa02e3',
        2,
        (tests.get_supabase_uid('employee_without_permission')),
        (tests.get_supabase_uid('client2')),
        'true',
        'Karl havde hovedpine',
        NULL,
        '2025-01-24 12:39:48+00'
    );

-- disable RLS on all tables and enable on journals
SELECT public.disable_all_rls_in_public_schema();

ALTER TABLE public.journals
    ENABLE ROW LEVEL SECURITY;

-- ASSERT
SELECT plan(4);

-- 1: user has permission, information returned as expected
SELECT tests.authenticate_as('employee_with_permission');

SELECT results_eq(
    ('SELECT count(*) FROM journals'),
    $$VALUES (3::bigint)$$,
    'confirm that employee with permission can read only their clients three journals'
);


SELECT tests.clear_authentication();

-- 2: employee user does not have permission, information access denied
SELECT tests.authenticate_as('employee_without_permission');

SELECT is_empty(
               $$ SELECT * FROM journals $$,
               'confirm that no rows are returned for user without permissions');

SELECT tests.clear_authentication();

-- 3: employee user does not have clients, information access denied
SELECT tests.authenticate_as('employee_without_clients');

SELECT is_empty(
               $$ SELECT * FROM journals $$,
               'confirm that no rows are returned for user without clients');

SELECT tests.clear_authentication();

-- 4: unauthenticated, information access denied
SELECT is_empty(
               $$ SELECT * FROM journals $$,
               'confirm that no rows are returned for unauthenticated user');

SELECT * from finish();
ROLLBACK;