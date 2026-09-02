/*
# Add seller_fee column to orders table

## Purpose
Stores the WEARERA fee charged to the SELLER, separate from the buyer fee.
- Buyer always pays 8% on the article price (unchanged).
- Seller pays 0% on their first eligible transaction, 2% on subsequent transactions.

## Changes
- Added column: seller_fee (numeric, NOT NULL DEFAULT 0) on orders table.
- No existing columns modified or deleted. No data lost.

## Important Notes
1. The existing wearera_fee column continues to store the BUYER's 8% fee.
2. seller_fee stores the SELLER's fee (0% or 2% of seller_price).
3. The seller's net payout = seller_price - seller_fee.
*/

ALTER TABLE orders ADD COLUMN IF NOT EXISTS seller_fee numeric NOT NULL DEFAULT 0;
