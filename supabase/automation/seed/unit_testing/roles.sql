-- Insert roles
INSERT INTO roles (role)
VALUES ('client'),
    ('employee'),
    ('admin');
INSERT INTO role_has_permissions (role, permission)
VALUES ('client', 'appointment:read'),
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