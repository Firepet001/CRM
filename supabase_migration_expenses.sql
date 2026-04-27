-- =====================================================================
--  Migracion incremental: añade la tabla `expenses` al CRM
--  Si ya tenias el esquema base creado, ejecuta SOLO este archivo.
--  Si vas a recrear todo desde cero, usa supabase_schema.sql en su lugar.
-- =====================================================================

-- 1) Tipos enumerados nuevos (idempotente) ----------------------------
do $$ begin
  if not exists (select 1 from pg_type where typname = 'expense_category') then
    create type expense_category as enum ('materiales','mano_obra','transporte','permisos','subcontratos','equipos','otros');
  end if;
  if not exists (select 1 from pg_type where typname = 'expense_status') then
    create type expense_status as enum ('pendiente','pagado');
  end if;
end $$;

-- 2) Tabla de gastos --------------------------------------------------
create table if not exists expenses (
  id           uuid primary key default gen_random_uuid(),
  project_id   uuid not null references projects(id) on delete cascade,
  category     expense_category not null default 'materiales',
  description  text not null,
  vendor       text,
  amount_usd   numeric(12,2) not null default 0,
  status       expense_status not null default 'pendiente',
  spent_on     date not null default current_date,
  paid_on      date,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists expenses_project_id_idx on expenses (project_id, spent_on desc);
create index if not exists expenses_category_idx   on expenses (category);
create index if not exists expenses_status_idx     on expenses (status);

-- 3) Trigger updated_at (reusa la funcion ya existente) --------------
drop trigger if exists trg_expenses_updated on expenses;
create trigger trg_expenses_updated before update on expenses
  for each row execute function set_updated_at();

-- 4) Row Level Security ----------------------------------------------
alter table expenses enable row level security;
drop policy if exists "anon_all_expenses" on expenses;
create policy "anon_all_expenses" on expenses for all using (true) with check (true);

-- 5) Datos de ejemplo (opcional) -------------------------------------
-- Solo inserta si la tabla esta vacia.
do $$
declare cnt int;
begin
  select count(*) into cnt from expenses;
  if cnt = 0 then
    insert into expenses (project_id, category, description, vendor, amount_usd, status, spent_on, paid_on)
    select id, 'materiales'::expense_category,  'Cemento Holcim 50kg x 200 sacos', 'Distribuidora Loja',     1850.00, 'pagado'::expense_status,    current_date - 18, current_date - 17 from projects where code='P-2026-001'
    union all select id, 'mano_obra'::expense_category,   'Cuadrilla maestro + 3 oficiales', 'Maestro Edgar Cuenca',  2400.00, 'pagado'::expense_status,    current_date - 12, current_date - 10 from projects where code='P-2026-001'
    union all select id, 'materiales'::expense_category,  'Hierro corrugado 12mm 4 ton',     'Aceria del Ecuador',   3200.00, 'pendiente'::expense_status, current_date - 6,  null              from projects where code='P-2026-001'
    union all select id, 'transporte'::expense_category,  'Volqueta material petreo',        'Transportes Vilca',     420.00, 'pagado'::expense_status,    current_date - 8,  current_date - 7  from projects where code='P-2026-001'
    union all select id, 'permisos'::expense_category,    'Permiso construccion municipal',  'GAD Loja',              280.00, 'pagado'::expense_status,    current_date - 30, current_date - 30 from projects where code='P-2026-001'
    union all select id, 'subcontratos'::expense_category,'Instalacion electrica',           'Electricos del Sur',    980.00, 'pendiente'::expense_status, current_date - 4,  null              from projects where code='P-2026-001'
    union all select id, 'mano_obra'::expense_category,   'Demolicion tabiques',             'Cuadrilla Carlos',      650.00, 'pagado'::expense_status,    current_date - 3,  current_date - 2  from projects where code='P-2026-002'
    union all select id, 'materiales'::expense_category,  'Pintura interior 25 gal',         'Pinturas Cesa',         320.00, 'pendiente'::expense_status, current_date - 1,  null              from projects where code='P-2026-002'
    union all select id, 'permisos'::expense_category,    'Estudio de suelos',               'Geotecnia Andina',      850.00, 'pagado'::expense_status,    current_date - 22, current_date - 21 from projects where code='P-2026-003'
    union all select id, 'mano_obra'::expense_category,   'Topografia',                      'Ing. Patricio Salinas', 480.00, 'pagado'::expense_status,    current_date - 18, current_date - 17 from projects where code='P-2026-003'
    union all select id, 'materiales'::expense_category,  'Acabados ceramica',               'Graiman',              4200.00, 'pagado'::expense_status,    current_date - 9,  current_date - 7  from projects where code='P-2026-004'
    union all select id, 'subcontratos'::expense_category,'Carpinteria de aluminio',         'AluVidrio Loja',       2900.00, 'pendiente'::expense_status, current_date - 5,  null              from projects where code='P-2026-004'
    union all select id, 'equipos'::expense_category,     'Alquiler andamios 2 semanas',     'Andamios del Sur',      380.00, 'pagado'::expense_status,    current_date - 11, current_date - 10 from projects where code='P-2026-004'
    union all select id, 'mano_obra'::expense_category,   'Replanteo y excavacion',          'Cuadrilla Edgar',       780.00, 'pagado'::expense_status,    current_date - 14, current_date - 13 from projects where code='P-2026-007'
    union all select id, 'otros'::expense_category,       'Honorarios estructural',          'Ing. Andres Vivanco',   950.00, 'pendiente'::expense_status, current_date - 7,  null              from projects where code='P-2026-007';
  end if;
end $$;
