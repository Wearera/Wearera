/*
# Create cart_items table for WEARERA shopping cart

## Summary
Creates a `cart_items` table to store articles added to a user's shopping cart.
Each user can have multiple cart items, but each article can only appear once
(unique constraint on article_id per user) since every second-hand item is unique.

## New Tables

### cart_items
- `id` (uuid, primary key)
- `user_id` (uuid, not null, references auth.users) — the buyer who owns this cart entry
- `article_id` (uuid, not null, references Articles) — the article added to cart
- `created_at` (timestamptz) — when the item was added

## Security
- RLS enabled on cart_items
- Only the cart owner can view, add, and remove their own items
- Uses auth.uid() for ownership checks
- Unique constraint on (user_id, article_id) to prevent duplicate cart entries
*/

CREATE TABLE IF NOT EXISTS cart_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
    article_id uuid NOT NULL REFERENCES "Articles"(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

CREATE UNIQUE INDEX IF NOT EXISTS idx_cart_items_user_article ON cart_items(user_id, article_id);

DROP POLICY IF EXISTS "select_own_cart" ON cart_items;
CREATE POLICY "select_own_cart" ON cart_items FOR SELECT
    TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "insert_own_cart" ON cart_items;
CREATE POLICY "insert_own_cart" ON cart_items
    TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "delete_own_cart" ON cart_items;
CREATE POLICY "delete_own_cart" ON cart_items FOR DELETE
    TO authenticated USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON cart_items(user_id);