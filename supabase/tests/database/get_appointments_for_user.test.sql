BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- disable RLS on all tables
SELECT public.disable_all_rls_in_public_schema();

-- Create roles
INSERT INTO roles
    ("role")
VALUES
    ('client'),
    ('employee');

-- Create test users
SELECT public.seed_user('client', 'client@gmail.com', 'client', '4e8546b7-0f19-4f13-a9a4-154163c6b655');
SELECT public.seed_user('client_without_appointments', 'client_without_appointments@gmail.com', 'client', 'df03260f-0aa9-4006-a7c0-b974222257d1');
SELECT public.seed_user('employee', 'employee@gmail.com', 'client', '48cc7515-d22b-43d6-a0d1-4b4ef3a481b3');
SELECT public.seed_user('employee_without_appointments', 'employee_without_appointments@gmail.com', 'client', '585b4abe-d4c5-491c-9a3b-515f3c281c38');

-- Create appointments
SELECT public.map_appointment_and_services(1, '4e8546b7-0f19-4f13-a9a4-154163c6b655', '48cc7515-d22b-43d6-a0d1-4b4ef3a481b3', 1);
SELECT public.map_appointment_and_services(2, '4e8546b7-0f19-4f13-a9a4-154163c6b655', '48cc7515-d22b-43d6-a0d1-4b4ef3a481b3', 2);
SELECT public.map_appointment_and_services(3, '4e8546b7-0f19-4f13-a9a4-154163c6b655', '48cc7515-d22b-43d6-a0d1-4b4ef3a481b3', 3);

     
SELECT plan(4);

SELECT is(
       (SELECT count(*) FROM get_appointments_for_user('4e8546b7-0f19-4f13-a9a4-154163c6b655')),
       3::bigint,
       'Function returns the correct number of client appointments'
);

SELECT is(
       (SELECT count(*) FROM get_appointments_for_user('df03260f-0aa9-4006-a7c0-b974222257d1')),
       0::bigint,
       'Function returns no appointments for client without appointments'
);

SELECT is(
       (SELECT count(*) FROM get_appointments_for_user('48cc7515-d22b-43d6-a0d1-4b4ef3a481b3')),
       3::bigint,
       'Function returns the correct number of employee appointments'
);

SELECT is(
       (SELECT count(*) FROM get_appointments_for_user('585b4abe-d4c5-491c-9a3b-515f3c281c38')),
       0::bigint,
       'Function returns no appointments for employee without appointments'
);

SELECT *
FROM finish();
ROLLBACK;