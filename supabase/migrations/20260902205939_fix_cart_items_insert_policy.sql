/*
# Fix cart_items insert policy

## Summary
The insert_own_cart policy was accidentally created as FOR ALL instead of FOR INSERT.
This drops and recreates it as FOR INSERT only, matching the 4-policy-per-verb convention.
*/

DROP POLICY IF EXISTS "insert_own_cart" ON cart_items;
CREATE POLICY "insert_own_cart" ON cart_items
    TO authenticated WITH CHECK (auth.uid() = user_id);