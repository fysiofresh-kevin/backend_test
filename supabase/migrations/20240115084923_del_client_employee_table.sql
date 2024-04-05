revoke delete on table "public"."client_employee" from "anon";

revoke insert on table "public"."client_employee" from "anon";

revoke references on table "public"."client_employee" from "anon";

revoke select on table "public"."client_employee" from "anon";

revoke trigger on table "public"."client_employee" from "anon";

revoke truncate on table "public"."client_employee" from "anon";

revoke update on table "public"."client_employee" from "anon";

revoke delete on table "public"."client_employee" from "authenticated";

revoke insert on table "public"."client_employee" from "authenticated";

revoke references on table "public"."client_employee" from "authenticated";

revoke select on table "public"."client_employee" from "authenticated";

revoke trigger on table "public"."client_employee" from "authenticated";

revoke truncate on table "public"."client_employee" from "authenticated";

revoke update on table "public"."client_employee" from "authenticated";

revoke delete on table "public"."client_employee" from "service_role";

revoke insert on table "public"."client_employee" from "service_role";

revoke references on table "public"."client_employee" from "service_role";

revoke select on table "public"."client_employee" from "service_role";

revoke trigger on table "public"."client_employee" from "service_role";

revoke truncate on table "public"."client_employee" from "service_role";

revoke update on table "public"."client_employee" from "service_role";

alter table "public"."client_employee" drop constraint "client_employee_client_id_fkey";

alter table "public"."client_employee" drop constraint "client_employee_employee_id_fkey";

alter table "public"."client_employee" drop constraint "client_employee_pkey";

drop index if exists "public"."client_employee_pkey";

drop table "public"."client_employee";


