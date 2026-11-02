#!/bin/sh
# Installa o aggiorna TouchPad su Debian (LinuxRunner).
# Uso:  curl -fsSL https://raw.githubusercontent.com/cipherdesk007-max/mia/main/install.sh | sh
set -e
REPO="https://raw.githubusercontent.com/cipherdesk007-max/mia/main"
SUDO=""
[ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null && SUDO="sudo"

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

V=$(grep -m1 '__version__' /usr/local/bin/touchpad | cut -d'"' -f2)
echo ">> TouchPad v$V installato."
echo "   Aprilo dal desktop: Applications -> TouchPad  (oppure 'touchpad &' in xterm)"
echo "   Per aggiornare in futuro: rilancia lo stesso comando curl."
