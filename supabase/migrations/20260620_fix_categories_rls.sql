-- Fix RLS for categories and brands so Store Owners (and Customers) can read them
CREATE POLICY "Enable read access for all users" ON "public"."categories" AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Enable read access for all users" ON "public"."brands" AS PERMISSIVE FOR SELECT TO public USING (true);
