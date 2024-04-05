-- rls for subscriptions

create policy "Enable users to read their own subscriptions"
    on public.subscriptions
    for select
    to authenticated
    using (((auth.uid() = client_id) AND check_user_has_permission(auth.uid(), ARRAY['organization:read'])));

create policy "Enable admins to view all user subscriptions"
    on public.subscriptions
    for select
    to authenticated
    using (check_user_has_permission(auth.uid(), ARRAY['organization:read', 'organization:admin']));

alter table public.subscriptions
    enable row level security;

-- remove subscription_has_invoices and change structure in invoices table

drop table public.subscription_has_invoices;

ALTER TABLE public.invoices
    ADD COLUMN subscription_id text NOT NULL,
    ADD CONSTRAINT invoices_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscriptions (id) ON UPDATE CASCADE ON DELETE RESTRICT;

CREATE POLICY "Enable Admins to create invoice drafts"
    ON "public"."invoices" FOR INSERT WITH CHECK
    ("public"."check_user_has_permission"("auth"."uid"(), ARRAY['invoices:write', 'invoices:admin'])
        AND status = 'draft');

