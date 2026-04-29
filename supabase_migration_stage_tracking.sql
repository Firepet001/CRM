-- =====================================================================
--  Migracion: dias en etapa automaticos
--
--  Anade stage_changed_at en projects. Un trigger lo actualiza solo
--  cada vez que cambia la etapa. El frontend calcula los dias en
--  etapa = hoy - stage_changed_at.
--
--  Asi:
--   - days_in_stage NO se rellena a mano nunca mas.
--   - Cada movimiento de etapa (drag&drop o boton) reinicia a 0.
--
--  Idempotente.
-- =====================================================================

-- 1) Columna nueva
alter table projects
  add column if not exists stage_changed_at timestamptz default now();

-- 2) Para proyectos antiguos sin valor: usar created_at
update projects
   set stage_changed_at = coalesce(stage_changed_at, created_at)
 where stage_changed_at is null;

-- 3) Trigger: cuando cambia stage, actualizar stage_changed_at = now()
create or replace function update_stage_changed_at() returns trigger as $$
begin
  if old.stage is distinct from new.stage then
    new.stage_changed_at = now();
  end if;
  return new;
end; $$ language plpgsql;

drop trigger if exists trg_projects_stage_changed on projects;
create trigger trg_projects_stage_changed
  before update on projects
  for each row execute function update_stage_changed_at();

-- 4) Indice para filtrados rapidos por antiguedad en etapa
create index if not exists projects_stage_changed_idx
  on projects (stage_changed_at desc);
