-- =====================================================================
--  Limpieza de datos demo del CRM
--  Borra TODOS los registros de ejemplo (clientes, proyectos, terrenos,
--  actividades y gastos) dejando las tablas vacias y listas para empezar
--  con datos reales.
--
--  La estructura (tablas, enums, RLS, indices) se conserva intacta.
--  Solo desaparecen los datos.
--
--  IMPORTANTE: si ya has registrado datos reales mezclados con los demo,
--  no ejecutes este script tal cual — bórralos uno a uno desde la app
--  o filtra antes con un WHERE especifico.
-- =====================================================================

begin;

-- Orden importante: hijos antes que padres por las foreign keys.
delete from expenses;
delete from activities;
delete from projects;
delete from properties;
delete from clients;

commit;

-- Verificacion: las 5 tablas deben mostrar 0 filas.
select 'clients'    as tabla, count(*) as filas from clients
union all select 'projects',   count(*) from projects
union all select 'properties', count(*) from properties
union all select 'activities', count(*) from activities
union all select 'expenses',   count(*) from expenses;
