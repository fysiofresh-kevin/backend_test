BEGIN;
CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

-- wipe table data
SELECT delete_all_data_in_schemas();

-- Insert test data
SELECT public.seed_user_auth('user@gmail.com', 'cdcb5284-2b55-4d11-8fe5-b4c939411a59');


SELECT plan(1);

SELECT is(
       get_user_email('cdcb5284-2b55-4d11-8fe5-b4c939411a59'),
       'user@gmail.com',
       'Confirm that user email is correct'
);

-- Finish tests
SELECT *
FROM finish();
ROLLBACK;