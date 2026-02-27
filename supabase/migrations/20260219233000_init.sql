-- =============================================
-- EntreNós — Supabase Schema V2 (Completo)
-- =============================================

-- 1. Profiles Table
-- Armazena dados dos usuários e seus parceiros
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  display_name TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  invite_code TEXT UNIQUE NOT NULL,
  partner_id UUID REFERENCES public.profiles(id),
  push_token TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Usuários podem ver seu próprio perfil e o do parceiro
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT
USING (
  auth.uid() = id
  OR auth.uid() = partner_id
  OR id IN (SELECT partner_id FROM public.profiles WHERE id = auth.uid())
);

-- Usuários podem atualizar seu próprio perfil
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Usuários podem inserir seu próprio perfil
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id);


-- 2. Drawings Table
-- Armazena registros de desenhos enviados
CREATE TABLE IF NOT EXISTS public.drawings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID REFERENCES public.profiles(id) NOT NULL,
  recipient_id UUID REFERENCES public.profiles(id) NOT NULL,
  image_url TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.drawings ENABLE ROW LEVEL SECURITY;

-- Usuários podem ver desenhos enviados e recebidos
CREATE POLICY "drawings_select" ON public.drawings FOR SELECT
USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

-- Usuários podem inserir desenhos como remetente
CREATE POLICY "drawings_insert" ON public.drawings FOR INSERT
WITH CHECK (auth.uid() = sender_id);

-- Destinatário pode marcar como lido
CREATE POLICY "drawings_update" ON public.drawings FOR UPDATE
USING (auth.uid() = recipient_id)
WITH CHECK (auth.uid() = recipient_id);


-- 3. Notifications Table
-- Armazena notificações para o parceiro
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type TEXT NOT NULL DEFAULT 'new_drawing',
  sender_id UUID REFERENCES public.profiles(id) NOT NULL,
  recipient_id UUID REFERENCES public.profiles(id) NOT NULL,
  drawing_id UUID REFERENCES public.drawings(id),
  message TEXT,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_select" ON public.notifications FOR SELECT
USING (auth.uid() = recipient_id);

CREATE POLICY "notifications_insert" ON public.notifications FOR INSERT
WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "notifications_update" ON public.notifications FOR UPDATE
USING (auth.uid() = recipient_id);


-- 4. Storage Bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('drawings', 'drawings', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "drawings_storage_upload" ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'drawings' 
  AND auth.uid() IS NOT NULL
);

CREATE POLICY "drawings_storage_select" ON storage.objects FOR SELECT
USING (bucket_id = 'drawings');


-- 5. Function to auto-create notification on new drawing
CREATE OR REPLACE FUNCTION public.handle_new_drawing()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notifications (type, sender_id, recipient_id, drawing_id, message)
  VALUES (
    'new_drawing',
    NEW.sender_id,
    NEW.recipient_id,
    NEW.id,
    'Novo carinho enviado! ❤️'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_drawing_created
  AFTER INSERT ON public.drawings
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_drawing();


-- 6. Function to generate unique invite code
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT AS $$
DECLARE
  code TEXT;
  exists BOOLEAN;
BEGIN
  LOOP
    code := upper(substr(md5(random()::text), 1, 6));
    SELECT EXISTS(SELECT 1 FROM public.profiles WHERE invite_code = code) INTO exists;
    EXIT WHEN NOT exists;
  END LOOP;
  RETURN code;
END;
$$ LANGUAGE plpgsql;


-- 7. Enable Realtime for drawings and notifications
ALTER PUBLICATION supabase_realtime ADD TABLE public.drawings;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
