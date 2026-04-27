#!/usr/bin/env bash
# Restaura un backup local de Supabase generado con ./backup.sh
# Uso:   ./restore_from_backup.sh backups/2026-04-27_12-00
#
# CUIDADO: hace upsert por id. Si las tablas ya tienen datos con esos
# mismos id, los sobrescribe. Si tienen datos NUEVOS no los borra.

set -e
cd "$(dirname "$0")"

URL='https://yptwguwsjudnsgoovrhd.supabase.co'
KEY='sb_publishable_sNL29U6i0bqa0c2srS-klA_8cI341kZ'

DIR="$1"
if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  echo "Uso: $0 <carpeta-de-backup>"
  echo "Ejemplo: $0 backups/2026-04-27_12-00"
  echo
  echo "Backups disponibles:"
  ls -d backups/*/ 2>/dev/null || echo "  (no hay backups en esta carpeta)"
  exit 1
fi

echo "→ Restaurando desde $DIR/"
read -p "  ¿Seguro que quieres restaurar? (escribe 'si' para continuar): " ANS
if [ "$ANS" != "si" ]; then
  echo "Cancelado."
  exit 0
fi

# Orden importante: padres antes que hijos por las foreign keys
for TABLE in clients properties projects activities expenses; do
  FILE="$DIR/$TABLE.json"
  if [ ! -f "$FILE" ]; then
    echo "  ⚠ $TABLE — falta el archivo $FILE, salto"
    continue
  fi
  COUNT=$(python3 -c "import json;print(len(json.load(open('$FILE'))))")
  printf "  %-12s ... " "$TABLE"
  if [ "$COUNT" = "0" ]; then
    echo "vacio, salto"
    continue
  fi
  STATUS=$(curl -s -o /tmp/restore_$TABLE.log -w '%{http_code}' -X POST \
    "$URL/rest/v1/$TABLE" \
    -H "apikey: $KEY" -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: resolution=merge-duplicates,return=minimal" \
    --data @"$FILE")
  if [ "$STATUS" = "201" ] || [ "$STATUS" = "200" ]; then
    echo "✓ $COUNT filas"
  else
    echo "✗ HTTP $STATUS — $(head -c 200 /tmp/restore_$TABLE.log)"
  fi
done

echo
echo "✓ Restauracion completa. Recarga el CRM con Cmd+Shift+R."
