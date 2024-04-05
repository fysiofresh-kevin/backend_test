CREATE OR REPLACE FUNCTION public.assign_user_profile_and_role(username TEXT, userRole TEXT, id UUID) RETURNS void AS $$
BEGIN
    PERFORM public.assign_user_profile(username, id);
    PERFORM public.assign_user_role(userRole, id);
END;
$$ language plpgsql;
