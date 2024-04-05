BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
-- Insert test data
SELECT tests.create_supabase_user('client_1');
SELECT tests.create_supabase_user('client_2');
SELECT tests.create_supabase_user('employee_1');
SELECT tests.create_supabase_user('employee_2');

INSERT INTO user_profile
    (user_id, name)
VALUES ((tests.get_supabase_user('client_1') ->> 'id')::UUID, 'client 1'),
       ((tests.get_supabase_user('client_2') ->> 'id')::UUID, 'client 2'),
       ((tests.get_supabase_user('employee_1') ->> 'id')::UUID, 'employee 1'),
       ((tests.get_supabase_user('employee_2') ->> 'id')::UUID, 'employee 2');

-- Ensure no existing data could overlap & corrupt the test.
DELETE
FROM employee_has_clients;

SELECT plan(6);
-- Test case: Function returns the roles field as jsonb
SELECT has_table('public', 'employee_has_clients', 'Table: employee_has_clients exists');

-- Test case: Function exists
SELECT has_function(
               'public',
               'update_employee_to_clients_relationships',
               ARRAY ['uuid', 'uuid[]'],
               'Function: update_employee_to_clients_relationships exists with uuid arguments');

SELECT is(
               update_employee_to_clients_relationships(
                       (tests.get_supabase_user('employee_1') ->> 'id')::UUID,
                       ARRAY [
                           (tests.get_supabase_user('client_1') ->> 'id')::UUID,
                           (tests.get_supabase_user('client_2') ->> 'id')::UUID
                           ]
               ),
               'ok',
               'Function returns ok'
       );

SELECT is(
               (SELECT ARRAY_AGG(client_id)
                FROM employee_has_clients
                WHERE employee_id = (tests.get_supabase_user('employee_1') ->> 'id')::UUID),
               ARRAY [
                   (tests.get_supabase_user('client_1') ->> 'id')::UUID,
                   (tests.get_supabase_user('client_2') ->> 'id')::UUID
                   ],
               'Confirm if the database has the expected consequences'
       );

SELECT is(
               update_employee_to_clients_relationships(
                       (tests.get_supabase_user('employee_1') ->> 'id')::UUID,
                       ARRAY [(tests.get_supabase_user('client_1') ->> 'id')::UUID]
               ),
               'ok',
               'Function returns ok'
       );

SELECT is(
               (SELECT ARRAY_AGG(client_id)
                FROM employee_has_clients
                WHERE employee_id = (tests.get_supabase_user('employee_1') ->> 'id')::UUID),
               ARRAY [(tests.get_supabase_user('client_1') ->> 'id')::UUID],
               'Confirm if the database has the expected consequences'
       );
SELECT *
FROM finish(TRUE);
ROLLBACK;