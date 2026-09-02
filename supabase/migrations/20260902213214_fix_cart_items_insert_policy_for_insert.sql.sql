/*
  Fix: insert_own_cart policy was FOR ALL (default when no command is specified).
  Recreate it as FOR INSERT only, matching the 4-policy-per-verb convention.
*/
DROP POLICY IF EXISTS "insert_own_cart" ON cart_items;
CREATE POLICY "insert_own_cart" ON cart_items
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);