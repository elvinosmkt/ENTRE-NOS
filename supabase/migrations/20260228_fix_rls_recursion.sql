-- =============================================
-- CORREÇÃO: Recursão Infinita nas RLS Policies
-- Execute no SQL Editor do Supabase:
-- https://supabase.com/dashboard/project/lrqbzkgbvegwcyxwakac/sql/new
-- =============================================

-- 1. Remover policies problemáticas com recursão
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;

-- 2. Criar novas policies SEM recursão
-- Qualquer usuário autenticado pode LER perfis (necessário para busca por invite_code)
CREATE POLICY "profiles_select_all" ON public.profiles FOR SELECT
USING (true);

-- Usuários só podem ATUALIZAR seu próprio perfil
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Usuários só podem INSERIR seu próprio perfil
CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- 3. Criar função RPC para conectar parceiros (SECURITY DEFINER = bypassa RLS)
CREATE OR REPLACE FUNCTION public.connect_partners(p_partner_code TEXT)
RETURNS JSON AS $$
DECLARE
  v_current_user_id UUID;
  v_partner_id UUID;
BEGIN
  v_current_user_id := auth.uid();
  
  IF v_current_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  SELECT p.id INTO v_partner_id
  FROM public.profiles p
  WHERE p.invite_code = UPPER(p_partner_code);
  
  IF v_partner_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Partner not found');
  END IF;
  
  IF v_partner_id = v_current_user_id THEN
    RETURN json_build_object('success', false, 'error', 'Cannot connect with yourself');
  END IF;
  
  UPDATE public.profiles SET partner_id = v_partner_id, updated_at = NOW()
  WHERE id = v_current_user_id;
  
  UPDATE public.profiles SET partner_id = v_current_user_id, updated_at = NOW()
  WHERE id = v_partner_id;
  
  RETURN json_build_object(
    'success', true, 
    'partner_id', v_partner_id,
    'message', 'Connected successfully'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
