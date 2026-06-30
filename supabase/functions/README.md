# Supabase Edge Functions

These functions keep provider credentials out of the Flutter app.

## AI Search Suggestions (Groq)

Required Supabase secrets:

```bash
supabase secrets set GROQ_API_KEY=your_groq_api_key
supabase secrets set GROQ_MODEL=llama-3.1-8b-instant
```

Deploy:

```bash
supabase functions deploy ai-search-suggestions
```

Flutter calls this function from the catalog search flow. If the function is not
deployed or Groq fails, the app falls back to Supabase product-name suggestions.

## payOS

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
