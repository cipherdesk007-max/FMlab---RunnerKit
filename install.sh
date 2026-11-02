#!/bin/sh
# RunnerKit - installa o aggiorna gli strumenti per Debian su LinuxRunner.
# Strumenti: TouchPad, UnaVolta, Pulizia
# Uso:  curl -fsSL https://raw.githubusercontent.com/cipherdesk007-max/mia/main/install.sh | sh
set -e
REPO="https://raw.githubusercontent.com/cipherdesk007-max/mia/main"
SUDO=""
[ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null && SUDO="sudo"

echo "== RunnerKit =="
echo ">> Pacchetti (python3-tk, python3-xlib, xcompmgr)..."
$SUDO apt-get install -y python3-tk python3-xlib xcompmgr xdotool >/dev/null 2>&1 || {
  $SUDO apt-get update && $SUDO apt-get install -y python3-tk python3-xlib xcompmgr xdotool; }

echo ">> Scarico TouchPad..."
curl -fsSL "$REPO/touchpad/touchpad.py" -o /tmp/touchpad.py
python3 -m py_compile /tmp/touchpad.py
$SUDO install -m 755 /tmp/touchpad.py /usr/local/bin/touchpad

echo ">> Scarico UnaVolta..."
curl -fsSL "$REPO/unavolta/unavolta" -o /tmp/unavolta
sh -n /tmp/unavolta
$SUDO install -m 755 /tmp/unavolta /usr/local/bin/unavolta

echo ">> Scarico Pulizia..."
curl -fsSL "$REPO/pulizia/pulizia" -o /tmp/pulizia
sh -n /tmp/pulizia
$SUDO install -m 755 /tmp/pulizia /usr/local/bin/pulizia

mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/touchpad.desktop" <<'EOF'
[Desktop Entry]
Name=TouchPad
Comment=Mouse e tastiera touch
Exec=sh -c "pgrep -x xcompmgr >/dev/null || xcompmgr & exec touchpad"
Icon=input-mouse
Type=Application
Categories=Utility;
EOF

# avvio automatico con il desktop (si spegne da TouchPad: impostazioni -> Avvio col desktop -> No)
if [ "${RUNNERKIT_NO_AUTOSTART:-0}" != "1" ]; then
  mkdir -p "$HOME/.config/autostart"
  cat > "$HOME/.config/autostart/touchpad.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=TouchPad
Comment=Avvia TouchPad con il desktop (RunnerKit)
Exec=sh -c "sleep 3; pgrep -x xcompmgr >/dev/null || xcompmgr & exec touchpad"
X-GNOME-Autostart-enabled=true
X-XFCE-Autostart-Override=true
Hidden=false
EOF
fi

# icona anche sul desktop (stessa cartella di Firefox ESR / Tastiera)
for D in "$HOME/Desktop" "$HOME/Scrivania"; do
  if [ -d "$D" ]; then
    cp "$HOME/.local/share/applications/touchpad.desktop" "$D/"
    chmod +x "$D/touchpad.desktop"
  fi
done

# UnaVolta su icone e menu (si toglie con: unavolta --ripristina)
[ "${RUNNERKIT_NO_UNAVOLTA:-0}" = "1" ] || /usr/local/bin/unavolta --applica

V=$(grep -m1 '__version__' /usr/local/bin/touchpad | cut -d'"' -f2)
echo ">> TouchPad v$V installato."
echo "   Aprilo: icona sul desktop, Applications -> TouchPad, oppure scrivi 'touchpad' (anche dal Terminal dell'app)"
echo "   Si apre da solo a ogni avvio del desktop (disattivabile nelle impostazioni)."
echo ">> UnaVolta: ogni programma si apre una volta sola anche con tocchi ripetuti."
echo ">> Pulizia: scrivi 'pulizia' per il report, 'pulizia --sicura' per pulire."
echo "   Per aggiornare in futuro: rilancia lo stesso comando curl."
