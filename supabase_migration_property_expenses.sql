-- =====================================================================
--  Migracion: permitir asociar gastos a un terreno (no solo a un proyecto)
--
--  Cambios:
--   - expenses.project_id pasa a ser nullable
--   - se anade expenses.property_id (nullable, FK a properties)
--   - CHECK: cada gasto debe estar vinculado a UN proyecto o UN terreno
--   - indice en property_id
--
--  Ejecuta este script en el SQL Editor de Supabase. Es idempotente,
--  puedes correrlo dos veces sin problema.
-- =====================================================================

begin;

-- 1) project_id nullable
alter table expenses alter column project_id drop not null;

-- 2) property_id nuevo
alter table expenses
  add column if not exists property_id uuid references properties(id) on delete cascade;

-- 3) CHECK: al menos uno de los dos (no ambos null)
alter table expenses drop constraint if exists expenses_target_check;
alter table expenses add constraint expenses_target_check
  check (project_id is not null or property_id is not null);

-- 4) indice
create index if not exists expenses_property_id_idx on expenses (property_id, spent_on desc);

commit;

-- Verificacion: estructura actualizada
select column_name, data_type, is_nullable
from information_schema.columns
where table_name = 'expenses'
order by ordinal_position;
