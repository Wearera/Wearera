/*
# Create WEARERA database tables

## Summary
Creates all tables needed for the WEARERA second-hand fashion marketplace:
- Articles (products listed for sale)
- conversations (buyer-seller chat threads)
- messages (individual chat messages)
- profiles (private user profile data)
- public_profiles (public-facing profile data)

## New Tables

### Articles
- `id` (uuid, primary key)
- `name` (text, not null) — article name
- `category` (text, not null) — Vêtements / Chaussures / Sacs / Accessoires
- `brand` (text) — brand name
- `size` (text) — clothing size
- `shoe_size` (text) — shoe size
- `price` (numeric, not null) — price in CAD
- `condition` (text, not null) — Neuf or 1-5 rating
- `defects` (text) — description of defects
- `description` (text) — article description
- `province` (text, not null) — Canadian province code
- `city` (text, not null) — city name
- `photo_urls` (jsonb) — array of photo URLs
- `seller_id` (uuid, not null) — references auth.users
- `created_at` (timestamptz) — creation timestamp

### conversations
- `id` (uuid, primary key)
- `article_id` (uuid, references Articles)
- `buyer_id` (uuid, references auth.users)
- `seller_id` (uuid, references auth.users)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)

### messages
- `id` (uuid, primary key)
- `conversation_id` (uuid, references conversations)
- `sender_id` (uuid, references auth.users)
- `message` (text, not null)
- `is_read` (boolean, default false)
- `created_at` (timestamptz)

### profiles
- `id` (uuid, primary key, references auth.users)
- `first_name` (text)
- `city` (text)
- `province` (text)
- `avatar_url` (text)
- `updated_at` (timestamptz)

### public_profiles
- `id` (uuid, primary key, references auth.users)
- `first_name` (text)
- `city` (text)
- `province` (text)
- `avatar_url` (text)
- `updated_at` (timestamptz)

## Security
- RLS enabled on all tables
- Articles: anyone can read; only seller can insert/update/delete their own
- conversations: both buyer and seller can read; buyer can create; both can update
- messages: conversation participants can read; any participant can insert; sender can update read status
- profiles: owner can read/update; public read for public_profiles
- All policies use auth.uid() for ownership checks
*/

-- Articles table
CREATE TABLE IF NOT EXISTS "Articles" (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    category text NOT NULL,
    brand text,
    size text,
    shoe_size text,
    price numeric NOT NULL DEFAULT 0,
    condition text NOT NULL,
    defects text,
    description text,
    province text NOT NULL,
    city text NOT NULL,
    photo_urls jsonb DEFAULT '[]'::jsonb,
    seller_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE "Articles" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_articles" ON "Articles";
CREATE POLICY "select_articles" ON "Articles" FOR SELECT
    TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "insert_own_articles" ON "Articles";
CREATE POLICY "insert_own_articles" ON "Articles" FOR INSERT
    TO authenticated WITH CHECK (auth.uid() = seller_id);

DROP POLICY IF EXISTS "update_own_articles" ON "Articles";
CREATE POLICY "update_own_articles" ON "Articles" FOR UPDATE
    TO authenticated USING (auth.uid() = seller_id) WITH CHECK (auth.uid() = seller_id);

DROP POLICY IF EXISTS "delete_own_articles" ON "Articles";
CREATE POLICY "delete_own_articles" ON "Articles" FOR DELETE
    TO authenticated USING (auth.uid() = seller_id);

-- conversations table
CREATE TABLE IF NOT EXISTS conversations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id uuid REFERENCES "Articles"(id) ON DELETE CASCADE,
    buyer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    seller_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_conversations" ON conversations;
CREATE POLICY "select_conversations" ON conversations FOR SELECT
    TO authenticated USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

DROP POLICY IF EXISTS "insert_conversations" ON conversations;
CREATE POLICY "insert_conversations" ON conversations FOR INSERT
    TO authenticated WITH CHECK (auth.uid() = buyer_id);

DROP POLICY IF EXISTS "update_conversations" ON conversations;
CREATE POLICY "update_conversations" ON conversations FOR UPDATE
    TO authenticated USING (auth.uid() = buyer_id OR auth.uid() = seller_id)
    WITH CHECK (auth.uid() = buyer_id OR auth.uid() = seller_id);

DROP POLICY IF EXISTS "delete_conversations" ON conversations;
CREATE POLICY "delete_conversations" ON conversations FOR DELETE
    TO authenticated USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- messages table
CREATE TABLE IF NOT EXISTS messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message text NOT NULL,
    is_read boolean NOT NULL DEFAULT false,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_messages" ON messages;
CREATE POLICY "select_messages" ON messages FOR SELECT
    TO authenticated USING (
        EXISTS (
            SELECT 1 FROM conversations c
            WHERE c.id = messages.conversation_id
            AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "insert_messages" ON messages;
CREATE POLICY "insert_messages" ON messages FOR INSERT
    TO authenticated WITH CHECK (
        EXISTS (
            SELECT 1 FROM conversations c
            WHERE c.id = messages.conversation_id
            AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
            AND messages.sender_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "update_messages" ON messages;
CREATE POLICY "update_messages" ON messages FOR UPDATE
    TO authenticated USING (
        EXISTS (
            SELECT 1 FROM conversations c
            WHERE c.id = messages.conversation_id
            AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM conversations c
            WHERE c.id = messages.conversation_id
            AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
        )
    );

-- profiles table (private user profile)
CREATE TABLE IF NOT EXISTS profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name text,
    city text,
    province text,
    avatar_url text,
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_profile" ON profiles;
CREATE POLICY "select_own_profile" ON profiles FOR SELECT
    TO authenticated USING (auth.uid() = id);

DROP POLICY IF EXISTS "insert_own_profile" ON profiles;
CREATE POLICY "insert_own_profile" ON profiles FOR INSERT
    TO authenticated WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "update_own_profile" ON profiles;
CREATE POLICY "update_own_profile" ON profiles FOR UPDATE
    TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- public_profiles table (public-facing profile)
CREATE TABLE IF NOT EXISTS public_profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name text,
    city text,
    province text,
    avatar_url text,
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE public_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_public_profiles" ON public_profiles;
CREATE POLICY "select_public_profiles" ON public_profiles FOR SELECT
    TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "insert_own_public_profile" ON public_profiles;
CREATE POLICY "insert_own_public_profile" ON public_profiles FOR INSERT
    TO authenticated WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "update_own_public_profile" ON public_profiles;
CREATE POLICY "update_own_public_profile" ON public_profiles FOR UPDATE
    TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_articles_seller_id ON "Articles"(seller_id);
CREATE INDEX IF NOT EXISTS idx_articles_created_at ON "Articles"(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_buyer_id ON conversations(buyer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_seller_id ON conversations(seller_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

-- Enable realtime for messages table
ALTER TABLE messages REPLICA IDENTITY FULL;
ALTER TABLE conversations REPLICA IDENTITY FULL;