#!/bin/sh
# Test di Pulizia: cancella solo le categorie sicure, mai i file personali.
set -e
DIR=$(cd "$(dirname "$0")/.." && pwd)
P="$DIR/pulizia/pulizia"
T=$(mktemp -d)
export PULIZIA_ROOT="$T/root" PULIZIA_HOME="$T/home"
R="$PULIZIA_ROOT"; H="$PULIZIA_HOME"
mkdir -p "$R/var/cache/apt/archives/partial" "$R/var/log/apt" "$R/tmp" "$R/var/tmp" "$R/var/crash" \
         "$H/.cache/mesa" "$H/.local/share/Trash/files" "$H/Documenti" "$H/Desktop" "$H/Shared"

# roba da pulire
head -c 300000 /dev/zero > "$R/var/cache/apt/archives/pippo.deb"
head -c 200000 /dev/zero > "$H/.cache/mesa/shader.bin"
echo x > "$H/.local/share/Trash/files/vecchio.txt"
echo x > "$R/var/log/syslog.1"; echo x > "$R/var/log/apt/history.log.1.gz"
echo x > "$R/tmp/vecchio"; touch -d '10 days ago' "$R/tmp/vecchio"
echo x > "$R/tmp/nuovo"
mkdir "$R/tmp/.X11-unix"; touch -d '10 days ago' "$R/tmp/.X11-unix"
# roba personale che NON deve sparire
echo importante > "$H/Documenti/contratto.txt"
echo importante > "$H/Desktop/nota.txt"
echo importante > "$H/Shared/foto.jpg"
echo importante > "$R/var/log/syslog"

"$P" --prova | grep -q "PROVA"
[ -f "$R/var/cache/apt/archives/pippo.deb" ] || { echo "FALLITO: --prova ha cancellato"; exit 1; }

"$P" --sicura
for f in "$R/var/cache/apt/archives/pippo.deb" "$H/.cache/mesa/shader.bin" \
         "$H/.local/share/Trash/files/vecchio.txt" "$R/var/log/syslog.1" \
         "$R/var/log/apt/history.log.1.gz" "$R/tmp/vecchio"; do
  [ ! -e "$f" ] || { echo "FALLITO: non cancellato $f"; exit 1; }
done
for f in "$H/Documenti/contratto.txt" "$H/Desktop/nota.txt" "$H/Shared/foto.jpg" \
         "$R/var/log/syslog" "$R/tmp/nuovo" "$R/tmp/.X11-unix"; do
  [ -e "$f" ] || { echo "FALLITO: cancellato per errore $f"; exit 1; }
done
echo "ok: sicura cancella solo il sicuro"
head -c 100000 /dev/zero > "$R/var/cache/apt/archives/a.deb"; head -c 100000 /dev/zero > "$H/.cache/b.bin"
"$P" --json | grep -q "^apt|.*|[0-9]*$"
"$P" --json | grep -q "^autoremove|"
"$P" --sicura --solo cache >/dev/null
[ -e "$R/var/cache/apt/archives/a.deb" ] && [ ! -e "$H/.cache/b.bin" ] || { echo "FALLITO: --solo"; exit 1; }
echo "ok: --json e --solo"

out=$("$P")
echo "$out" | grep -q "REPORT PULIZIA"
echo "$out" | grep -q "SI PUO' CANCELLARE"
ls "$H/Shared"/pulizia-report-*.txt >/dev/null
echo "ok: report salvato in Shared"

"$P" --auto-on >/dev/null && [ -f "$H/.config/autostart/pulizia.desktop" ]
"$P" --auto-off >/dev/null && [ ! -f "$H/.config/autostart/pulizia.desktop" ]
echo "ok: auto on/off"
rm -rf "$T"
echo "OK pulizia"
