CREATE OR REPLACE FUNCTION public.map_role_and_permissions(input_role TEXT, permissions TEXT[]) RETURNS void AS $$
DECLARE perm text;
BEGIN
    -- Insert the role into the public.roles table if it does not exist
    INSERT INTO public.roles (role)
    SELECT input_role
    WHERE NOT EXISTS (
        SELECT 1 FROM public.roles WHERE role = input_role
    );

    -- Insert the permissions into the public.permissions table if they do not exist
    FOREACH perm IN ARRAY permissions LOOP
            INSERT INTO public.permissions (permission)
            SELECT perm
            WHERE NOT EXISTS (
                SELECT 1 FROM public.permissions WHERE permission = perm
            );
        END LOOP;

    -- Insert input_role and permissions into the junction table role_has_permissions
    FOREACH perm IN ARRAY permissions LOOP
            INSERT INTO public.role_has_permissions (role, permission)
            VALUES (input_role, perm)
            ON CONFLICT (role, permission) DO NOTHING;
        END LOOP;
END;
$$ LANGUAGE plpgsql;
