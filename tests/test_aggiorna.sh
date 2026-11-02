#!/bin/sh
# rkaggiorna: senza rete deve dirlo e uscire; sintassi bash corretta.
set -e
DIR=$(cd "$(dirname "$0")/.." && pwd)
bash -n "$DIR/strumenti/rkaggiorna"
out=$(env -u DISPLAY http_proxy=http://127.0.0.1:9 https_proxy=http://127.0.0.1:9 HTTPS_PROXY=http://127.0.0.1:9 \
      bash "$DIR/strumenti/rkaggiorna" 2>&1 || true)
printf '%s\n' "$out" | grep -q "Nessuna connessione" || { echo "manca messaggio offline"; printf '%s\n' "$out"; exit 1; }
echo "OK aggiorna"
