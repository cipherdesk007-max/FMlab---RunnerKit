#!/bin/sh
# Test di Backup, Italiano e Collaudo.
set -e
DIR=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d)
export RKB_HOME="$T/home" RKB_SHARED="$T/shared" RKI_HOME="$T/home" RKI_SALTA_APT=1
mkdir -p "$RKB_HOME/.config/runnerboost" "$RKB_HOME/Desktop" "$RKB_SHARED" "$RKB_HOME/.mozilla/firefox/x.default-esr"
echo '{"theme":"blu"}' > "$RKB_HOME/.config/touchpad.json"
echo nota > "$RKB_HOME/Desktop/nota.txt"
mkdir -p "$RKB_HOME/progetti"; echo extra > "$RKB_HOME/progetti/extra.txt"

# backup -> modifica -> ripristino
B="$DIR/strumenti/rkbackup"
HOME="$RKB_HOME" "$B" --aggiungi "$RKB_HOME/progetti" >/dev/null
HOME="$RKB_HOME" "$B" | grep -q "Backup creato"
f=$(ls "$RKB_SHARED"/RunnerKit-backup/backup-*.tar.gz)
tar -tzf "$f" | grep -q "Desktop/nota.txt"
tar -tzf "$f" | grep -q ".config/touchpad.json"
tar -tzf "$f" | grep -q "pacchetti-debian.txt"
tar -tzf "$f" | grep -q "progetti/extra.txt"
echo cambiato > "$RKB_HOME/Desktop/nota.txt"
HOME="$RKB_HOME" "$B" --ripristina "$f" --si </dev/null | grep -q "Ripristinato"
[ "$(cat "$RKB_HOME/Desktop/nota.txt")" = nota ] || { echo "ripristino fallito"; exit 1; }
ls "$RKB_SHARED"/RunnerKit-backup/ | grep -q sicurezza || { echo "manca copia di sicurezza"; exit 1; }
for i in 1 2 3 4 5 6 7; do HOME="$RKB_HOME" "$B" >/dev/null; sleep 1; done
[ "$(ls "$RKB_SHARED"/RunnerKit-backup/backup-*.tar.gz | grep -vc sicurezza)" -le 5 ] || { echo "rotazione non funziona"; exit 1; }
echo "ok: backup / ripristino / rotazione"

# italiano (senza apt nei test)
I="$DIR/strumenti/rkitaliano"
HOME="$RKI_HOME" "$I" --on >/dev/null 2>&1 || true
grep -q it_IT "$RKI_HOME/.config/runnerkit/lingua"
grep -q 'intl.locale.requested' "$RKI_HOME/.mozilla/firefox/x.default-esr/user.js"
HOME="$RKI_HOME" "$I" --off >/dev/null 2>&1 || true
[ ! -f "$RKI_HOME/.config/runnerkit/lingua" ]
! grep -q 'intl.locale.requested' "$RKI_HOME/.mozilla/firefox/x.default-esr/user.js"
echo "ok: italiano on/off"

# collaudo: deve girare fino in fondo e salvare il report
mkdir -p "$T/home/Shared"
PATH="$DIR/strumenti:$DIR/unavolta:$DIR/pulizia:$DIR/runnerboost:$PATH" HOME="$T/home" sh "$DIR/strumenti/rkcollaudo" > "$T/coll.txt" 2>&1 || true
grep -q "Risultato" "$T/coll.txt"
ls "$T/home/Shared"/runnerkit-collaudo-*.txt >/dev/null
echo "ok: collaudo (report salvato)"

# terminale: barra fissa e comandi rk nuovi
out=$(HOME="$T/home" bash --norc -i -c ". '$DIR/terminale/terminale.sh'; _rk_riga1; echo; rk; type _rk_fisso >/dev/null && echo FISSO" 2>&1)
printf '%s\n' "$out" | grep -q "RunnerKit" && printf '%s\n' "$out" | grep -q "RAM" && printf '%s\n' "$out" | grep -q "FISSO"
printf '%s\n' "$out" | grep -q "rk collaudo"
echo "ok: barra fissa e comandi"
rm -rf "$T"
echo "OK strumenti"
