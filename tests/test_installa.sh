#!/bin/sh
# Prova completa dell'installatore, come sul telefono, contro una copia locale del repo:
#  1) installa tutto  2) rkaggiorna dice "gia' aggiornato"  3) un file rovinato non cambia niente
#  4) rkdisinstalla toglie tutto e lascia le impostazioni.
# Scrive in /usr/local: si lancia in CI (o in una macchina di prova), con root o sudo.
set -e
DIR=$(cd "$(dirname "$0")/.." && pwd)
[ "$(id -u)" = 0 ] || command -v sudo >/dev/null || { echo "salto: serve root o sudo"; exit 0; }
SRV=$(mktemp -d); H=$(mktemp -d)
cp -r "$DIR/." "$SRV/"
PORTA=$((20000 + $$ % 20000))
( cd "$SRV" && exec python3 -m http.server "$PORTA" --bind 127.0.0.1 >/dev/null 2>&1 ) &
PID=$!
trap 'kill $PID 2>/dev/null; rm -rf "$SRV" "$H"' EXIT
sleep 1
export RK_SALTA_APT="${RK_SALTA_APT:-0}" HOME="$H" RK_REPO="http://127.0.0.1:$PORTA" NO_PROXY=127.0.0.1 no_proxy=127.0.0.1
unset DISPLAY
mkdir -p "$H/Desktop"

# 1) installazione completa
out=$(sh "$SRV/install.sh" 2>&1) || { printf '%s\n' "$out"; echo "FALLITO: installazione"; exit 1; }
printf '%s\n' "$out" | grep -q "installato ==" || { printf '%s\n' "$out"; exit 1; }
for t in touchpad unavolta pulizia runnerboost rkterminale rkcollaudo rkbackup rkitaliano rkaggiorna rkcentro rkdisinstalla rkavvio; do
  [ -x "/usr/local/bin/$t" ] || { echo "FALLITO: manca $t"; exit 1; }
done
[ "$(cat /usr/local/share/runnerkit/versione)" = "$(tr -d '[:space:]' < "$DIR/VERSIONE")" ] || { echo "FALLITO: versione"; exit 1; }
[ -f "$H/Desktop/runnerkit-centro.desktop" ] && grep -q "RunnerKit Terminale inizio" "$H/.bashrc"
grep -q "Exec=/usr/local/bin/rkavvio" "$H/.local/share/dbus-1/services/org.a11y.Bus.service" || { echo "FALLITO: servizio D-Bus di avvio"; exit 1; }
# rkavvio deve finire subito (D-Bus aspetta la sua uscita prima di rispondere ai programmi del desktop)
inizio=$(date +%s); HOME="$H" RKAVVIO_TP=/nessuno /usr/local/bin/rkavvio || true; [ $(( $(date +%s) - inizio )) -le 2 ] || { echo "FALLITO: rkavvio lento"; exit 1; }
[ ! -d /tmp/runnerkit-installa.lock ] || { echo "FALLITO: blocco rimasto"; exit 1; }
echo "ok: installazione completa"

# 2) nessuna novita' -> "gia' aggiornato", senza reinstallare
out=$(bash /usr/local/bin/rkaggiorna 2>&1)
printf '%s\n' "$out" | grep -q "gia' aggiornato" || { printf '%s\n' "$out"; echo "FALLITO: rkaggiorna"; exit 1; }
echo "ok: rkaggiorna dice gia' aggiornato"

# 3) versione nuova ma con un file rovinato: si ferma e non tocca niente
prima=$(md5sum /usr/local/bin/touchpad)
echo "2099.01.01-1" > "$SRV/VERSIONE"
echo "def rotto(:" >> "$SRV/strumenti/rkcentro"
if sh "$SRV/install.sh" >/dev/null 2>&1; then echo "FALLITO: installato con un file rovinato"; exit 1; fi
[ "$(md5sum /usr/local/bin/touchpad)" = "$prima" ] || { echo "FALLITO: file cambiati dopo un errore"; exit 1; }
[ "$(cat /usr/local/share/runnerkit/versione)" != "2099.01.01-1" ] || { echo "FALLITO: versione scritta dopo un errore"; exit 1; }
echo "ok: file rovinato -> nessuna modifica"

# 3b) risposta HTML (rete con pagina di accesso): nessuna modifica
cp "$DIR/strumenti/rkcentro" "$SRV/strumenti/rkcentro"
echo "<html>login</html>" > "$SRV/VERSIONE"
if sh "$SRV/install.sh" >/dev/null 2>&1; then echo "FALLITO: accettata una versione HTML"; exit 1; fi
echo "ok: pagina HTML al posto della versione -> nessuna modifica"

# 4) disinstalla
mkdir -p "$H/.config/runnerkit"; echo x > "$H/.config/runnerkit/prova"
/usr/local/bin/rkdisinstalla --si >/dev/null
for t in touchpad rkcentro rkdisinstalla; do [ ! -e "/usr/local/bin/$t" ] || { echo "FALLITO: $t rimasto"; exit 1; }; done
[ ! -f "$H/Desktop/runnerkit-centro.desktop" ] && ! grep -q "RunnerKit Terminale" "$H/.bashrc"
[ ! -f "$H/.local/share/dbus-1/services/org.a11y.Bus.service" ] || { echo "FALLITO: servizio D-Bus rimasto"; exit 1; }
[ -f "$H/.config/runnerkit/prova" ] || { echo "FALLITO: impostazioni cancellate senza --tutto"; exit 1; }
echo "ok: disinstalla"
echo "OK installa"
