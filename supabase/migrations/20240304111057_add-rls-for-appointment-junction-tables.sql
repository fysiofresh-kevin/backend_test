CREATE OR REPLACE function get_client_id_by_appointment(appointment_id BIGINT) RETURNS UUID AS $$
BEGIN
  RETURN (
    SELECT client_id
    FROM public.appointments
    WHERE id = appointment_id
  );
END;
$$ LANGUAGE plpgsql;

ALTER TABLE "public"."invoice_has_appointments"
    ENABLE ROW LEVEL SECURITY;


drop policy if exists "Enable clients to read appointments on their invoices"
    on "public"."invoice_has_appointments";

drop policy if exists "Enable admin to read all appointments on invoices"
    on "public"."invoice_has_appointments";

drop policy if exists "Enable select access to authenticated users (temporary)"
    on "public"."appointment_has_services";

drop policy if exists "Enable clients to read services on their appointments"
    on "public"."appointment_has_services";


create policy "Enable clients to read appointments on their invoices"
    on "public"."invoice_has_appointments"
    as permissive
    for select
    to authenticated
    using (((get_client_id_by_appointment(appointment_id) = auth.uid()) AND check_user_has_permission(auth.uid(), ARRAY['appointment:read'])));


create policy "Enable admin to read all appointments on invoices"
    on "public"."invoice_has_appointments"
    as permissive
    for select
    to authenticated
    using ((check_user_has_permission(auth.uid(), ARRAY['organization:admin'])));


create policy "Enable clients to read services on their appointments"
    on "public"."appointment_has_services"
    as permissive
    for select
    to authenticated
    using (((get_client_id_by_appointment(appointment_id) = auth.uid()) AND check_user_has_permission(auth.uid(), ARRAY['appointment:read'])));



create policy "Enable admin to read all services on appointments"
    on "public"."appointment_has_services"
    as permissive
    for select
    to authenticated
    using ((check_user_has_permission(auth.uid(), ARRAY['organization:admin'])));


create policy "Enable employee to read services on their clients appointments"
    on "public"."appointment_has_services"
    as permissive
    for select
    to authenticated
    using ((check_are_users_connected(auth.uid(), get_client_id_by_appointment(appointment_id)) AND check_user_has_permission(auth.uid(), ARRAY['appointment:read'])));