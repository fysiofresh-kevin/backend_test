CREATE OR REPLACE FUNCTION can_client_access_invoice(subscription_id text, auth_id UUID) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.subscriptions
    WHERE id::text = subscription_id
    AND client_id = auth_id
  );
END;
$$ LANGUAGE plpgsql;


DROP POLICY IF EXISTS "Enable client to read their own invoices" ON "public"."invoices";

CREATE POLICY "Enable client to read their own invoices"
ON "public"."invoices"
FOR SELECT
USING (
    can_client_access_invoice("public"."invoices"."subscription_id", "auth"."uid"())
    AND public.check_user_has_permission(auth.uid(), ARRAY['invoices:read'])
);