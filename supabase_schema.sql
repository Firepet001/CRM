-- =====================================================================
--  CRM CONSTRUCTORA LOJA — esquema Supabase
--  Pega este SQL completo en el SQL Editor de Supabase y ejecutalo.
--  Crea las tablas, indices, RLS y datos de ejemplo.
-- =====================================================================

-- 1) Limpieza opcional (reejecucion idempotente) ----------------------
drop table if exists expenses   cascade;
drop table if exists activities cascade;
drop table if exists projects   cascade;
drop table if exists properties cascade;
drop table if exists clients    cascade;
drop type  if exists client_status    cascade;
drop type  if exists project_stage    cascade;
drop type  if exists project_kind     cascade;
drop type  if exists activity_type    cascade;
drop type  if exists property_status  cascade;
drop type  if exists expense_category cascade;
drop type  if exists expense_status   cascade;

-- 2) Tipos enumerados -------------------------------------------------
create type client_status    as enum ('lead','prospect','customer');
create type project_stage    as enum ('prospeccion','visita','anteproyecto','presupuesto','contrato','entrega');
create type project_kind     as enum ('propio','cliente');
create type activity_type    as enum ('llamada','reunion','email','whatsapp','visita_obra','nota','tarea');
create type property_status  as enum ('disponible','en_negociacion','adquirido','vendido');
create type expense_category as enum ('materiales','mano_obra','transporte','permisos','subcontratos','equipos','otros');
create type expense_status   as enum ('pendiente','pagado');

-- 3) Tablas -----------------------------------------------------------

-- Clientes (leads / prospectos / clientes finales)
create table clients (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  company       text,
  email         text,
  phone         text,
  status        client_status not null default 'lead',
  city          text default 'Loja',
  source        text,             -- de donde llego (referido, web, anuncio...)
  notes         text,
  owner         text,             -- ej: 'pedro', 'residente', 'estudiante'
  total_value   numeric default 0,
  last_activity timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Terrenos / propiedades para proyectos propios
create table properties (
  id           uuid primary key default gen_random_uuid(),
  code         text unique,             -- ej: T-001
  title        text not null,           -- ej: 'Terreno Av. Pio Jaramillo'
  address      text,
  sector       text,                    -- barrio / sector de Loja
  area_m2      numeric,
  price_usd    numeric,
  status       property_status not null default 'disponible',
  notes        text,
  created_at   timestamptz not null default now()
);

-- Proyectos (oportunidades + obras)
create table projects (
  id             uuid primary key default gen_random_uuid(),
  code           text unique,             -- ej: P-2026-001
  title          text not null,           -- ej: 'Casa San Cayetano'
  kind           project_kind not null,   -- propio / cliente
  client_id      uuid references clients(id) on delete set null,
  property_id    uuid references properties(id) on delete set null,
  service        text,                    -- 'Vivienda', 'Edificio residencial', 'Local comercial', 'Remodelacion'
  stage          project_stage not null default 'prospeccion',
  budget_usd     numeric default 0,       -- presupuesto / valor del proyecto
  area_m2        numeric,
  start_date     date,
  end_date       date,
  due_date       date,
  days_in_stage  int default 0,
  progress       int default 0,           -- 0-100 % avance fisico
  notes          text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- Gastos (costes de obra por proyecto)
create table expenses (
  id           uuid primary key default gen_random_uuid(),
  project_id   uuid not null references projects(id) on delete cascade,
  category     expense_category not null default 'materiales',
  description  text not null,
  vendor       text,                    -- proveedor
  amount_usd   numeric(12,2) not null default 0,
  status       expense_status not null default 'pendiente',
  spent_on     date not null default current_date,
  paid_on      date,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- Actividades (timeline)
create table activities (
  id          uuid primary key default gen_random_uuid(),
  client_id   uuid references clients(id) on delete cascade,
  project_id  uuid references projects(id) on delete set null,
  type        activity_type not null,
  title       text not null,
  body        text,
  author      text,                       -- pedro / residente / estudiante
  occurred_at timestamptz not null default now(),
  created_at  timestamptz not null default now()
);

-- 4) Indices ----------------------------------------------------------
create index on clients   (status);
create index on clients   (last_activity desc);
create index on projects  (stage);
create index on projects  (client_id);
create index on projects  (kind);
create index on activities(client_id, occurred_at desc);
create index on activities(project_id, occurred_at desc);
create index on expenses  (project_id, spent_on desc);
create index on expenses  (category);
create index on expenses  (status);

-- 5) Trigger de updated_at -------------------------------------------
create or replace function set_updated_at() returns trigger as $$
begin new.updated_at = now(); return new; end; $$ language plpgsql;

create trigger trg_clients_updated  before update on clients  for each row execute function set_updated_at();
create trigger trg_projects_updated before update on projects for each row execute function set_updated_at();
create trigger trg_expenses_updated before update on expenses for each row execute function set_updated_at();

-- 6) Row Level Security ----------------------------------------------
-- Para empezar abrimos lectura/escritura con la anon key (uso interno
-- del equipo). Cuando anadas Supabase Auth, sustituye 'true' por
-- 'auth.role() = ''authenticated''' o por una policy basada en user_id.

alter table clients    enable row level security;
alter table properties enable row level security;
alter table projects   enable row level security;
alter table activities enable row level security;
alter table expenses   enable row level security;

create policy "anon_all_clients"    on clients    for all using (true) with check (true);
create policy "anon_all_properties" on properties for all using (true) with check (true);
create policy "anon_all_projects"   on projects   for all using (true) with check (true);
create policy "anon_all_activities" on activities for all using (true) with check (true);
create policy "anon_all_expenses"   on expenses   for all using (true) with check (true);

-- 7) Datos de ejemplo (Loja, Ecuador, USD) ---------------------------

insert into clients (name, company, email, phone, status, city, source, owner, total_value, last_activity, notes) values
  ('Maria Jimenez',     'Particular',                'maria.jimenez@gmail.com',   '+593 99 812 4471', 'customer', 'Loja',     'Referido',  'pedro',     185000, now() - interval '2 days',  'Cliente recurrente, casa en San Cayetano entregada 2025.'),
  ('Carlos Andrade',    'Andrade & Hijos',           'carlos@andradehijos.ec',    '+593 98 712 9930', 'prospect', 'Loja',     'Web',       'pedro',      72000, now() - interval '4 days',  'Quiere remodelar local comercial en centro.'),
  ('Lucia Ortega',      'Particular',                'lucia.ortega@hotmail.com',  '+593 98 444 2210', 'lead',     'Loja',     'Anuncio FB','estudiante',     0, now() - interval '1 days',  'Interesada en duplex en Pio Jaramillo.'),
  ('Familia Vivanco',   'Particular',                'jvivanco@yahoo.com',        '+593 99 220 1188', 'customer', 'Catamayo', 'Referido',  'pedro',     310000, now() - interval '7 days',  'Casa de campo en Catamayo, fase acabados.'),
  ('Inmobiliaria Sur',  'Inmobiliaria Sur S.A.',     'gerencia@inmosur.ec',       '+593 7 257 4400',  'prospect', 'Loja',     'B2B',       'pedro',     520000, now() - interval '10 days', 'Posible alianza para edificio en La Tebaida.'),
  ('Diego Cuenca',      'Particular',                'diego.cuenca@outlook.com',  '+593 96 117 3320', 'lead',     'Loja',     'Instagram', 'residente',      0, now() - interval '3 days',  'Joven profesional, busca primer departamento.'),
  ('Veronica Pineda',   'Particular',                'vpineda@gmail.com',         '+593 99 558 7720', 'prospect', 'Loja',     'Referido',  'pedro',     145000, now() - interval '5 days',  'Solicito anteproyecto vivienda 2 plantas.'),
  ('Roberto Tinoco',    'Constructora Tinoco Cia.',  'rtinoco@tinoco.com.ec',     '+593 7 258 1820',  'customer', 'Loja',     'B2B',       'pedro',     480000, now() - interval '14 days', 'Subcontrato hidrosanitario edificio Norte.');

insert into properties (code, title, address, sector, area_m2, price_usd, status, notes) values
  ('T-001', 'Terreno Av. Pio Jaramillo',     'Av. Pio Jaramillo y Manuelita Saenz', 'Pio Jaramillo', 320,  78000, 'adquirido',     'Esquinero, listo para duplex.'),
  ('T-002', 'Lote Sector San Cayetano',      'Calle Bolivar s/n',                   'San Cayetano',  450, 105000, 'en_negociacion','Pendiente firma escritura.'),
  ('T-003', 'Quinta Catamayo',               'Via a Catamayo km 9',                 'Catamayo',      820,  62000, 'disponible',    'Zona residencial campestre.'),
  ('T-004', 'Lote La Tebaida',               'Av. Eduardo Kingman',                 'La Tebaida',    600, 132000, 'disponible',    'Apto para edificio 4 plantas.');

-- helpers para datos
do $$
declare
  c_maria   uuid; c_carlos uuid; c_lucia  uuid; c_vivanco uuid;
  c_inmosur uuid; c_diego  uuid; c_vero   uuid; c_robe    uuid;
  t_pio     uuid; t_sanc   uuid; t_cata   uuid; t_teba    uuid;
begin
  select id into c_maria   from clients where name='Maria Jimenez';
  select id into c_carlos  from clients where name='Carlos Andrade';
  select id into c_lucia   from clients where name='Lucia Ortega';
  select id into c_vivanco from clients where name='Familia Vivanco';
  select id into c_inmosur from clients where name='Inmobiliaria Sur';
  select id into c_diego   from clients where name='Diego Cuenca';
  select id into c_vero    from clients where name='Veronica Pineda';
  select id into c_robe    from clients where name='Roberto Tinoco';

  select id into t_pio  from properties where code='T-001';
  select id into t_sanc from properties where code='T-002';
  select id into t_cata from properties where code='T-003';
  select id into t_teba from properties where code='T-004';

  insert into projects (code, title, kind, client_id, property_id, service, stage, budget_usd, area_m2, due_date, days_in_stage, progress, notes) values
    ('P-2026-001', 'Duplex Pio Jaramillo',          'propio',  null,      t_pio,  'Vivienda',           'contrato',    185000, 240, current_date + interval '60 days', 4,  35, 'Proyecto propio, en fase obra gris.'),
    ('P-2026-002', 'Remodelacion Local Andrade',    'cliente', c_carlos,  null,   'Remodelacion',       'presupuesto',  72000,  140, current_date + interval '20 days', 6,  0,  'Esperando aprobacion del presupuesto.'),
    ('P-2026-003', 'Casa San Cayetano',             'propio',  null,      t_sanc, 'Vivienda',           'anteproyecto', 220000, 310, current_date + interval '90 days', 8,  10, 'Diseno en revision con cliente potencial.'),
    ('P-2026-004', 'Casa de campo Vivanco',         'cliente', c_vivanco, null,   'Vivienda',           'contrato',    310000, 420, current_date + interval '45 days', 12, 70, 'Acabados, falta jardineria y carpinteria.'),
    ('P-2026-005', 'Edificio La Tebaida (alianza)', 'propio',  c_inmosur, t_teba, 'Edificio residencial','prospeccion', 1200000, 0,  current_date + interval '180 days', 2, 0, 'Reunion de alianza programada.'),
    ('P-2026-006', 'Departamento centro',           'cliente', c_diego,   null,   'Vivienda',           'visita',        85000,   95, current_date + interval '30 days', 1,  0, 'Visita al sitio agendada.'),
    ('P-2026-007', 'Vivienda 2 plantas Pineda',     'cliente', c_vero,    null,   'Vivienda',           'anteproyecto', 145000, 200, current_date + interval '40 days', 5,  5, 'Bocetos enviados, pendiente feedback.'),
    ('P-2026-008', 'Hidrosanitario Edif. Norte',    'cliente', c_robe,    null,   'Subcontrato',        'entrega',     480000,   0, current_date - interval '5 days',  0, 100, 'Entregado, pendiente acta final.');

  -- Actividades de muestra
  insert into activities (client_id, project_id, type, title, body, author, occurred_at)
  select c_maria, (select id from projects where code='P-2026-001'), 'reunion'::activity_type, 'Revision de avance obra',
         'Visita semanal con Maria. Aprobado el cambio de mamparas de aluminio a PVC.',
         'pedro', now() - interval '2 days'
  union all select c_maria, (select id from projects where code='P-2026-001'), 'visita_obra'::activity_type,'Vaciado de losa segunda planta','Hormigonado completado, curado en proceso.','residente', now() - interval '5 days'
  union all select c_carlos, (select id from projects where code='P-2026-002'),'email'::activity_type,'Envio de presupuesto v2','Adjunto desglose por partidas, IVA 12%.','pedro', now() - interval '4 days'
  union all select c_lucia, null, 'whatsapp'::activity_type,'Primer contacto','Pregunta por duplex en Pio Jaramillo, le envio fotos.','estudiante', now() - interval '1 days'
  union all select c_vivanco,(select id from projects where code='P-2026-004'),'visita_obra'::activity_type,'Inspeccion de acabados','Falta corregir juntas en pisos zona social.','residente', now() - interval '6 days'
  union all select c_vero,  (select id from projects where code='P-2026-007'),'reunion'::activity_type,'Presentacion de bocetos','Cliente pide ampliar dormitorio principal.','pedro', now() - interval '3 days'
  union all select c_robe,  (select id from projects where code='P-2026-008'),'tarea'::activity_type,'Acta de entrega','Coordinar firma del acta con director de obra.','pedro', now() - interval '1 days'
  union all select c_diego, (select id from projects where code='P-2026-006'),'llamada'::activity_type,'Confirmacion visita','Visita confirmada para el sabado 10am.','residente', now() - interval '2 days';

  -- Gastos de obra por proyecto
  insert into expenses (project_id, category, description, vendor, amount_usd, status, spent_on, paid_on)
  select id, 'materiales'::expense_category,  'Cemento Holcim 50kg x 200 sacos', 'Distribuidora Loja',     1850.00, 'pagado'::expense_status,    current_date - 18, current_date - 17 from projects where code='P-2026-001'
  union all select id, 'mano_obra'::expense_category,   'Cuadrilla maestro + 3 oficiales', 'Maestro Edgar Cuenca',  2400.00, 'pagado'::expense_status,    current_date - 12, current_date - 10 from projects where code='P-2026-001'
  union all select id, 'materiales'::expense_category,  'Hierro corrugado 12mm 4 ton',   'Aceria del Ecuador',     3200.00, 'pendiente'::expense_status, current_date - 6,  null              from projects where code='P-2026-001'
  union all select id, 'transporte'::expense_category,  'Volqueta material petreo',       'Transportes Vilca',      420.00,  'pagado'::expense_status,    current_date - 8,  current_date - 7  from projects where code='P-2026-001'
  union all select id, 'permisos'::expense_category,    'Permiso construccion municipal', 'GAD Loja',               280.00,  'pagado'::expense_status,    current_date - 30, current_date - 30 from projects where code='P-2026-001'
  union all select id, 'subcontratos'::expense_category,'Instalacion electrica',          'Electricos del Sur',     980.00,  'pendiente'::expense_status, current_date - 4,  null              from projects where code='P-2026-001'
  union all select id, 'mano_obra'::expense_category,   'Demolicion tabiques',            'Cuadrilla Carlos',       650.00,  'pagado'::expense_status,    current_date - 3,  current_date - 2  from projects where code='P-2026-002'
  union all select id, 'materiales'::expense_category,  'Pintura interior 25 gal',        'Pinturas Cesa',          320.00,  'pendiente'::expense_status, current_date - 1,  null              from projects where code='P-2026-002'
  union all select id, 'permisos'::expense_category,    'Estudio de suelos',              'Geotecnia Andina',       850.00,  'pagado'::expense_status,    current_date - 22, current_date - 21 from projects where code='P-2026-003'
  union all select id, 'mano_obra'::expense_category,   'Topografia',                     'Ing. Patricio Salinas',  480.00,  'pagado'::expense_status,    current_date - 18, current_date - 17 from projects where code='P-2026-003'
  union all select id, 'materiales'::expense_category,  'Acabados ceramica',              'Graiman',               4200.00,  'pagado'::expense_status,    current_date - 9,  current_date - 7  from projects where code='P-2026-004'
  union all select id, 'subcontratos'::expense_category,'Carpinteria de aluminio',        'AluVidrio Loja',        2900.00,  'pendiente'::expense_status, current_date - 5,  null              from projects where code='P-2026-004'
  union all select id, 'equipos'::expense_category,     'Alquiler andamios 2 semanas',    'Andamios del Sur',       380.00,  'pagado'::expense_status,    current_date - 11, current_date - 10 from projects where code='P-2026-004'
  union all select id, 'mano_obra'::expense_category,   'Replanteo y excavacion',         'Cuadrilla Edgar',        780.00,  'pagado'::expense_status,    current_date - 14, current_date - 13 from projects where code='P-2026-007'
  union all select id, 'otros'::expense_category,       'Honorarios estructural',         'Ing. Andres Vivanco',    950.00,  'pendiente'::expense_status, current_date - 7,  null              from projects where code='P-2026-007';
end $$;
