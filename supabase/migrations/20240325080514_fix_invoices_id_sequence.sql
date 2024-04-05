ALTER SEQUENCE invoices_id_seq RESTART WITH 1;

-- Assuming the identity column 'id' for 'invoices' table
SELECT setval(pg_get_serial_sequence('public.invoices', 'id'), coalesce(max(id), 1) + 1, false) FROM public.invoices;
