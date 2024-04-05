DROP TABLE public.appointment_has_services;
create table
public.appointment_has_services (
    appointment_id bigint not null,
    service_id bigint not null,
    constraint appointment_has_services_pkey primary key (appointment_id, service_id),
    constraint appointment_has_services_service_id_fkey foreign key (service_id) references services (id) on update cascade on delete cascade,
    constraint appointment_has_services_appointment_id_fkey foreign key (appointment_id) references appointments (id) on update cascade on delete cascade
) tablespace pg_default;

create policy "Enable select access to authenticated users (temporary)"
    on "public"."appointment_has_services"
    as permissive
    for select
    to authenticated
    using (true);

alter table "public"."appointment_has_services" enable row level security;