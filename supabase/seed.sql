INSERT INTO public.seed_version
    (version)
VALUES (1);

CREATE EXTENSION fysiofresh_helper_functions;

INSERT INTO permissions (permission)
VALUES
    ('appointment:read'),
    ('appointment:write'),
    ('appointment:delete'),
    ('appointment:cancel'),
    ('appointment:admin'),
    ('invoices:read'),
    ('invoices:write'),
    ('invoices:admin'),
    ('subscriptions:write'),
    ('subscriptions:admin'),
    ('journal:read'),
    ('journal:write'),
    ('journal:admin'),
    ('organization:read'),
    ('organization:write'),
    ('organization:admin'),
    ('site:navigation:clients'),
    ('site:navigation:employees'),
    ('site:navigation:services'),
    ('site:navigation:invoices');
-- Insert roles
INSERT INTO roles (role)
VALUES
    ('client'),
    ('employee'),
    ('admin');

INSERT INTO role_has_permissions (role, permission)
VALUES
    ('client', 'appointment:read'),
    ('client', 'appointment:cancel'),
    ('client', 'organization:read'),
    ('client', 'invoices:read'),
    ('client', 'site:navigation:invoices'),
    ('employee', 'appointment:read'),
    ('employee', 'appointment:cancel'),
    ('employee', 'journal:read'),
    ('employee', 'journal:write'),
    ('employee', 'organization:read'),
    ('employee', 'site:navigation:clients'),
    ('admin', 'appointment:read'),
    ('admin', 'appointment:write'),
    ('admin', 'appointment:delete'),
    ('admin', 'appointment:cancel'),
    ('admin', 'appointment:admin'),
    ('admin', 'invoices:read'),
    ('admin', 'invoices:write'),
    ('admin', 'invoices:admin'),
    ('admin', 'subscriptions:write'),
    ('admin', 'subscriptions:admin'),
    ('admin', 'journal:read'),
    ('admin', 'journal:write'),
    ('admin', 'journal:admin'),
    ('admin', 'organization:read'),
    ('admin', 'organization:write'),
    ('admin', 'organization:admin'),
    ('admin', 'site:navigation:clients'),
    ('admin', 'site:navigation:employees'),
    ('admin', 'site:navigation:services'),
    ('admin', 'site:navigation:invoices');
INSERT INTO services
    (created_at, price, duration, status, description, title, id)
VALUES ('2024-01-08 10:41:59.645907+00', 490, 2700, 'ACTIVE', 'Treatment in the clients own home', 'Home Treatment', 1),
       ('2024-01-08 10:45:59.645907+00', 290, 2700, 'ACTIVE', 'Treatment is purely virtual', 'Virtual Treatment', 2);

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

INSERT INTO appointments
    (id, created_at, client_id, employee_id, start, "end", notes, status)
VALUES
    (6, '2023-12-01 13:02:59.854815+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-21 12:00:00+00', '2023-12-21 12:00:00+00', 'hej med dig', 'pending'),
    (2, '2023-11-06 12:47:47.010801+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2024-01-02 10:00:00+00', '2024-01-02 11:00:00+00', 'Jeg er blevet forsinket med 30 minutter', 'completed'),
    (7, '2023-12-01 13:24:13.657111+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-21 08:00:00+00', '2023-12-21 08:00:00+00', 'sdfjnsdkjfnsdkjfsk', 'completed'),
    (5, '2023-12-01 09:00:21.768418+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-22 08:00:00+00', '2023-12-22 08:00:00+00', null, 'pending'),
    (3, '2023-12-01 09:00:21.768418+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-22 08:00:00+00', '2023-12-22 08:00:00+00', null, 'pending'),
    (1111, '2023-11-06 12:48:06.279819+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-20 12:00:00+00', '2023-12-20 12:00:00+00', 'asd', 'completed'),
    (2222, '2023-11-06 12:48:06.279819+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-20 12:00:00+00', '2023-12-20 12:00:00+00', 'asd', 'completed'),
    (3333, '2023-11-06 12:48:06.279819+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-20 12:00:00+00', '2023-12-20 12:00:00+00', 'asd', 'completed'),
    (4444, '2023-11-06 12:48:06.279819+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-20 12:00:00+00', '2023-12-20 12:00:00+00', 'asd', 'completed'),
    (5555, '2023-11-06 12:48:06.279819+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-20 12:00:00+00', '2023-12-20 12:00:00+00', 'asd', 'completed'),
    (6666, '2023-11-06 12:48:06.279819+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-20 12:00:00+00', '2023-12-20 12:00:00+00', 'asd', 'completed'),
    (7777, '2023-11-06 12:48:06.279819+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-20 12:00:00+00', '2023-12-20 12:00:00+00', 'asd', 'completed');

INSERT INTO invoices (
        id,
        created_at,
        "from",
        "to",
        billwerk_id,
        dinero_id,
        status,
        change_log,
        subscription_id
    )
VALUES (
        10010,
        '2024-01-24 12:39:46+00',
        '2024-01-24 12:39:46+00',
        '2024-01-31 12:39:51+00',
        'bw1',
        'dn1',
        'settled',
        NULL,
        'fake-sub-2'
    ),
    (
        10011,
        '2023-01-24 12:39:46+00',
        '2023-01-24 12:39:46+00',
        '2023-01-31 12:39:51+00',
        '14a608fe-802b-4659-b923-e56adcc478a0',
        '4b3b0a98ea795f34e0ae7a7347a8bb8b',
        'booked',
        NULL,
        'fake-sub-2'
    ),
    (
        10012,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        'bw3',
        'dn3',
        'booked',
        NULL,
        'fake-sub-2'
    ),
    (
        10013,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-2'
    ),
    (
        10014,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-2'
    ),
    (
        10015,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        10016,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        11111,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        22222,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        33333,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        44444,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        55555,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        66666,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        77777,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    );
INSERT INTO invoice_has_appointments
    (invoice_id, appointment_id)
VALUES
    (11111, 1111),
    (22222, 2222),
    (33333, 3333),
    (44444, 4444),
    (55555, 5555),
    (66666, 6666),
    (77777, 7777);
INSERT INTO appointment_has_services
    (appointment_id, service_id)
VALUES
    (6, 1),
    (2, 1),
    (3, 1);

UPDATE auth.users
SET role='service_role'
where id = '7a0e7730-9def-4d23-8012-729d5c86114e';

INSERT INTO appointments
    (id, created_at, client_id, employee_id, start, "end", notes, status)
VALUES
    (6, '2023-12-01 13:02:59.854815+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-21 12:00:00+00', '2023-12-21 12:00:00+00', 'hej med dig', 'pending'),
    (2, '2023-11-06 12:47:47.010801+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2024-01-02 10:00:00+00', '2024-01-02 11:00:00+00', 'Jeg er blevet forsinket med 30 minutter', 'completed'),
    (7, '2023-12-01 13:24:13.657111+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-21 08:00:00+00', '2023-12-21 08:00:00+00', 'sdfjnsdkjfnsdkjfsk', 'completed'),
    (5, '2023-12-01 09:00:21.768418+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-22 08:00:00+00', '2023-12-22 08:00:00+00', null, 'pending'),
    (3, '2023-12-01 09:00:21.768418+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-22 08:00:00+00', '2023-12-22 08:00:00+00', null, 'pending'),
    (1111, '2023-11-06 12:48:06.279819+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-20 12:00:00+00', '2023-12-20 12:00:00+00', 'asd', 'completed'),
    (2222, '2023-11-06 12:48:06.279819+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-20 12:00:00+00', '2023-12-20 12:00:00+00', 'asd', 'completed'),
    (3333, '2023-11-06 12:48:06.279819+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-20 12:00:00+00', '2023-12-20 12:00:00+00', 'asd', 'completed'),
    (4444, '2023-11-06 12:48:06.279819+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-20 12:00:00+00', '2023-12-20 12:00:00+00', 'asd', 'completed'),
    (5555, '2023-11-06 12:48:06.279819+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-20 12:00:00+00', '2023-12-20 12:00:00+00', 'asd', 'completed'),
    (6666, '2023-11-06 12:48:06.279819+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-20 12:00:00+00', '2023-12-20 12:00:00+00', 'asd', 'completed'),
    (7777, '2023-11-06 12:48:06.279819+00', '8a6657c8-b06e-4945-af12-238a3ea42f25', '59c1efb3-4f0e-43d4-99e6-cf0316e2a956',
     '2023-12-20 12:00:00+00', '2023-12-20 12:00:00+00', 'asd', 'completed');

INSERT INTO invoices (
        id,
        created_at,
        "from",
        "to",
        billwerk_id,
        dinero_id,
        status,
        change_log,
        subscription_id
    )
VALUES (
        10010,
        '2024-01-24 12:39:46+00',
        '2024-01-24 12:39:46+00',
        '2024-01-31 12:39:51+00',
        'bw1',
        'dn1',
        'settled',
        NULL,
        'fake-sub-2'
    ),
    (
        10011,
        '2023-01-24 12:39:46+00',
        '2023-01-24 12:39:46+00',
        '2023-01-31 12:39:51+00',
        '14a608fe-802b-4659-b923-e56adcc478a0',
        '4b3b0a98ea795f34e0ae7a7347a8bb8b',
        'booked',
        NULL,
        'fake-sub-2'
    ),
    (
        10012,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        'bw3',
        'dn3',
        'booked',
        NULL,
        'fake-sub-2'
    ),
    (
        10013,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-2'
    ),
    (
        10014,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-2'
    ),
    (
        10015,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        10016,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        11111,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        22222,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        33333,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        44444,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        55555,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        66666,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    ),
    (
        77777,
        '2025-01-24 12:39:46+00',
        '2025-01-24 12:39:46+00',
        '2025-01-31 12:39:51+00',
        null,
        null,
        'draft',
        NULL,
        'fake-sub-3'
    );
INSERT INTO invoice_has_appointments
    (invoice_id, appointment_id)
VALUES
    (11111, 1111),
    (22222, 2222),
    (33333, 3333),
    (44444, 4444),
    (55555, 5555),
    (66666, 6666),
    (77777, 7777);
INSERT INTO appointment_has_services
    (appointment_id, service_id)
VALUES
    (6, 1),
    (2, 1),
    (3, 1);

UPDATE auth.users
SET role='service_role'
where id = '7a0e7730-9def-4d23-8012-729d5c86114e';

DROP EXTENSION fysiofresh_helper_functions;
