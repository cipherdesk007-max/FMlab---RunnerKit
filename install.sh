#!/bin/sh
# FMlab - RunnerKit - installa o aggiorna gli strumenti per Debian su LinuxRunner.
# Strumenti: TouchPad, Centro, UnaVolta, Pulizia, RunnerBoost, Terminale, Collaudo, Backup, Italiano, Aggiorna, Disinstalla
# Uso:  curl -fsSL https://raw.githubusercontent.com/cipherdesk007-max/FMlab---RunnerKit/stabile/install.sh | sh
set -e
REPO="${RK_REPO:-https://raw.githubusercontent.com/cipherdesk007-max/FMlab---RunnerKit/stabile}"
T="${RK_T:-$(date +%s)}"   # parametro anti-cache: scarica sempre i file appena pubblicati
SUDO=""
[ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null && SUDO="sudo"

echo "== FMlab - RunnerKit =="
# un solo installatore alla volta (due tocchi su ⟳, icona + terminale...)
LOCK=/tmp/runnerkit-installa.lock
if ! mkdir "$LOCK" 2>/dev/null; then
  if [ -n "$(find "$LOCK" -maxdepth 0 -mmin -15 2>/dev/null)" ]; then
    echo "!! Un aggiornamento di RunnerKit e' gia' in corso: aspetta che finisca."; exit 1
  fi
  rm -rf "$LOCK"; mkdir "$LOCK"   # blocco rimasto da un'installazione interrotta
fi
W=$(mktemp -d)
trap 'rm -rf "$W" "$LOCK"' EXIT
trap 'exit 1' INT TERM HUP

# spazio: con il telefono quasi pieno apt e i download si rompono a meta'
LIBERO=$(df -Pk / 2>/dev/null | awk 'NR==2{print $4}')
if [ -n "$LIBERO" ] && [ "$LIBERO" -lt 51200 ]; then
  echo "!! Spazio quasi finito (meno di 50 MB liberi): libera spazio sull'iPhone o usa 'pulizia --sicura', poi riprova."
  exit 1
fi

# pacchetti: apt solo se ne manca qualcuno (apt su LinuxRunner e' pesante: niente lavoro inutile)
PACCHETTI="python3-tk python3-xlib xcompmgr xdotool shared-mime-info desktop-file-utils bash-completion mesa-utils x11-utils"
MANCANO=""
for p in $PACCHETTI; do dpkg -s "$p" >/dev/null 2>&1 || MANCANO="$MANCANO $p"; done
if [ -n "$MANCANO" ] && [ "${RK_SALTA_APT:-0}" = 1 ]; then
  echo ">> (prova) salto apt, mancherebbero:$MANCANO"
elif [ -n "$MANCANO" ]; then
  echo ">> Installo i pacchetti mancanti:$MANCANO"
  $SUDO dpkg --configure -a >/dev/null 2>&1 || true   # completa eventuali installazioni interrotte
  $SUDO apt-get install -y $MANCANO >/dev/null 2>&1 || { $SUDO apt-get update && $SUDO apt-get install -y $MANCANO; } ||
    { echo "!! Non riesco a installare i pacchetti Debian (rete o apt occupato): riprova tra poco. RunnerKit non e' stato cambiato."; exit 1; }
else
  echo ">> Pacchetti gia' presenti"
fi

# 1) scarico TUTTO in una cartella temporanea e controllo ogni file.
#    Si installa solo se e' tutto a posto: una rete che cade a meta' non lascia mai il kit mezzo vecchio e mezzo nuovo.
echo ">> Scarico i file..."
FILES="VERSIONE touchpad/touchpad.py unavolta/unavolta runnerboost/runnerboost terminale/terminale.sh terminale/rkterminale
pulizia/pulizia strumenti/rkcollaudo strumenti/rkbackup strumenti/rkitaliano strumenti/rkaggiorna strumenti/rkcentro strumenti/rkdisinstalla strumenti/rkavvio"
for f in $FILES; do
  mkdir -p "$W/$(dirname "$f")"
  e=0; curl -fsS --location --retry 3 --retry-delay 2 --max-time 120 "$REPO/$f?t=$T" -o "$W/$f" 2>/dev/null || e=$?
  if [ "$e" = 22 ]; then
    echo "!! La versione nuova non e' ancora pubblicata (i test automatici stanno finendo): riprova tra 2-3 minuti. Non ho cambiato niente."; exit 1
  elif [ "$e" != 0 ]; then
    echo "!! Download non riuscito ($f): controlla la connessione e riprova. Non ho cambiato niente."; exit 1
  fi
done
NUOVA=$(tr -d '[:space:]' < "$W/VERSIONE")
case "$NUOVA" in
  [0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]-[0-9]*) ;;
  *) echo "!! Risposta strana da GitHub (rete con pagina di accesso?). Non ho cambiato niente."; exit 1 ;;
esac
for f in $FILES; do
  [ "$f" = VERSIONE ] && continue
  case "$(head -1 "$W/$f")" in
    *python*) python3 -m py_compile "$W/$f" ;;
    *bash*) bash -n "$W/$f" ;;
    *) case "$f" in *.sh) bash -n "$W/$f" ;; *) sh -n "$W/$f" ;; esac ;;
  esac 2>/dev/null || { echo "!! File rovinato ($f). Non ho cambiato niente: riprova tra qualche minuto."; exit 1; }
done
find "$W" -name '__pycache__' -prune -exec rm -rf {} + 2>/dev/null

# 2) installo (copie veloci: il passaggio rischioso, il download, e' gia' finito)
echo ">> Installo FMlab - RunnerKit $NUOVA..."
$SUDO mkdir -p /usr/local/share/runnerkit
$SUDO install -m 755 "$W/touchpad/touchpad.py" /usr/local/bin/touchpad
for f in unavolta/unavolta runnerboost/runnerboost terminale/rkterminale pulizia/pulizia \
         strumenti/rkcollaudo strumenti/rkbackup strumenti/rkitaliano strumenti/rkaggiorna strumenti/rkcentro strumenti/rkdisinstalla strumenti/rkavvio; do
  $SUDO install -m 755 "$W/$f" "/usr/local/bin/$(basename "$f")"
done
$SUDO install -m 644 "$W/terminale/terminale.sh" /usr/local/share/runnerkit/terminale.sh

mkdir -p "$HOME/.local/share/applications"
# ~/Templates: pannello e desktop di LinuxRunner lo cercano a ogni avvio (avviso nel report di LinuxRunner)
mkdir -p "$HOME/Templates" 2>/dev/null
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
Exec=sh -c "sleep 1; exec touchpad --avvio"
X-GNOME-Autostart-enabled=true
X-XFCE-Autostart-Override=true
Hidden=false
EOF
fi

# Il desktop di LinuxRunner non legge ~/.config/autostart (avvia openbox, lxpanel e pcmanfm da solo):
# TouchPad parte tramite D-Bus, che all'avvio del desktop attiva il servizio di accessibilita'.
# rkavvio fa partire TouchPad e poi passa la mano al vero servizio, se installato.
SVC="$HOME/.local/share/dbus-1/services/org.a11y.Bus.service"
if [ ! -e "$SVC" ] || grep -q rkavvio "$SVC" 2>/dev/null; then
  mkdir -p "$(dirname "$SVC")"
  printf '[D-BUS Service]\nName=org.a11y.Bus\nExec=/usr/local/bin/rkavvio\n' > "$SVC"
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
# (solo la prima volta o se sono stati installati pacchetti: e' un'operazione pesante)
if [ -n "$MANCANO" ] || [ ! -f /usr/local/share/runnerkit/mime-ok ]; then
  command -v update-mime-database >/dev/null && $SUDO update-mime-database /usr/share/mime >/dev/null 2>&1
  $SUDO mkdir -p /usr/local/share/runnerkit && $SUDO touch /usr/local/share/runnerkit/mime-ok
fi
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
echo "$NUOVA" | $SUDO tee /usr/local/share/runnerkit/versione >/dev/null

# TouchPad gia' aperto: lo riavvio, cosi' la versione nuova e' subito attiva
if pgrep -f /usr/local/bin/touchpad >/dev/null 2>&1; then
  pkill -f /usr/local/bin/touchpad 2>/dev/null; sleep 1
  (nohup /usr/local/bin/touchpad --avvio >/dev/null 2>&1 &)
  RIAVVIATO=" (riavviato)"
fi
date '+%Y-%m-%d %H:%M' | $SUDO tee /usr/local/share/runnerkit/installato >/dev/null

echo ""
echo "== FMlab - RunnerKit $(cat /usr/local/share/runnerkit/versione 2>/dev/null) installato =="
echo "   TouchPad    $(grep -m1 '__version__' /usr/local/bin/touchpad | cut -d'"' -f2)${RIAVVIATO:-}"
echo "   UnaVolta    $(/usr/local/bin/unavolta --versione | cut -d' ' -f2)"
echo "   Pulizia     $(/usr/local/bin/pulizia --versione | cut -d' ' -f2)"
echo "   RunnerBoost $(/usr/local/bin/runnerboost --versione | cut -d' ' -f2)"
echo "   Terminale   $(/usr/local/bin/rkterminale --versione)"
echo "   Centro      $(grep -m1 '__version__' /usr/local/bin/rkcentro 2>/dev/null | cut -d'"' -f2)  (icona sul desktop, pallini ♻ e ⚡)"
echo "   Collaudo, Backup, Italiano: rk collaudo · rk backup · rk italiano · togliere tutto: rk disinstalla"
echo ""
echo "   Comandi: scrivi 'rk' in un terminale nuovo."
echo "   Aggiornare in futuro: pallino ⟳ di TouchPad (diventa arancione quando c'e' una novita'),"
echo "   icona 'Aggiorna RunnerKit' sul desktop, oppure: rk aggiorna"
