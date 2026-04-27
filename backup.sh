#!/usr/bin/env bash
# Descarga un snapshot de todas las tablas de Supabase a JSON local.
# Uso:   ./backup.sh
# Crea un backup en backups/AAAA-MM-DD_HH-MM/ con un fichero por tabla.

set -e
cd "$(dirname "$0")"

URL='https://yptwguwsjudnsgoovrhd.supabase.co'
KEY='sb_publishable_sNL29U6i0bqa0c2srS-klA_8cI341kZ'

STAMP=$(date +'%Y-%m-%d_%H-%M')
DIR="backups/$STAMP"
mkdir -p "$DIR"

echo "→ Backup en $DIR/"

for TABLE in clients properties projects activities expenses; do
  printf "  %-12s ... " "$TABLE"
  STATUS=$(curl -s -o "$DIR/$TABLE.json" -w '%{http_code}' \
    "$URL/rest/v1/$TABLE?select=*" \
    -H "apikey: $KEY" -H "Authorization: Bearer $KEY")
  if [ "$STATUS" = "200" ]; then
    COUNT=$(python3 -c "import json;print(len(json.load(open('$DIR/$TABLE.json'))))" 2>/dev/null || echo '?')
    echo "✓ $COUNT filas"
  else
    echo "✗ HTTP $STATUS"
  fi
done

echo
echo "✓ Backup completo en: $(pwd)/$DIR"
echo
echo "Para restaurar (desde la carpeta del backup):"
echo "  ./restore_from_backup.sh $DIR"
