BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

SELECT delete_all_data_in_schemas();

-- create users
SELECT tests.create_supabase_user('admin');
SELECT tests.create_supabase_user('employee_with_permission');
SELECT tests.create_supabase_user('employee_without_permission');
SELECT tests.create_supabase_user('client');

-- create roles with permissions
SELECT map_role_and_permissions('admin_role', ARRAY['appointment:read', 'appointment:write', 'organization:admin']);
SELECT map_role_and_permissions('employee_role', ARRAY['appointment:read', 'appointment:write']);
SELECT map_role_and_permissions('user_without_permission_role', ARRAY['appointment:read']);

-- connect users with roles
INSERT INTO public.user_has_role
(user_id, role)
VALUES
    ((tests.get_supabase_uid('admin')), 'admin_role'),
    ((tests.get_supabase_uid('employee_with_permission')), 'employee_role'),
    ((tests.get_supabase_uid('employee_without_permission')), 'user_without_permission_role');

-- map client and employee
SELECT public.map_client_and_employee((tests.get_supabase_uid('client')), (tests.get_supabase_uid('employee_with_permission')));
SELECT public.map_client_and_employee((tests.get_supabase_uid('client')), (tests.get_supabase_uid('employee_without_permission')));

-- Create services
INSERT INTO services
    (id, "status")
VALUES
    (1, 'DRAFT'),
    (2, 'ACTIVE'),
    (3, 'ARCHIVED');

SELECT public.map_appointment_and_services(1, (tests.get_supabase_uid('client')), (tests.get_supabase_uid('employee_with_permission')), 1);
SELECT public.map_appointment_and_services(2, (tests.get_supabase_uid('client')), (tests.get_supabase_uid('employee_without_permission')), 1);


-- disable all rls
SELECT public.disable_all_rls_in_public_schema();

-- enable rls on appointment_has_services
ALTER TABLE public.appointment_has_services
    ENABLE ROW LEVEL SECURITY;

SELECT plan(4);

-- 1: admin has permission to insert appointments, rows inserted as expected
SELECT tests.authenticate_as('admin');

INSERT INTO appointment_has_services
    (appointment_id, service_id)
VALUES
    (1, 2);

SELECT results_eq(
       ('SELECT count(*) FROM appointment_has_services'),
       $$VALUES (3::bigint)$$,
       'confirm that admin can insert rows in appointment_has_services'
);

SELECT tests.clear_authentication();

-- 2: employee has permission to insert services on their clients appointments, rows inserted as expected
SELECT tests.authenticate_as('employee_with_permission');

INSERT INTO appointment_has_services
    (appointment_id, service_id)
VALUES
    (1, 3);

SELECT results_eq(
       ('SELECT count(*) FROM appointment_has_services'),
       $$VALUES (4::bigint)$$,
       'confirm that employee can insert services on their clients appointments appointment_has_services'
);

SELECT tests.clear_authentication();

-- 3: employee without permission does not have permission to insert services on their clients appointments, no rows inserted as expected
SELECT tests.authenticate_as('employee_without_permission');

PREPARE employee_rls_thrower AS
INSERT INTO appointment_has_services
    (appointment_id, service_id)
VALUES
    (1, 3);

SELECT throws_ok(
    'employee_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "appointment_has_services"',
    'We should get a row-level security policy violation for insertion attempt'
);

SELECT tests.clear_authentication();

-- 4: anon user does not have permission to insert services on appointments, no rows inserted as expected
PREPARE anon_rls_thrower AS
INSERT INTO appointment_has_services
    (appointment_id, service_id)
VALUES
    (1, 3);

SELECT throws_ok(
    'anon_rls_thrower',
    '42501',
    'new row violates row-level security policy for table "appointment_has_services"',
    'We should get a row-level security policy violation for insertion attempt'
);

SELECT * from finish();
ROLLBACK;