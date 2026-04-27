# CRM Constructora · Loja, Ecuador

CRM dark-mode estilo PEDRA, adaptado al negocio de construcción (proyectos propios y de clientes), conectado a Supabase y publicable en GitHub Pages.

URL final esperada: **https://Firepet001.github.io/CRM/**

## Pantallas

- **Dashboard** — KPIs (revenue contratado, proyectos activos, gastos acumulados, tasa de cierre), tendencia mensual, próximas actividades, tabla de proyectos recientes.
- **Clientes** — Lista con búsqueda, filtros por estado (lead/prospect/customer) y columnas ordenables.
- **Pipeline** — Kanban de 6 etapas con drag & drop (Prospección → Visita/Terreno → Anteproyecto → Presupuesto → Contrato/Obra → Entrega).
- **Detalle de cliente** — Ficha + lista de proyectos con barra **Presupuesto vs Gastado vs Margen** + timeline de actividades.
- **Terrenos** — Inventario de lotes para proyectos propios (compra-construcción-venta).
- **Gastos** — Panel global con KPIs (total gastado, pagado, pendiente, % sobre presupuesto), distribución por categoría, top proyectos por coste, tabla con filtros por categoría/estado/proyecto y botón rápido para marcar como pagado.
- **Modal Nuevo proyecto** y **Modal Nuevo gasto** — Formularios para registrar oportunidades y costes.

### Categorías de gasto

`Materiales`, `Mano de obra`, `Transporte`, `Permisos / Honorarios`, `Subcontratos`, `Equipos`, `Otros`.

Diseño 100% basado en la guía visual de PEDRA: fondo `#080808`, dorado `#FAC51C`, blanco `#F5F5F5`, superficies `#111`/`#1A1A1A`, tipografía Inter + JetBrains Mono. Web responsive con bottom-nav en móvil.

## Stack

- HTML/CSS/JS vanilla — sin build, un solo `index.html`.
- `@supabase/supabase-js` v2 vía CDN.
- Sin dependencias de servidor — funciona en GitHub Pages.

## Modo demo

Si abres `index.html` antes de configurar Supabase, la app detecta que no hay conexión y arranca automáticamente en **modo demo** con datos de ejemplo en memoria. Verás un banner ámbar arriba ("Modo demo — sin Supabase") y todas las pantallas funcionan, incluyendo crear proyectos y mover tarjetas en el Kanban — pero los cambios no se guardan al recargar.

Esto te permite ver la app funcionando inmediatamente, mientras configuras Supabase con calma.

## Setup paso a paso

### 1) Crear el proyecto Supabase (gratis, ~3 min)

1. Entra en https://supabase.com/dashboard y pulsa **New project**.
2. Nombre: `crm-loja` (o el que prefieras).
3. **Database password**: crea una fuerte y guárdala.
4. **Region**: `South America (São Paulo)` — la más cercana a Loja.
5. Espera ~2 min a que termine de aprovisionar.

### 2) Crear las tablas

1. En tu nuevo proyecto, ve a **SQL Editor → New query**.
2. Pega el contenido completo de [`supabase_schema.sql`](./supabase_schema.sql) y pulsa **Run**.

Esto crea las tablas (`clients`, `properties`, `projects`, `activities`, `expenses`), tipos enumerados, RLS y datos de ejemplo realistas para Loja.

> **Si ya creaste antes solo las tablas base** (sin `expenses`), no vuelvas a ejecutar `supabase_schema.sql` (te borraría los datos). En su lugar ejecuta solo [`supabase_migration_expenses.sql`](./supabase_migration_expenses.sql), que añade la tabla de gastos sin tocar las anteriores.

### 3) Conectar la app

1. En Supabase, ve a **Project Settings → API**.
2. Copia los dos valores:
   - **Project URL** (ej. `https://abc123xyz.supabase.co`)
   - **Project API keys → anon public**
3. Edita `index.html` y reemplaza:
   ```js
   const SUPABASE_URL  = 'https://...tu-url...supabase.co';
   const SUPABASE_KEY  = '...tu-anon-key...';
   ```
4. Recarga la página — el banner amarillo desaparecerá y verás los datos reales.

### 4) Probar en local

```bash
cd CRM
python3 -m http.server 8080
# abre http://localhost:8080
```

O simplemente haz doble click en `index.html`.

### 5) Publicar en GitHub Pages

```bash
# Desde la carpeta del proyecto
git init -b main
git add .
git commit -m "Inicial: CRM constructora Loja"
git remote add origin https://github.com/Firepet001/CRM.git
git push -u origin main
```

Luego en GitHub:

1. Ve a **Settings → Pages**.
2. **Source**: `Deploy from a branch`.
3. **Branch**: `main` · `/ (root)` → **Save**.
4. Espera ~1 min y abre `https://Firepet001.github.io/CRM/`.

> El archivo `.nojekyll` está incluido para que GitHub Pages no procese el sitio con Jekyll.

## Notas de seguridad / RGPD / RLS

- La key incluida es de tipo `sb_publishable_…` (anon key) — pensada para clientes web. Por sí sola no da privilegios elevados.
- **El esquema activa Row Level Security en todas las tablas** y por ahora la política es abierta (`using (true) with check (true)`) para que el equipo entre directamente. Cuando incorpores Supabase Auth, sustituye esas policies por reglas basadas en `auth.role()` o `auth.uid()`.
- Los datos de ejemplo son ficticios. Cuando cargues clientes reales, asegúrate de tener su consentimiento (RGPD/LOPD/equivalente Ecuador — Ley Orgánica de Protección de Datos Personales) y un aviso de privacidad accesible.

## Cambiar credenciales

Edita `index.html` y modifica:

```js
const SUPABASE_URL = 'https://pjhyqpinpebddwohuhqq.supabase.co';
const SUPABASE_KEY = 'sb_publishable_KIr1up5DRZT9XN8V8GOCJg_yAxTpyXn';
```

## Estructura

```
CRM/
├── index.html           # SPA completa (UI + lógica)
├── supabase_schema.sql  # Esquema de BD + datos de ejemplo
├── .nojekyll            # Evita procesado Jekyll en GH Pages
└── README.md
```
