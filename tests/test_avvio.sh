#!/bin/sh
# Prova il meccanismo vero di avvio col desktop, come su LinuxRunner: un bus D-Bus di sessione e un
# programma GTK3 che parte (come lxpanel/pcmanfm). GTK chiede org.a11y.Bus -> D-Bus avvia rkavvio ->
# rkavvio avvia TouchPad (qui un finto TouchPad che lascia un segno). Va lanciato con uno schermo (xvfb-run).
set -e
DIR=$(cd "$(dirname "$0")/.." && pwd)
command -v dbus-daemon >/dev/null && command -v zenity >/dev/null || { echo "salto: servono dbus-daemon e zenity"; exit 0; }
T=$(mktemp -d)
export HOME="$T/home" XDG_DATA_HOME="$T/home/.local/share"
mkdir -p "$HOME/.config/autostart" "$XDG_DATA_HOME/dbus-1/services" "$T/bin"
echo "[Desktop Entry]" > "$HOME/.config/autostart/touchpad.desktop"
cp "$DIR/strumenti/rkavvio" "$T/bin/rkavvio"; chmod +x "$T/bin/rkavvio"
cat > "$T/bin/touchpad" <<EOT
#!/usr/bin/env python3
import os, sys, time
open("$T/segno", "a").write("avviato " + " ".join(sys.argv[1:]) + " " + os.environ.get("DISPLAY", "-") + "\n")
time.sleep(20)
EOT
chmod +x "$T/bin/touchpad"
# il servizio punta a un piccolo involucro che passa il finto TouchPad
printf '#!/bin/sh\nRKAVVIO_TP=%s exec %s "$@"\n' "$T/bin/touchpad" "$T/bin/rkavvio" > "$T/bin/avvio"; chmod +x "$T/bin/avvio"
printf '[D-BUS Service]\nName=org.a11y.Bus\nExec=%s\n' "$T/bin/avvio" > "$XDG_DATA_HOME/dbus-1/services/org.a11y.Bus.service"
eval "$(dbus-launch --sh-syntax 2>/dev/null)" || {
  ADDR=$(dbus-daemon --session --fork --print-address); export DBUS_SESSION_BUS_ADDRESS="$ADDR"; }
dbus-update-activation-environment DISPLAY HOME XDG_DATA_HOME 2>/dev/null || true
# due programmi GTK insieme, come lxpanel e pcmanfm: TouchPad deve partire UNA volta
inizio=$(date +%s)
timeout 15 zenity --info --text prova --timeout=2 >/dev/null 2>&1 &
timeout 15 zenity --info --text prova --timeout=2 >/dev/null 2>&1 &
wait
durata=$(( $(date +%s) - inizio ))
sleep 2
n=$(grep -c "avviato --avvio" "$T/segno" 2>/dev/null || echo 0)
pkill -f "$T/bin/touchpad" 2>/dev/null || true
[ -n "${DBUS_SESSION_BUS_PID:-}" ] && kill "$DBUS_SESSION_BUS_PID" 2>/dev/null
[ "$n" = 1 ] || { echo "FALLITO: TouchPad avviato $n volte (atteso 1)"; cat "$HOME/.config/runnerkit/avvio.log" 2>/dev/null; exit 1; }
grep -q "avvio TouchPad" "$HOME/.config/runnerkit/avvio.log" || { echo "FALLITO: registro avvio"; exit 1; }
[ "$durata" -le 10 ] || { echo "FALLITO: i programmi GTK hanno aspettato troppo ($durata s)"; exit 1; }
echo "ok: GTK -> D-Bus -> rkavvio -> TouchPad una volta sola (programmi GTK pronti in $durata s)"
# avvio col desktop spento: niente TouchPad
rm "$HOME/.config/autostart/touchpad.desktop"; rm -rf /tmp/rkavvio-"$(id -u)".lock
eval "$(dbus-launch --sh-syntax 2>/dev/null)"
timeout 15 zenity --info --text prova --timeout=1 >/dev/null 2>&1 || true
sleep 1
[ "$(grep -c "avviato" "$T/segno")" = 1 ] || { echo "FALLITO: avviato anche da spento"; exit 1; }
[ -n "${DBUS_SESSION_BUS_PID:-}" ] && kill "$DBUS_SESSION_BUS_PID" 2>/dev/null
rm -rf "$T" /tmp/rkavvio-"$(id -u)".lock
echo "OK avvio col desktop"
