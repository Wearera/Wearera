CREATE OR REPLACE FUNCTION public.create_test_user(
  p_email text,
  p_password text,
  p_first_name text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, public, extensions
AS $$
DECLARE
  v_user_id uuid;
  v_encrypted text;
BEGIN
  v_encrypted := extensions.crypt(p_password, extensions.gen_salt('bf', 10));
  
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    raw_app_meta_data,
    created_at,
    updated_at,
    last_sign_in_at
  )
  VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    p_email,
    v_encrypted,
    now(),
    jsonb_build_object('first_name', p_first_name),
    '{}'::jsonb,
    now(),
    now(),
    now()
  )
  RETURNING id INTO v_user_id;
  
  INSERT INTO auth.identities (
    provider_id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  )
  VALUES (
    v_user_id::text,
    v_user_id,
    jsonb_build_object(
      'sub', v_user_id::text,
      'email', p_email,
      'email_verified', true
    ),
    'email',
    now(),
    now(),
    now()
  );
  
  INSERT INTO public.profiles (id, first_name)
  VALUES (v_user_id, p_first_name)
  ON CONFLICT (id) DO NOTHING;
  
  INSERT INTO public.public_profiles (id, first_name)
  VALUES (v_user_id, p_first_name)
  ON CONFLICT (id) DO NOTHING;
  
  RETURN v_user_id;
END;
$$;
