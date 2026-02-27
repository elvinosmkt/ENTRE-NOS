-- 1. Tabela de Perfis
-- Esta tabela armazena informações extras dos usuários e lida com a conexão do casal.
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  display_name text,
  avatar_url text,
  partner_id uuid references public.profiles(id),
  updated_at timestamp with time zone default now()
);

-- Habilitar Row Level Security (RLS)
alter table public.profiles enable row level security;

-- Política: Usuários podem ver seu próprio perfil e o do parceiro
create policy "Usuários podem ver seu próprio perfil e o do parceiro"
on public.profiles for select
using (
  auth.uid() = id or 
  auth.uid() = partner_id or
  id in (select partner_id from public.profiles where id = auth.uid())
);

-- 2. Tabela de Desenhos
-- Armazena o histórico de artes trocadas.
create table public.drawings (
  id uuid default uuid_generate_v4() primary key,
  sender_id uuid references public.profiles(id) not null,
  recipient_id uuid references public.profiles(id) not null,
  image_url text not null,
  created_at timestamp with time zone default now()
);

-- Habilitar RLS
alter table public.drawings enable row level security;

-- Política: Usuários podem ver desenhos que enviaram ou receberam
create policy "Usuários podem ver seus próprios desenhos"
on public.drawings for select
using (auth.uid() = sender_id or auth.uid() = recipient_id);

-- Política: Usuários podem inserir novos desenhos
create policy "Usuários podem enviar desenhos"
on public.drawings for insert
with check (auth.uid() = sender_id);

-- 3. Storage Bucket
-- Certifique-se de criar um bucket chamado 'app_assets' no painel do Supabase
-- e definir como PÚBLICO para simplificar o acesso às imagens.
