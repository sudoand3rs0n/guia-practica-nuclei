#!/usr/bin/env bash
#
# pipeline.sh — Encadena subfinder -> httpx -> nuclei para un flujo de
# reconocimiento y escaneo básico (ver labs/ejecucion.md para el detalle paso a paso).
#
# Uso:
#   ./pipeline.sh <dominio_o_ip> [directorio_salida]
#
# Ejemplos:
#   ./pipeline.sh target.local
#   ./pipeline.sh 192.168.56.20 resultados_lab
#
# Requisitos: subfinder, httpx y nuclei instalados y en el PATH.
# Ver docs/instalacion.md para instrucciones de instalación.

set -euo pipefail

TARGET="${1:-}"
OUTDIR="${2:-resultados_$(date +%Y%m%d_%H%M%S)}"

if [[ -z "$TARGET" ]]; then
  echo "Uso: $0 <dominio_o_ip> [directorio_salida]"
  exit 1
fi

for bin in subfinder httpx nuclei; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "[!] '$bin' no encontrado en el PATH. Consulta docs/instalacion.md"
    exit 1
  fi
done

mkdir -p "$OUTDIR"
echo "[*] Resultados en: $OUTDIR"

# 1. Enumeración (se omite automáticamente si el target es una IP)
SUBS_FILE="$OUTDIR/subdominios.txt"
if [[ "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "[*] Target es una IP, se omite subfinder."
  echo "$TARGET" > "$SUBS_FILE"
else
  echo "[*] Fase 1/4 - Enumeración con subfinder..."
  subfinder -d "$TARGET" -o "$SUBS_FILE" -silent
fi

# 2. Filtrado de activos vivos
LIVE_FILE="$OUTDIR/vivos.txt"
echo "[*] Fase 2/4 - Filtrado de activos vivos con httpx..."
httpx -l "$SUBS_FILE" -silent -status-code -title -tech-detect -o "$LIVE_FILE"

# httpx añade metadata al final de la línea; extraemos solo la URL para nuclei
URLS_FILE="$OUTDIR/urls_para_nuclei.txt"
awk '{print $1}' "$LIVE_FILE" > "$URLS_FILE"

# 3. Escaneo inicial amplio
echo "[*] Fase 3/4 - Escaneo inicial (amplio) con nuclei..."
nuclei -l "$URLS_FILE" -tags tech,panel,exposure,default-login \
  -jsonl -o "$OUTDIR/recon_inicial.jsonl" -stats

# 4. Escaneo dirigido a vulnerabilidades comunes y CVEs
echo "[*] Fase 4/4 - Escaneo dirigido con nuclei..."
nuclei -l "$URLS_FILE" -tags cve,sqli,xss,lfi,rce -s critical,high,medium \
  -jsonl -o "$OUTDIR/dirigido.jsonl" -stats

echo "[*] Pipeline completado."
echo "[*] Recuerda: los resultados de nuclei son hallazgos candidatos."
echo "[*] Confirma cada uno con -debug (o una plantilla propia si hace falta) antes de documentarlos en labs/hallazgos.md"
