create table "public"."client_employee" (
    "client_id" text not null,
    "employee_id" text not null
);


alter table "public"."client_employee" enable row level security;

CREATE UNIQUE INDEX client_employee_pkey ON public.client_employee USING btree (client_id, employee_id);

alter table "public"."client_employee" add constraint "client_employee_pkey" PRIMARY KEY using index "client_employee_pkey";

alter table "public"."client_employee" add constraint "client_employee_client_id_fkey" FOREIGN KEY (client_id) REFERENCES user_profile(user_id) not valid;

alter table "public"."client_employee" validate constraint "client_employee_client_id_fkey";

alter table "public"."client_employee" add constraint "client_employee_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES user_profile(user_id) not valid;

alter table "public"."client_employee" validate constraint "client_employee_employee_id_fkey";

grant delete on table "public"."client_employee" to "anon";

grant insert on table "public"."client_employee" to "anon";

grant references on table "public"."client_employee" to "anon";

grant select on table "public"."client_employee" to "anon";

grant trigger on table "public"."client_employee" to "anon";

grant truncate on table "public"."client_employee" to "anon";

grant update on table "public"."client_employee" to "anon";

grant delete on table "public"."client_employee" to "authenticated";

grant insert on table "public"."client_employee" to "authenticated";

grant references on table "public"."client_employee" to "authenticated";

grant select on table "public"."client_employee" to "authenticated";

grant trigger on table "public"."client_employee" to "authenticated";

grant truncate on table "public"."client_employee" to "authenticated";

grant update on table "public"."client_employee" to "authenticated";

grant delete on table "public"."client_employee" to "service_role";

grant insert on table "public"."client_employee" to "service_role";

grant references on table "public"."client_employee" to "service_role";

grant select on table "public"."client_employee" to "service_role";

grant trigger on table "public"."client_employee" to "service_role";

grant truncate on table "public"."client_employee" to "service_role";

grant update on table "public"."client_employee" to "service_role";


