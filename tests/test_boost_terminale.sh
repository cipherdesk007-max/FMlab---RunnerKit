#!/bin/sh
# Test di RunnerBoost e Terminale.
set -e
DIR=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d)
export RB_HOME="$T/home" RB_GIRI=1 RB_SCALA=1
mkdir -p "$RB_HOME/.mozilla/firefox/abc.default-esr"
RB="$DIR/runnerboost/runnerboost"

o=$("$RB"); printf '%s\n' "$o" | grep -q "Consigli" || { printf '%s\n' "$o"; exit 1; }
echo "ok: diagnosi"
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
out=$(HOME="$T/home" bash --norc -i -c ". '$DIR/terminale/terminale.sh'; _rk_prompt; echo \"PS1=\$PS1\"; rk; type rktop >/dev/null && echo RKTOP" 2>&1)
printf "%s\n" "$out" | grep -q "RunnerKit"
printf "%s\n" "$out" | grep -q "RAM"
printf "%s\n" "$out" | grep -q "PS1=.*❯"
printf "%s\n" "$out" | grep -q "RKTOP"
echo "ok: terminale (banner, prompt, comandi)"
rm -rf "$T" /tmp/runnerboost-dati
echo "OK runnerboost + terminale"
