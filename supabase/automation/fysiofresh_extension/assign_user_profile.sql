CREATE OR REPLACE FUNCTION public.assign_user_profile(username TEXT, id UUID) RETURNS void AS $$
BEGIN
    INSERT INTO user_profile
    (user_id, "name")
    VALUES
        (id, username);

END;
$$ language plpgsql;