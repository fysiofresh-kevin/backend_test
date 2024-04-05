CREATE OR REPLACE FUNCTION public.seed_user(username TEXT, email TEXT, userRole TEXT, id UUID) RETURNS void AS $$
BEGIN
    PERFORM public.seed_user_auth(email, id);
    PERFORM public.assign_user_profile_and_role(username, userRole, id);
END;
$$ language plpgsql;
