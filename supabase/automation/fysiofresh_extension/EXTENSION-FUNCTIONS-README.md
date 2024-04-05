# Overview of extension functions

To seed and test our database we have created a set of extension functions. 
These functions are primarily used to create data in the database or setup the database for test cases.

In order to enable these functions, you must first create the extension. This is done by calling:
> CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;

If you are creating it inside a test file after your begin statement, it will automatically be dropped when the rollback is called at the end of the test.
If you are using it outside such cases you need to drop the extension manually in the end of the file, by calling:
> DROP EXTENSION IF EXISTS fysiofresh_helper_functions;

## General test functions
The following functions are used to setup the database for testing. These functions takes zero parameters and returns void.

### [delete_all_data_in_schemas.sql](delete_all_data_in_schemas.sql)
This function is used to delete all data in the public and auth schemas.

### [disable_all_rls_in_public_schema.sql](disable_all_rls_in_public_schema.sql)
This function is used to disable all row level security in the public schema. This is done in order to avoid potential issues with RLS when doing unit tests.
The idea is that you call the function and afterwards enable RLS on the table you are testing, to make sure only the RLS for the table you are testing can interfere with your test. 
> SELECT disable_all_rls_in_public_schema();
>
> ALTER TABLE table_i_want_to_test ENABLE ROW LEVEL SECURITY;


## User seed functions
These functions are used to seed the database with user data in auth table and in the public table to assign them with a role and profile.

### [assign_user_profile.sql](assign_user_profile.sql)
This function takes 2 arguments, the name of the user and the user id:
> SELECT assign_user_profile(username TEXT, id UUID)

### [assign_user_role.sql](assign_user_role.sql)
This function takes 2 arguments, the role of the user and the user id:
> SELECT assign_user_role(userRole TEXT, id UUID)

### [assign_user_profile_and_role.sql](assign_user_profile_and_role.sql)
This function takes 3 arguments, the name of the user, the role of the user and the user id.
This function utilizes the [assign_user_profile.sql](assign_user_profile.sql) and [assign_user_role.sql](assign_user_role.sql) functions to assign the user profile and role in their respective tables:
> SELECT assign_user_profile_and_role(username TEXT, userRole TEXT, id UUID)

### [seed_user_auth.sql](seed_user_auth.sql)
This function takes 2 arguments, the email of the user and the user id:
> SELECT seed_user_auth(email TEXT, id UUID)

### [seed_user.sql](seed_user.sql)
This function takes 4 arguments the name of the user, the email of the user, the role of the user and the user id:
This function utilizes the [seed_user_auth.sql](seed_user_auth.sql) and [assign_user_profile_and_role.sql](assign_user_profile_and_role.sql) functions to seed the user in the auth table and assign the user profile and role in their respective tables:
> SELECT seed_user(username TEXT, email TEXT, userRole TEXT, id UUID)

## Map users and roles functions
These functions are used to map the user and role relations in the junction tables.

### [map_client_and_employee.sql](map_client_and_employee.sql)
This function takes 2 arguments, the client id and the employee id. 
It does not create the users themselves in other tables, only maps them together in the junction table employee_has_clients:
> SELECT map_client_and_employee(client uuid, employee uuid)

### [map_role_and_permissions.sql](map_role_and_permissions.sql)
This function takes 2 arguments, the role name and an array of permissions for that role.
It creates the role and the permissions in their respective tables if they do not exist and maps the permissions to the role in the junction table role_has_permissions.
> SELECT map_role_and_permissions(input_role TEXT, permissions TEXT[])

## Appointment and service functions
### [create_appointment.sql](create_appointment.sql)
This function takes 4 arguments, the appointment id, the client id, the employee id and the status of the appointment, which is a predefined enum type:
> SELECT create_appointment(input_appointment_id bigint, input_client_id UUID, input_employee_id UUID, input_status appointment_status)

### [create_service.sql](create_service.sql)
This function takes 2 arguments, the service id and the title of the service:
> SELECT create_service(input_service_id bigint, input_title TEXT)

### [map_appointment_and_services.sql](map_appointment_and_services.sql)
This function takes 4 arguments, the appointment id, the client id, the employee id and the service id.
This function utilizes the [create_appointment.sql](create_appointment.sql) and [create_service.sql](create_service.sql) functions to create the appointment and service in their respective tables if they do not exist. 
It then maps the service to the appointment in the junction table appointment_has_services:
> SELECT map_appointment_and_services(input_appointment_id bigint, input_client_id UUID, input_employee_id UUID, input_service_id bigint)

Note: This function automatically sets the status of the appointment to 'completed' and the service title to 'Test treatment' to simplify the amount of user inputs required.

## Subscription and invoice functions
### [create_subscription_for_client.sql](create_subscription_for_client.sql)
This function takes 2 arguments, the client id and the subscription id:
> SELECT create_subscription_for_client(client uuid, subscription_id TEXT)

Note: This function automatically sets the value of the subscription status to 'ACTIVE' and inserts two hardcoded dates in the created_at and last_paid fields.

### [create_invoice_with_subscription.sql](create_invoice_with_subscription.sql)
This function takes 3 arguments, the invoice id, the client id and the subscription id.
It creates a new subscription if no subscription with the given id exists, as a FK subscription id is required in the invoice table: 
> SELECT create_invoice_with_subscription(input_invoice_id bigint, input_client_id uuid, input_subscription_id TEXT)

Note: This function automatically sets the "from" and "to" dates of the invoice to the current date.

### [map_invoice_and_appointments.sql](map_invoice_and_appointments.sql)
This function takes 2 arguments, the invoice id and an array of appointment ids.
It maps the appointments to the invoice in the junction table invoice_has_appointments if they do not already exist:
> SELECT map_invoice_and_appointments(input_invoice_id bigint, input_appointment_ids bigint[])








