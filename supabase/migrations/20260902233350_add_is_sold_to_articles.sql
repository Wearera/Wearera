/*
# Add is_sold column to Articles table

## Purpose
Marks articles as sold so they can be hidden from the marketplace
and blocked from being added to cart or purchased again.

## Changes
- Added column: is_sold (boolean, NOT NULL DEFAULT false) on "Articles" table.
- No existing columns modified or deleted. No data lost.
*/

ALTER TABLE "Articles" ADD COLUMN IF NOT EXISTS is_sold boolean NOT NULL DEFAULT false;
