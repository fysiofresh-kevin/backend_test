do $$
    DECLARE
        clientRole TEXT := 'client';
        employeeRole TEXT := 'employee';
        adminRole TEXT := 'admin';
        integration_client uuid := '77f089d8-66f5-40b2-9520-fb494350b7a3';
        integration_employee uuid := '88ec8e98-e708-4d0f-a44a-b6e1992315eb';
        integration_admin uuid := '7a38a993-93cf-462e-b8ad-52dd0b9c4022';
        integration_service_role uuid := '7a0e7730-9def-4d23-8012-729d5c86114e';
    BEGIN
        perform public.seed_user('Integration Client', 'integration@client.dk', clientRole, integration_client);
        perform public.seed_user('Integration Employee', 'integration@employee.dk', employeeRole, integration_employee);
        perform public.seed_user('Integration Admin', 'integration@admin.dk', adminRole, integration_admin);
        perform public.seed_user('Integration Service_Role', 'integration@servicerole.dk', adminRole, integration_service_role);
    END $$;

UPDATE auth.users
SET role='service_role'
where id = '7a0e7730-9def-4d23-8012-729d5c86114e';
