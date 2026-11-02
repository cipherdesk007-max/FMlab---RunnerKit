#!/bin/sh
# RunnerKit - installa o aggiorna gli strumenti per Debian su LinuxRunner.
# Strumenti: TouchPad, UnaVolta, Pulizia, RunnerBoost, Terminale, Collaudo, Backup, Italiano
# Uso:  curl -fsSL https://raw.githubusercontent.com/cipherdesk007-max/mia/main/install.sh | sh
set -e
REPO="https://raw.githubusercontent.com/cipherdesk007-max/mia/main"
T="${RK_T:-$(date +%s)}"   # parametro anti-cache: scarica sempre i file appena pubblicati
SUDO=""
[ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null && SUDO="sudo"

echo "== RunnerKit =="
echo ">> Pacchetti (python3-tk, python3-xlib, xcompmgr)..."
$SUDO apt-get install -y python3-tk python3-xlib xcompmgr xdotool shared-mime-info desktop-file-utils bash-completion mesa-utils x11-utils >/dev/null 2>&1 || {
  $SUDO apt-get update && $SUDO apt-get install -y python3-tk python3-xlib xcompmgr xdotool shared-mime-info desktop-file-utils bash-completion mesa-utils x11-utils; }

echo ">> Scarico TouchPad..."
curl -fsSL "$REPO/touchpad/touchpad.py?t=$T" -o /tmp/touchpad.py
python3 -m py_compile /tmp/touchpad.py
$SUDO install -m 755 /tmp/touchpad.py /usr/local/bin/touchpad

echo ">> Scarico UnaVolta..."
curl -fsSL "$REPO/unavolta/unavolta?t=$T" -o /tmp/unavolta
sh -n /tmp/unavolta
$SUDO install -m 755 /tmp/unavolta /usr/local/bin/unavolta

echo ">> Scarico RunnerBoost e Terminale..."
curl -fsSL "$REPO/runnerboost/runnerboost?t=$T" -o /tmp/runnerboost
curl -fsSL "$REPO/terminale/terminale.sh?t=$T" -o /tmp/terminale.sh
curl -fsSL "$REPO/terminale/rkterminale?t=$T" -o /tmp/rkterminale
sh -n /tmp/runnerboost && bash -n /tmp/terminale.sh && sh -n /tmp/rkterminale
$SUDO install -m 755 /tmp/runnerboost /usr/local/bin/runnerboost
$SUDO install -m 755 /tmp/rkterminale /usr/local/bin/rkterminale
$SUDO mkdir -p /usr/local/share/runnerkit
$SUDO install -m 644 /tmp/terminale.sh /usr/local/share/runnerkit/terminale.sh

echo ">> Scarico Centro, Collaudo, Backup, Italiano, Aggiorna..."
for t in rkcollaudo rkbackup rkitaliano rkaggiorna rkcentro; do
  curl -fsSL "$REPO/strumenti/$t?t=$T" -o "/tmp/$t" || continue
  case "$(head -1 "/tmp/$t")" in *python*) python3 -m py_compile "/tmp/$t" ;; *) bash -n "/tmp/$t" ;; esac &&
    $SUDO install -m 755 "/tmp/$t" "/usr/local/bin/$t"
done

echo ">> Scarico Pulizia..."
curl -fsSL "$REPO/pulizia/pulizia?t=$T" -o /tmp/pulizia
sh -n /tmp/pulizia
$SUDO install -m 755 /tmp/pulizia /usr/local/bin/pulizia

mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/touchpad.desktop" <<'EOF'
[Desktop Entry]
Name=TouchPad
Comment=Mouse e tastiera touch
Exec=sh -c "[ -f ~/.config/runnerboost/no-compositing ] || pgrep -x xcompmgr >/dev/null || xcompmgr & exec touchpad"
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
Exec=sh -c "sleep 3; [ -f ~/.config/runnerboost/no-compositing ] || pgrep -x xcompmgr >/dev/null || xcompmgr & exec touchpad --avvio"
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

# tipi di file: le icone .desktop si aprono subito (niente finestra "Execute File")
command -v update-mime-database >/dev/null && $SUDO update-mime-database /usr/share/mime >/dev/null 2>&1
command -v update-desktop-database >/dev/null && update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1

# Terminale RunnerKit (si spegne con: rkterminale --off)
[ "${RUNNERKIT_NO_TERMINALE:-0}" = "1" ] || /usr/local/bin/rkterminale --on >/dev/null

# icona "RunnerKit Centro" (sistema, pulizia, processi)
cat > "$HOME/.local/share/applications/runnerkit-centro.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=RunnerKit Centro
Comment=Sistema, pulizia del disco e processi
Exec=rkcentro
Icon=utilities-system-monitor
Categories=Utility;System;
EOF
for D in "$HOME/Desktop" "$HOME/Scrivania"; do
  [ -d "$D" ] && cp "$HOME/.local/share/applications/runnerkit-centro.desktop" "$D/" && chmod +x "$D/runnerkit-centro.desktop"
done

# icona "Aggiorna RunnerKit" (desktop e menu)
cat > "$HOME/.local/share/applications/runnerkit-aggiorna.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Aggiorna RunnerKit
Comment=Scarica e installa l'ultima versione di RunnerKit
Exec=rkaggiorna
Icon=system-software-update
Categories=Utility;
EOF
for D in "$HOME/Desktop" "$HOME/Scrivania"; do
  [ -d "$D" ] && cp "$HOME/.local/share/applications/runnerkit-aggiorna.desktop" "$D/" && chmod +x "$D/runnerkit-aggiorna.desktop"
done

# versione del kit (TouchPad la confronta con GitHub e accende il pallino ⟳ se ce n'e' una nuova)
$SUDO mkdir -p /usr/local/share/runnerkit
curl -fsSL "$REPO/VERSIONE?t=$T" 2>/dev/null | $SUDO tee /usr/local/share/runnerkit/versione >/dev/null

# TouchPad gia' aperto: lo riavvio, cosi' la versione nuova e' subito attiva
if pgrep -f /usr/local/bin/touchpad >/dev/null 2>&1; then
  pkill -f /usr/local/bin/touchpad 2>/dev/null; sleep 1
  (nohup /usr/local/bin/touchpad --avvio >/dev/null 2>&1 &)
  RIAVVIATO=" (riavviato)"
fi
$SUDO mkdir -p /usr/local/share/runnerkit
date '+%Y-%m-%d %H:%M' | $SUDO tee /usr/local/share/runnerkit/installato >/dev/null

echo ""
echo "== RunnerKit $(cat /usr/local/share/runnerkit/versione 2>/dev/null) installato =="
echo "   TouchPad    $(grep -m1 '__version__' /usr/local/bin/touchpad | cut -d'"' -f2)${RIAVVIATO:-}"
echo "   UnaVolta    $(/usr/local/bin/unavolta --versione | cut -d' ' -f2)"
echo "   Pulizia     $(/usr/local/bin/pulizia --versione | cut -d' ' -f2)"
echo "   RunnerBoost $(/usr/local/bin/runnerboost --versione | cut -d' ' -f2)"
echo "   Terminale   $(/usr/local/bin/rkterminale --versione)"
echo "   Centro      $(grep -m1 '__version__' /usr/local/bin/rkcentro 2>/dev/null | cut -d'"' -f2)  (icona sul desktop, pallini ♻ e ⚡)"
echo "   Collaudo, Backup, Italiano: rk collaudo · rk backup · rk italiano"
echo ""
echo "   Comandi: scrivi 'rk' in un terminale nuovo."
echo "   Aggiornare in futuro: pallino ⟳ di TouchPad (diventa arancione quando c'e' una novita'),"
echo "   icona 'Aggiorna RunnerKit' sul desktop, oppure: rk aggiorna"
