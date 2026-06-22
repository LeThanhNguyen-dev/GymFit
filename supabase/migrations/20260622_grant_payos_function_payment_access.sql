-- Allow Edge Functions that use the service role key to read/update payments.

GRANT SELECT, UPDATE ON TABLE public.payments TO service_role;
