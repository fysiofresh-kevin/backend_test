CREATE OR REPLACE FUNCTION public.assign_user_role(userRole TEXT, id UUID) RETURNS void AS $$
BEGIN
    INSERT INTO user_has_role
    (user_id, role)
    VALUES
        (id, userRole);
END;
$$ language plpgsql;