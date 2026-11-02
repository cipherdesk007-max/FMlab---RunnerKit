#!/bin/sh
# Test di RunnerBoost e Terminale.
set -e
DIR=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d)
export RB_HOME="$T/home" RB_GIRI=1 RB_SCALA=1
mkdir -p "$RB_HOME/.mozilla/firefox/abc.default-esr"
RB="$DIR/runnerboost/runnerboost"

o=$("$RB"); printf '%s\n' "$o" | grep -q "Consigli" || { printf '%s\n' "$o"; exit 1; }
printf '%s\n' "$o" | grep -q "Grafica (GPU del telefono)" || { echo "manca sezione GPU"; exit 1; }
LR_GUI_GPU_ACTIVE=mesa-metal-resident "$RB" | grep -q "disegnano sulla GPU" || { echo "stato GPU non letto"; exit 1; }
SD=$(mktemp -d); printf 'pid=1\ncommand=glxgears\nfps=60.0\nmetal_draws=900\nmesa_draws=100\n' > "$SD/1.txt"
LR_MESA_METAL_STATS_DIR="$SD" "$RB" --gpu-stats | grep -q "glxgears.*900.*100.*90%" || { echo "statistiche GPU non lette"; LR_MESA_METAL_STATS_DIR="$SD" "$RB" --gpu-stats; exit 1; }
echo "ok: diagnosi (con stato GPU) + statistiche"
o=$("$RB" --test "prima"); printf '%s\n' "$o" | grep -q "TOTALE" || { echo "FALLITO test prima:"; printf '%s\n' "$o"; exit 1; }
o=$("$RB" --test "dopo"); printf '%s\n' "$o" | grep -q "rispetto a" || { echo "FALLITO test dopo:"; printf '%s\n' "$o"; exit 1; }
[ "$(wc -l < "$RB_HOME/.config/runnerboost/storico.csv")" = 3 ]
echo "ok: test di velocita' + confronto + storico"

"$RB" --profilo veloce >/dev/null
grep -q 'dom.ipc.processCount' "$RB_HOME/.mozilla/firefox/abc.default-esr/user.js"
grep -q '^gtk-enable-animations=0' "$RB_HOME/.config/gtk-3.0/settings.ini"
[ -f "$RB_HOME/.config/runnerboost/no-compositing" ]
"$RB" --profilo veloce >/dev/null   # due volte: niente righe doppie
[ "$(grep -c 'RunnerBoost inizio' "$RB_HOME/.mozilla/firefox/abc.default-esr/user.js")" = 1 ]
"$RB" --profilo normale >/dev/null
! grep -q 'dom.ipc.processCount' "$RB_HOME/.mozilla/firefox/abc.default-esr/user.js"
grep -q '^gtk-enable-animations=1' "$RB_HOME/.config/gtk-3.0/settings.ini"
[ ! -f "$RB_HOME/.config/runnerboost/no-compositing" ]
echo "ok: profili veloce / normale reversibili"

# Terminale: sintassi, caricamento in una shell interattiva, prompt e statistiche
bash -n "$DIR/terminale/terminale.sh"
out=$(HOME="$T/home" bash --norc -i -c ". '$DIR/terminale/terminale.sh'; _rk_prompt; echo \"PS1=\$PS1\"; rk; type rktop >/dev/null && echo RKTOP; TERM=xterm clear; rk versioni" 2>&1)
printf "%s\n" "$out" | grep -q "RunnerKit"
printf "%s\n" "$out" | grep -q "RAM"
printf "%s\n" "$out" | grep -q "PS1=.*❯"
printf "%s\n" "$out" | grep -q "RKTOP"
printf "%s\n" "$out" | grep -q "GPU:"
[ "$(printf "%s\n" "$out" | grep -c "RunnerKit ─")" -ge 2 ] || { echo "dopo clear la schermata non torna"; exit 1; }
printf "%s\n" "$out" | grep -q "versioni installate"
echo "ok: terminale (banner con GPU, prompt, comandi)"
# barra fissa in un terminale vero (pseudo-tty con script): dopo clear deve ricomparire in cima
if command -v script >/dev/null; then
  tty_out=$(HOME="$T/home" LINES=30 COLUMNS=100 script -qec "bash --norc -i -c \". '$DIR/terminale/terminale.sh'; clear; echo FINE\"" /dev/null 2>&1 || true)
  printf '%s' "$tty_out" | grep -q "3;30r" || { echo "barra fissa: area di scorrimento non impostata"; exit 1; }
  [ "$(printf '%s' "$tty_out" | grep -o "RunnerKit " | wc -l)" -ge 2 ] || { echo "barra fissa non ridisegnata dopo clear"; exit 1; }
  echo "ok: barra fissa resta dopo clear (pseudo-terminale)"
fi
rm -rf "$T" /tmp/runnerboost-dati
out=$(RB_HOME=$(mktemp -d) sh "$DIR/runnerboost/runnerboost" --riposo 1)
printf '%s\n' "$out" | grep -q "processore occupato a riposo" || { echo "riposo: misura mancante"; printf '%s\n' "$out"; exit 1; }
echo "ok: consumo a riposo"
echo "OK runnerboost + terminale"
