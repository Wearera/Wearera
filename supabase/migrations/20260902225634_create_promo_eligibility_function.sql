/*
# Launch promo eligibility function

## Purpose
Determines whether a seller is eligible for the launch promo (0% WEARERA fee on their first transaction).

## Rules
1. The promo is valid during the first month of WEARERA's launch.
2. The 50 first sellers who registered during that first month are eligible.
3. Each eligible seller gets their FIRST transaction with 0% fee.
4. Starting from their 2nd transaction, the 8% fee applies.
5. After the first month ends, the promo ends permanently.
6. If 50 sellers are reached before the end of the month, subsequent sellers are not eligible.
7. The promo benefits the SELLER, not the buyer.

## New Function: is_seller_eligible_for_promo

Parameters:
- p_seller_id uuid — the seller's user ID

Returns: boolean — true if the seller is eligible for 0% fee on their first transaction

Logic:
- The launch period is defined as 30 days from the earliest user registration.
- Count users who registered before this seller, up to 50.
- If the seller is within the first 50 registrants AND within the launch period, return true.
- Otherwise return false.

## Security
- SECURITY DEFINER so it can read auth.users.
- Read-only: only queries, no mutations.

## Important Notes
1. This function only checks ELIGIBILITY — the actual fee waiver also requires that it's the seller's first transaction.
2. The caller must check if the seller has prior orders to determine if this is their first transaction.
3. The 8% fee calculation remains unchanged for non-eligible sellers.
*/

CREATE OR REPLACE FUNCTION public.is_seller_eligible_for_promo(p_seller_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, public
AS $$
DECLARE
    v_seller_created_at timestamptz;
    v_launch_start timestamptz;
    v_launch_end timestamptz;
    v_seller_rank integer;
BEGIN
    -- Get the seller's registration date
    SELECT created_at INTO v_seller_created_at
    FROM auth.users
    WHERE id = p_seller_id;

    IF v_seller_created_at IS NULL THEN
        RETURN false;
    END IF;

    -- The launch period starts at the earliest user registration
    SELECT min(created_at) INTO v_launch_start
    FROM auth.users;

    IF v_launch_start IS NULL THEN
        RETURN false;
    END IF;

    -- Launch period: 30 days from the first registration
    v_launch_end := v_launch_start + INTERVAL '30 days';

    -- Seller must have registered during the launch period
    IF v_seller_created_at > v_launch_end THEN
        RETURN false;
    END IF;

    -- Count how many users registered before this seller (including themselves)
    -- to determine if they are within the first 50
    SELECT count(*) INTO v_seller_rank
    FROM auth.users
    WHERE created_at <= v_seller_created_at;

    -- Must be within the first 50 registrants
    IF v_seller_rank > 50 THEN
        RETURN false;
    END IF;

    RETURN true;
END;
$$;
