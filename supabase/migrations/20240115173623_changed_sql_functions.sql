alter table "public"."user_profile" drop column "email";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_all_clients(auth_id uuid)
 RETURNS SETOF jsonb
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT JSONB_BUILD_OBJECT(
    'id', client_profile.user_id,
    'email', get_user_email(client_profile.user_id::text),
    'name', client_profile.name
  )
  FROM user_has_role
  JOIN public.user_profile client_profile ON
  user_has_role.user_id = client_profile.user_id
  WHERE
    roles @> '["client"]' AND
    (check_are_users_connected(auth_id, client_profile.user_id) OR check_user_has_permission(auth_id, '["organization:read", "organization:admin"]'));
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_appointments_for_user(user_id_param uuid)
 RETURNS TABLE(appointment jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    JSONB_BUILD_OBJECT(
      'id', appointments.id,
      'client', JSONB_BUILD_OBJECT('id', appointments.client_id, 'email', get_user_email(appointments.client_id::text), 'name', client_profile.name),
      'employee', JSONB_BUILD_OBJECT('id', appointments.employee_id, 'email', get_user_email(appointments.employee_id::text), 'name', employee_profile.name),
      'start', appointments.start,
      'end', appointments.end,
      'status', appointments.status,
      'notes', appointments.notes) as appointment
  FROM appointments
  JOIN
    public.user_profile client_profile ON appointments.client_id = client_profile.user_id
  JOIN
    public.user_profile employee_profile ON appointments.employee_id = employee_profile.user_id
  WHERE
  CASE
    WHEN appointments.client_id = user_id_param THEN true
    WHEN appointments.employee_id = user_id_param THEN true
    ELSE check_user_has_permission(user_id_param, '["appointment:read", "appointment:admin"]')
  END;
END;
$function$
;


