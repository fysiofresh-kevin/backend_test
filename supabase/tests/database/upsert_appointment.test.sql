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
SELECT public.seed_user('employee', 'employee@gmail.com', 'client', '48cc7515-d22b-43d6-a0d1-4b4ef3a481b3');

SELECT plan(4);

-- Test case 1: Insert a new appointment
SELECT is(
    upsert_appointment(
        jsonb_build_object(
            'client_id', '4e8546b7-0f19-4f13-a9a4-154163c6b655',
            'employee_id', '48cc7515-d22b-43d6-a0d1-4b4ef3a481b3',
            'start', '2024-03-21 10:00:00',
            'end', '2024-03-21 11:00:00',
            'notes', 'Follow-up',
            'status', 'pending'
        ),
        ARRAY[]::integer[]
   )::boolean,
   TRUE,
   'Insert a new appointment'
);

-- Test case 2: Inserting new appointment failed due to invalid status
-- prepare upsert appointment thrower expected to fail
SELECT is(
    upsert_appointment(
        jsonb_build_object(
            'client_id', '4e8546b7-0f19-4f13-a9a4-154163c6b655',
            'employee_id', '48cc7515-d22b-43d6-a0d1-4b4ef3a481b3',
            'start', '2024-03-21 10:00:00',
            'end', '2024-03-21 11:00:00',
            'notes', 'Follow-up',
            'status', 'received'
        ),
        ARRAY[]::INTEGER[]
    )::boolean,
    FALSE,
    'Inserting new appointment failed due to invalid status'
);

-- -- Create appointments and services
SELECT public.map_appointment_and_services(2, '4e8546b7-0f19-4f13-a9a4-154163c6b655', '48cc7515-d22b-43d6-a0d1-4b4ef3a481b3', 1);
SELECT public.map_appointment_and_services(3, '4e8546b7-0f19-4f13-a9a4-154163c6b655', '48cc7515-d22b-43d6-a0d1-4b4ef3a481b3', 2);

-- Test case 3: Update existing appointment
SELECT is(
    upsert_appointment(
        jsonb_build_object(
            'id', 2,
            'client_id', '4e8546b7-0f19-4f13-a9a4-154163c6b655',
            'employee_id', '48cc7515-d22b-43d6-a0d1-4b4ef3a481b3',
            'start', '2024-03-20 10:00:00',
            'end', '2024-03-20 11:00:00',
            'notes', 'Initial consultation',
            'status', 'completed'
        ),
        ARRAY[1,2]
    )::boolean,
    TRUE,
    'Upsert existing appointment'
);

-- Test case 4: Updating appointment failed due to invalid status
-- prepare upsert appointment thrower expected to fail
SELECT is(
    upsert_appointment(
        jsonb_build_object(
            'id', 2,
            'client_id', '4e8546b7-0f19-4f13-a9a4-154163c6b655',
            'employee_id', '48cc7515-d22b-43d6-a0d1-4b4ef3a481b3',
            'start', '2024-03-21 10:00:00',
            'end', '2024-03-21 11:00:00',
            'notes', 'Follow-up',
            'status', 'received'
        ),
        ARRAY[1,2]
    )::boolean,
    FALSE,
    'Updating appointment failed due to invalid status'
);

-- Finish tests
SELECT *
FROM finish();
ROLLBACK;
