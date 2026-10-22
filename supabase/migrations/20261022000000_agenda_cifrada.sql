-- Agenda Fisio: almacén de agendas CIFRADAS.
-- El servidor solo guarda texto cifrado. No conoce contraseñas, nombres ni datos de pacientes.
-- Pegar entero en Supabase → SQL Editor → Run.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.vaults (
  id          text primary key check (id ~ '^[0-9a-f]{64}$'),
  token_hash  text not null,
  data        text not null check (length(data) <= 30000000),
  version     integer not null default 1,
  updated_at  timestamptz not null default now()
);

-- Nadie puede leer ni escribir la tabla directamente; solo a través de las funciones de abajo.
alter table public.vaults enable row level security;
revoke all on table public.vaults from public;
do $$ begin
  if exists (select 1 from pg_roles where rolname = 'anon') then
    execute 'revoke all on table public.vaults from anon, authenticated';
  end if;
end $$;

-- Leer una agenda (hace falta conocer su id, que solo se obtiene a partir de la contraseña).
create or replace function public.vault_get(p_id text)
returns table (data text, version integer)
language sql stable security definer set search_path = public
as $$ select v.data, v.version from public.vaults v where v.id = p_id $$;

-- Consultar si hay cambios, sin descargar la agenda.
create or replace function public.vault_version(p_id text)
returns integer
language sql stable security definer set search_path = public
as $$ select v.version from public.vaults v where v.id = p_id $$;

-- Guardar. p_expected = versión sobre la que se hizo el cambio (0 = agenda nueva).
-- Errores: 'conflict' (otro dispositivo guardó antes), 'missing' (la agenda ya no existe), 'forbidden'.
create or replace function public.vault_put(p_id text, p_token text, p_data text, p_expected integer)
returns integer
language plpgsql security definer set search_path = public
as $$
declare
  v public.vaults;
  h text := encode(extensions.digest(p_token, 'sha256'), 'hex');
begin
  select * into v from public.vaults where id = p_id for update;
  if not found then
    if coalesce(p_expected, 0) <> 0 then raise exception 'missing'; end if;
    insert into public.vaults (id, token_hash, data) values (p_id, h, p_data);
    return 1;
  end if;
  if v.token_hash <> h then raise exception 'forbidden'; end if;
  if p_expected is distinct from v.version then raise exception 'conflict'; end if;
  update public.vaults set data = p_data, version = v.version + 1, updated_at = now() where id = p_id;
  return v.version + 1;
exception when unique_violation then
  raise exception 'conflict';
end $$;

-- Borrar (se usa al cambiar la contraseña, después de guardar con la nueva).
create or replace function public.vault_delete(p_id text, p_token text)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  delete from public.vaults
  where id = p_id and token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex');
end $$;

revoke all on function public.vault_get(text), public.vault_version(text),
  public.vault_put(text, text, text, integer), public.vault_delete(text, text) from public;
do $$ begin
  if exists (select 1 from pg_roles where rolname = 'anon') then
    execute 'grant execute on function public.vault_get(text), public.vault_version(text), public.vault_put(text, text, text, integer), public.vault_delete(text, text) to anon, authenticated';
  end if;
end $$;
