-- =====================================================================
--  Migracion: numero de factura y descripcion ampliada en gastos
--
--  - invoice_number: texto opcional. Si esta vacio, el gasto se considera
--    "sin factura" (util para gastos pequenos sin comprobante formal).
--  - notes: descripcion ampliada opcional (notas, detalles, observaciones).
--
--  Idempotente: puedes ejecutarlo varias veces sin romper nada.
-- =====================================================================

alter table expenses
  add column if not exists invoice_number text,
  add column if not exists notes          text;

-- indice para filtrado rapido de gastos sin factura
create index if not exists expenses_no_invoice_idx
  on expenses ((invoice_number is null or invoice_number = ''));
