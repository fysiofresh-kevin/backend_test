CREATE OR REPLACE FUNCTION public.seed_user_auth(email TEXT, id UUID) RETURNS void AS $$
BEGIN
    INSERT INTO auth.users
    (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token,
     confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at,
     last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone,
     phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current,
     email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at)
    VALUES
        ('00000000-0000-0000-0000-000000000000', id, 'authenticated', 'authenticated',
         email, '$2a$10$33zG3o0nJZfFXQtl1nJe1.tzayAcAjhKrAbosJAsvVC8n3iGll5.K',
         '2023-10-29 14:24:49.807149+00', NULL, '', NULL, '', '2023-10-30 14:24:06.149227+00', '', '', NULL,
         '2024-01-08 15:41:00.819885+00', '{"provider":"email","providers":["email"]}', '{}', NULL,
         '2023-10-29 14:24:06.149227+00', '2024-01-11 20:01:51.345308+00', NULL, NULL, '', '', NULL, '', 0, NULL,
         '', NULL);

    insert into auth.identities (id, user_id, provider_id, identity_data, provider, created_at, last_sign_in_at, updated_at)
    values
        (id,
         id,
         id,
         jsonb_build_object('sub', id, 'email', email),
         'email',
         '2023-10-29 14:24:06.149227+00',
         '2024-01-08 15:41:00.819885+00',
         '2024-01-11 20:01:51.345308+00');
END;
$$ language plpgsql;
