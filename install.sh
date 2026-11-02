#!/bin/sh
# RunnerKit - installa o aggiorna gli strumenti per Debian su LinuxRunner.
# Strumenti: TouchPad
# Uso:  curl -fsSL https://raw.githubusercontent.com/cipherdesk007-max/mia/main/install.sh | sh
set -e
REPO="https://raw.githubusercontent.com/cipherdesk007-max/mia/main"
SUDO=""
[ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null && SUDO="sudo"

echo "== RunnerKit =="
echo ">> Pacchetti (python3-tk, python3-xlib, xcompmgr)..."
$SUDO apt-get install -y python3-tk python3-xlib xcompmgr >/dev/null 2>&1 || {
  $SUDO apt-get update && $SUDO apt-get install -y python3-tk python3-xlib xcompmgr; }

echo ">> Scarico TouchPad..."
curl -fsSL "$REPO/touchpad/touchpad.py" -o /tmp/touchpad.py
python3 -m py_compile /tmp/touchpad.py
$SUDO install -m 755 /tmp/touchpad.py /usr/local/bin/touchpad

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

# icona anche sul desktop (stessa cartella di Firefox ESR / Tastiera)
for D in "$HOME/Desktop" "$HOME/Scrivania"; do
  if [ -d "$D" ]; then
    cp "$HOME/.local/share/applications/touchpad.desktop" "$D/"
    chmod +x "$D/touchpad.desktop"
  fi
done

V=$(grep -m1 '__version__' /usr/local/bin/touchpad | cut -d'"' -f2)
echo ">> TouchPad v$V installato."
echo "   Aprilo: icona sul desktop, Applications -> TouchPad, oppure scrivi 'touchpad' (anche dal Terminal dell'app)"
echo "   Per aggiornare in futuro: rilancia lo stesso comando curl."
