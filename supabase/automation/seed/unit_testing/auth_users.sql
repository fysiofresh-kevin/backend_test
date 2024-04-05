do $$
DECLARE
    clientRole TEXT := 'client';
    employeeRole TEXT := 'employee';
    adminRole TEXT := 'admin';
    client1 uuid := '8a6657c8-b06e-4945-af12-238a3ea42f25';
    client2 uuid := '7598645c-b688-47bd-be9a-8c83de365471';
    client3 uuid := '3598645c-b688-98dd-be9a-8c83de365651';
    employee1 uuid := '176657c8-b06e-4945-af12-238a3ea42f89';
    employee2 uuid := '59c1efb3-4f0e-43d4-99e6-cf0316e2a956';
    admin1 uuid := 'ab99645c-b688-47bd-be9a-8c83de875471';
    integration_client uuid := '77f089d8-66f5-40b2-9520-fb494350b7a3';
    integration_employee uuid := '88ec8e98-e708-4d0f-a44a-b6e1992315eb';
    integration_admin uuid := '7a38a993-93cf-462e-b8ad-52dd0b9c4022';
BEGIN
    perform public.seed_user('John Klientsen', 'pdhh+client@live.dk', clientRole, client1);
    perform public.seed_user('Henrik Klientsen', 'pdhh+client2@live.dk', clientRole, client2);
    perform public.seed_user('Ymer Klientsen', 'pdhh+client3@live.dk', clientRole, client3);
    perform public.seed_user('Søren Ansat', 'pdhh+employee@live.dk', employeeRole, employee1);
    perform public.seed_user('Bimmer Ansat', 'pdhh+employee2@live.dk', employeeRole, employee2);
    perform public.seed_user('Jørgen Admin', 'pdhh+admin@live.dk', adminRole, admin1);
    perform public.seed_user('Integration Client', 'integration@client.dk', clientRole, integration_client);
    perform public.seed_user('Integration Employee', 'integration@employee.dk', employeeRole, integration_employee);
    perform public.seed_user('Integration Admin', 'integration@admin.dk', adminRole, integration_admin);

    perform public.map_client_and_employee(client1, employee1);
    perform public.map_client_and_employee(client2, employee1);
    perform public.map_client_and_employee(client3, employee2);
    perform public.map_client_and_employee(client1, employee2);


    perform public.create_subscription_for_client(client1, 'supabase-user-subscription-id-3');
    perform public.create_subscription_for_client(client2, 'fake-sub-2');
    perform public.create_subscription_for_client(client3, 'fake-sub-3');
END $$;

