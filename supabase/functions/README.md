# payOS Edge Functions

These functions keep payOS credentials out of the Flutter app.

Required Supabase secrets:

```bash
supabase secrets set PAYOS_CLIENT_ID=your_client_id
supabase secrets set PAYOS_API_KEY=your_api_key
supabase secrets set PAYOS_CHECKSUM_KEY=your_checksum_key
supabase secrets set PAYOS_RETURN_URL=https://gymfit.app/payment-return
supabase secrets set PAYOS_CANCEL_URL=https://gymfit.app/payment-cancel
```

Deploy:

```bash
supabase functions deploy create-payos-payment
supabase functions deploy sync-payos-payment
supabase functions deploy payos-webhook --no-verify-jwt
```

Set the payOS webhook URL to:

```text
https://<project-ref>.functions.supabase.co/payos-webhook
```
