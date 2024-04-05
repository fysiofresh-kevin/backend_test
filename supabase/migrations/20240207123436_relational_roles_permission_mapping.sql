CREATE TABLE "public"."permissions" (
  permission text NOT NULL,
  constraint permissions_pkey PRIMARY KEY (permission)
);

ALTER TABLE "public"."roles"
    DROP COLUMN permissions;

ALTER TABLE "public"."roles"
    RENAME COLUMN title TO role;

ALTER TABLE "public"."user_has_role"
    RENAME COLUMN roles TO role;

ALTER TABLE "public"."user_has_role"
    ALTER COLUMN role TYPE text;

ALTER TABLE "public"."user_has_role"
    ADD CONSTRAINT user_has_role_role_fkey FOREIGN KEY (role) REFERENCES roles (role);

ALTER TABLE "public"."user_has_role"
    DROP CONSTRAINT user_has_role_pkey;

ALTER TABLE "public"."user_has_role"
    DROP CONSTRAINT user_has_role_user_id_key;

ALTER TABLE "public"."user_has_role"
    ADD CONSTRAINT user_has_role_pkey PRIMARY KEY (user_id, role);


CREATE TABLE "public"."role_has_permissions" (
  role text NOT NULL,
  permission text NOT NULL,
  CONSTRAINT role_has_permissions_pkey PRIMARY KEY (role, permission),
  CONSTRAINT role_has_permissions_role_fkey FOREIGN KEY (role) REFERENCES roles (role),
  CONSTRAINT role_has_permissions_permissions_fkey FOREIGN KEY (permission) REFERENCES permissions (permission)
);

-- Change fk constraint to auth.users table instead of user profile

ALTER TABLE "public"."employee_has_clients"
    DROP CONSTRAINT employee_has_clients_employee_id_fkey;

alter table "public"."employee_has_clients"
    add constraint "employee_has_clients_employee_id_fkey"
        FOREIGN KEY (employee_id) REFERENCES auth.users(id)
            ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."employee_has_clients"
    validate constraint "employee_has_clients_employee_id_fkey";


ALTER TABLE "public"."employee_has_clients"
    DROP CONSTRAINT employee_has_clients_client_id_fkey;

alter table "public"."employee_has_clients"
    add constraint "employee_has_clients_client_id_fkey"
        FOREIGN KEY (client_id) REFERENCES auth.users(id)
            ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."employee_has_clients"
    validate constraint "employee_has_clients_client_id_fkey";


ALTER TABLE "public"."appointments"
    DROP CONSTRAINT appointments_employee_id_fkey;

alter table "public"."appointments"
    add constraint "appointments_employee_id_fkey"
        FOREIGN KEY (employee_id) REFERENCES auth.users(id)
            ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."appointments"
    validate constraint "appointments_employee_id_fkey";


ALTER TABLE "public"."appointments"
    DROP CONSTRAINT appointments_client_id_fkey;

alter table "public"."appointments"
    add constraint "appointments_client_id_fkey"
        FOREIGN KEY (client_id) REFERENCES auth.users(id)
            ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."appointments"
    validate constraint "appointments_client_id_fkey";