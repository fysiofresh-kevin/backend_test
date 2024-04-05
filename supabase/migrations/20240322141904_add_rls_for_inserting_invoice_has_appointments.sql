CREATE POLICY "Enable Admins to upsert invoice_has_appointments" ON "public"."invoice_has_appointments" FOR INSERT WITH CHECK (
  "public"."check_user_has_permission"(
    "auth"."uid"(),
    ARRAY ['appointment:write', 'appointment:admin']
  )
);