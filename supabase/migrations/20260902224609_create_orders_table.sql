/*
# Create orders table for WEARERA marketplace

## Purpose
Stores every order placed by a buyer on an article. Tracks the full lifecycle:
paid → shipped → delivered → completed (or disputed). Designed to integrate
with Stripe later: the buyer pays, WEARERA holds the funds, the seller ships,
the buyer confirms, then the seller is paid out.

## New Table: orders

Columns:
- id (uuid, PK) — unique order ID
- buyer_id (uuid, NOT NULL, DEFAULT auth.uid()) — the user who buys
- article_id (uuid, NOT NULL) — the article purchased
- seller_id (uuid, NOT NULL) — the seller (denormalized from Articles for fast queries)
- seller_price (numeric, NOT NULL) — the amount the seller wants to receive (e.g. 20.00)
- wearera_fee (numeric, NOT NULL DEFAULT 0) — 8% of seller_price (0.00 during launch promo)
- item_total (numeric, NOT NULL) — seller_price + wearera_fee (what the buyer pays for the item)
- shipping_cost (numeric, NOT NULL DEFAULT 0) — shipping, separate from fees
- grand_total (numeric, NOT NULL) — item_total + shipping_cost
- status (text, NOT NULL DEFAULT 'paid') — one of: paid, shipped, delivered, completed, disputed
- tracking_number (text) — carrier tracking number, set by seller when shipping
- shipped_at (timestamptz) — when seller marked as shipped
- delivered_at (timestamptz) — when delivery was confirmed
- verification_deadline (timestamptz) — delivered_at + 48 hours
- completed_at (timestamptz) — when order was completed (buyer confirmed or 48h expired)
- disputed_at (timestamptz) — when buyer opened a dispute
- dispute_reason (text) — buyer's explanation of the problem
- fee_waived (boolean, NOT NULL DEFAULT false) — true if launch promo waived the fee
- buyer_transaction_number (integer, NOT NULL DEFAULT 0) — which transaction this is for the buyer (1-based)
- payout_status (text, NOT NULL DEFAULT 'pending') — pending, released, held (for Stripe integration)
- created_at (timestamptz, DEFAULT now())

Foreign keys:
- buyer_id → auth.users(id) ON DELETE CASCADE
- article_id → Articles(id) ON DELETE CASCADE
- seller_id → auth.users(id) ON DELETE CASCADE

## Security (RLS)
- Enable RLS on orders.
- SELECT: buyer or seller of the order can read it.
- INSERT: only the buyer can create an order (buyer_id must = auth.uid()).
- UPDATE: buyer can update status (confirm/dispute); seller can update status/tracking (ship).
  Both parties can update, but the policy checks they are either buyer or seller.
- DELETE: blocked (orders are permanent records).

## Important Notes
1. The 8% WEARERA fee is calculated ONLY on seller_price, never on shipping.
2. Launch promo: first 2 transactions per buyer have fee waived (fee_waived = true).
3. The buyer_transaction_number is computed at insert time to determine promo eligibility.
4. No Stripe integration yet — payout_status defaults to 'pending'.
5. The 48-hour auto-completion will be handled by a scheduled job or edge function later.
*/

CREATE TABLE IF NOT EXISTS orders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
    article_id uuid NOT NULL REFERENCES "Articles"(id) ON DELETE CASCADE,
    seller_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    seller_price numeric NOT NULL,
    wearera_fee numeric NOT NULL DEFAULT 0,
    item_total numeric NOT NULL,
    shipping_cost numeric NOT NULL DEFAULT 0,
    grand_total numeric NOT NULL,
    status text NOT NULL DEFAULT 'paid',
    tracking_number text,
    shipped_at timestamptz,
    delivered_at timestamptz,
    verification_deadline timestamptz,
    completed_at timestamptz,
    disputed_at timestamptz,
    dispute_reason text,
    fee_waived boolean NOT NULL DEFAULT false,
    buyer_transaction_number integer NOT NULL DEFAULT 0,
    payout_status text NOT NULL DEFAULT 'pending',
    created_at timestamptz DEFAULT now()
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- SELECT: buyer or seller can read their orders
DROP POLICY IF EXISTS "select_own_orders" ON orders;
CREATE POLICY "select_own_orders" ON orders FOR SELECT
    TO authenticated
    USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- INSERT: only the buyer can create an order
DROP POLICY IF EXISTS "insert_own_orders" ON orders;
CREATE POLICY "insert_own_orders" ON orders FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = buyer_id);

-- UPDATE: buyer or seller can update (status transitions, tracking)
DROP POLICY IF EXISTS "update_own_orders" ON orders;
CREATE POLICY "update_own_orders" ON orders FOR UPDATE
    TO authenticated
    USING (auth.uid() = buyer_id OR auth.uid() = seller_id)
    WITH CHECK (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- No DELETE policy: orders are permanent

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_orders_buyer_id ON orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_orders_seller_id ON orders(seller_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
