-- =====================================================================
--  Migracion: precio de venta en proyectos propios
--
--  En proyectos propios (compro terreno, construyo y vendo) se necesita
--  separar dos cosas:
--    - budget_usd      = coste estimado de construccion
--    - sale_price_usd  = precio de venta esperado (revenue)
--
--  El margen real = sale_price - (precio terreno + admin terreno + gastos obra)
--
--  Idempotente: puedes ejecutarla varias veces sin romper nada.
-- =====================================================================

alter table projects
  add column if not exists sale_price_usd numeric(12,2) default 0;

-- comentario en la columna para que se vea en el panel de Supabase
comment on column projects.sale_price_usd is
  'Precio de venta esperado para proyectos propios. En proyectos de cliente, dejar 0 (el revenue es budget_usd).';
