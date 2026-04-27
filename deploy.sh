#!/usr/bin/env bash
# Inicializa el repo (si hace falta), commitea cambios y los sube a GitHub.
# Uso: ./deploy.sh
#
# Requiere git autenticado con GitHub (token en Keychain, gh auth login,
# o ssh keys configuradas).

set -e
cd "$(dirname "$0")"

REPO_URL="https://github.com/Firepet001/CRM.git"

# 1) Limpiar cualquier .git parcial que pudiera haber quedado de un intento previo.
if [ -d .git ] && ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "→ Detecté un .git parcial — lo elimino para empezar limpio…"
  rm -rf .git
fi

# 2) Inicializar repo si no existe.
if [ ! -d .git ]; then
  echo "→ Inicializando repo git en branch 'main'…"
  git init -b main
  git config user.name  "$(git config --global user.name  || echo 'Pedro Cardenas')"
  git config user.email "$(git config --global user.email || echo 'pedro.cardenas@ineriamanagement.com')"
  git remote add origin "$REPO_URL"
fi

# 3) Si por algun motivo no esta el remote, lo anado.
if ! git remote get-url origin > /dev/null 2>&1; then
  git remote add origin "$REPO_URL"
fi

# 4) Anadir + commit (si hay cambios).
echo "→ Anadiendo archivos…"
git add .

if git diff --cached --quiet; then
  echo "  (sin cambios para commitear)"
else
  MSG="${1:-deploy $(date +'%Y-%m-%d %H:%M')}"
  git commit -m "$MSG"
  echo "  ✓ commit creado: $MSG"
fi

# 5) Push.
echo "→ Subiendo a GitHub…"
git push -u origin main

cat <<'EOF'

✓ Subido. Si es la primera vez, abre:
   https://github.com/Firepet001/CRM/settings/pages

Y selecciona:
   Source: Deploy from a branch
   Branch: main · /(root)  → Save

En ~1 minuto estara disponible en:
   https://Firepet001.github.io/CRM/

Para futuras actualizaciones, basta con volver a ejecutar este script:
   ./deploy.sh "tu mensaje de commit"
EOF
