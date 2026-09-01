/*
# Create storage buckets for WEARERA

## Summary
Creates two storage buckets:
- `avatars` — for user profile photos (public read, authenticated write)
- `articles-photos` — for article listing photos (public read, authenticated write)

## Security
- Both buckets are public-readable (anyone can view photos)
- Only authenticated users can upload
- Users can only upload to their own folder (user_id/)
- Users can only delete their own files
*/

INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('articles-photos', 'articles-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Avatars: public read
DROP POLICY IF EXISTS "avatars_public_read" ON storage.objects;
CREATE POLICY "avatars_public_read" ON storage.objects
    FOR SELECT TO anon, authenticated
    USING (bucket_id = 'avatars');

-- Avatars: authenticated upload to own folder
DROP POLICY IF EXISTS "avatars_auth_upload" ON storage.objects;
CREATE POLICY "avatars_auth_upload" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Avatars: owner can update/delete
DROP POLICY IF EXISTS "avatars_owner_update" ON storage.objects;
CREATE POLICY "avatars_owner_update" ON storage.objects
    FOR UPDATE TO authenticated
    USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text)
    WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "avatars_owner_delete" ON storage.objects;
CREATE POLICY "avatars_owner_delete" ON storage.objects
    FOR DELETE TO authenticated
    USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Articles-photos: public read
DROP POLICY IF EXISTS "articles_photos_public_read" ON storage.objects;
CREATE POLICY "articles_photos_public_read" ON storage.objects
    FOR SELECT TO anon, authenticated
    USING (bucket_id = 'articles-photos');

-- Articles-photos: authenticated upload to own folder
DROP POLICY IF EXISTS "articles_photos_auth_upload" ON storage.objects;
CREATE POLICY "articles_photos_auth_upload" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'articles-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Articles-photos: owner can delete
DROP POLICY IF EXISTS "articles_photos_owner_delete" ON storage.objects;
CREATE POLICY "articles_photos_owner_delete" ON storage.objects
    FOR DELETE TO authenticated
    USING (bucket_id = 'articles-photos' AND (storage.foldername(name))[1] = auth.uid()::text);