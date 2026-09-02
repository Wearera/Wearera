-- Create profile for the existing user who was created without one
INSERT INTO profiles (id, first_name)
SELECT id, (raw_user_meta_data->>'first_name')::text
FROM auth.users
WHERE NOT EXISTS (
    SELECT 1 FROM profiles p WHERE p.id = auth.users.id
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public_profiles (id, first_name)
SELECT id, (raw_user_meta_data->>'first_name')::text
FROM auth.users
WHERE NOT EXISTS (
    SELECT 1 FROM public_profiles p WHERE p.id = auth.users.id
)
ON CONFLICT (id) DO NOTHING;
