-- =====================================================================
--  Migracion: tabla de proveedores + vinculo desde expenses
--
--  Idempotente: puedes ejecutarlo varias veces sin romper nada.
-- =====================================================================

begin;

-- 1) Tabla vendors -------------------------------------------------
create table if not exists vendors (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  contact_name text,                  -- persona de contacto
  phone        text,
  email        text,
  address      text,
  ruc          text,                  -- RUC / cedula del proveedor
  category     text,                  -- materiales, mano_obra, transporte, etc.
  notes        text,
  active       boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists vendors_name_idx     on vendors (lower(name));
create index if not exists vendors_active_idx   on vendors (active) where active;
create index if not exists vendors_category_idx on vendors (category);

-- trigger updated_at (reusa la funcion existente)
drop trigger if exists trg_vendors_updated on vendors;
create trigger trg_vendors_updated before update on vendors
  for each row execute function set_updated_at();

-- RLS
alter table vendors enable row level security;
drop policy if exists "anon_all_vendors" on vendors;
create policy "anon_all_vendors" on vendors for all using (true) with check (true);

-- 2) Vinculo expenses -> vendors ----------------------------------
alter table expenses
  add column if not exists vendor_id uuid references vendors(id) on delete set null;

create index if not exists expenses_vendor_id_idx on expenses (vendor_id);

-- Mantenemos la columna 'vendor' (text) para retrocompatibilidad y
-- como fallback cuando no hay vendor_id (ej. proveedor puntual sin alta).

commit;
