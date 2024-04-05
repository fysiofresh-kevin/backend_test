DROP POLICY IF EXISTS "Enable Admins to create invoice drafts" ON "public"."invoices";

CREATE TYPE invoice_status AS ENUM ('draft', 'booked', 'settled');

ALTER TABLE invoices
ALTER COLUMN status TYPE invoice_status USING status::invoice_status,
ALTER COLUMN status SET DEFAULT 'draft';

CREATE POLICY "Enable Admins to create invoice drafts"
    ON "public"."invoices" FOR INSERT WITH CHECK
    ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['invoices:write', 'invoices:admin'])
        AND status = 'draft');