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
SELECT public.map_appointment_and_services(1, (tests.get_supabase_uid('client')), (tests.get_supabase_uid('employee_with_permission')), 2);
SELECT public.map_appointment_and_services(2, (tests.get_supabase_uid('client')), (tests.get_supabase_uid('employee_without_permission')), 1);
SELECT public.map_appointment_and_services(2, (tests.get_supabase_uid('client')), (tests.get_supabase_uid('employee_without_permission')), 2);


-- disable all rls
SELECT public.disable_all_rls_in_public_schema();

-- enable rls on appointment_has_services
ALTER TABLE public.appointment_has_services
    ENABLE ROW LEVEL SECURITY;

SELECT plan(4);

-- 1: admin has permission to delete appointments, rows deleted as expected
SELECT tests.authenticate_as('admin');

DELETE FROM appointment_has_services
WHERE appointment_id = 1 AND service_id = 1;

SELECT results_eq(
       ('SELECT count(*) FROM appointment_has_services'),
       $$VALUES (3::bigint)$$,
       'confirm that admin can delete rows in appointment_has_services'
);

SELECT tests.clear_authentication();

-- 2: employee has permission to delete services from their clients' appointments, rows deleted as expected
SELECT tests.authenticate_as('employee_with_permission');

DELETE FROM appointment_has_services
WHERE appointment_id = 1 AND service_id = 2;

SELECT results_eq(
       ('SELECT count(*) FROM appointment_has_services'),
       $$VALUES (2::bigint)$$,
       'confirm that employee can delete services from their clients appointments in appointment_has_services'
);

SELECT tests.clear_authentication();

-- 3: employee without permission does not have permission to delete services from their clients' appointments, no rows deleted as expected
SELECT tests.authenticate_as('employee_without_permission');

DELETE FROM appointment_has_services
WHERE appointment_id = 2 AND service_id = 2;

SELECT results_eq(
       ('SELECT count(*) FROM appointment_has_services'),
       $$VALUES (2::bigint)$$,
       'confirm that anon cannot delete services from appointments in appointment_has_services'
);

SELECT tests.clear_authentication();

-- 4: anon user does not have permission to delete services from appointments, no rows deleted as expected
DELETE FROM appointment_has_services
WHERE appointment_id = 2 AND service_id = 2;

-- authorize as admin to read appointment_has_services
SELECT tests.authenticate_as('admin');

SELECT results_eq(
       ('SELECT count(*) FROM appointment_has_services'),
       $$VALUES (2::bigint)$$,
       'confirm that anon cannot delete services from appointments in appointment_has_services'
);

SELECT tests.clear_authentication();

SELECT * from finish();
ROLLBACK;