#!/bin/sh
# Test di UnaVolta: tocchi ripetuti = un solo avvio; --applica / --ripristina.
set -e
DIR=$(cd "$(dirname "$0")/.." && pwd)
UV="$DIR/unavolta/unavolta"
T=$(mktemp -d)
export HOME="$T/home" UNAVOLTA_SYS_DIR="$T/sys"
mkdir -p "$HOME/Desktop" "$UNAVOLTA_SYS_DIR"
PATH="$DIR/unavolta:$PATH"

# 1) cinque tocchi rapidi sullo stesso programma -> un solo processo
cp /bin/sleep "$T/uvtestsleep"
for i in 1 2 3 4 5; do "$UV" "$T/uvtestsleep" 30; done
sleep 1
n=$(pgrep -c -x uvtestsleep || true)
[ "$n" = 1 ] || { echo "FALLITO: avviati $n processi invece di 1"; exit 1; }
echo "ok: 5 tocchi -> 1 avvio"
# programma lento (ancora senza finestra) e tocco dopo la finestra anti-doppio: non deve raddoppiare
UNAVOLTA_SECONDI=0 "$UV" "$T/uvtestsleep" 30
sleep 1
n=$(pgrep -c -x uvtestsleep || true)
pkill -x uvtestsleep || true
[ "$n" = 1 ] || { echo "FALLITO: programma lento riaperto ($n processi)"; exit 1; }
"$UV" --log | grep -q "non ne apro un altro"
echo "ok: programma lento non viene riaperto"

# programmi a piu' finestre (terminali, gestore file): il secondo tocco ne apre un altro
cp /bin/sleep "$T/lxterminal"
"$UV" "$T/lxterminal" 30
UNAVOLTA_SECONDI=0 "$UV" "$T/lxterminal" 30
sleep 1
n=$(pgrep -c -x lxterminal || true)
pkill -x lxterminal || true
[ "$n" = 2 ] || { echo "FALLITO: terminale a piu' finestre aperto $n volte invece di 2"; exit 1; }
echo "ok: terminale -> seconda finestra"

# 2) --applica modifica i lanciatori, --ripristina li riporta com'erano
printf '[Desktop Entry]\nName=Prova\nExec=prova %%u\nType=Application\n' > "$UNAVOLTA_SYS_DIR/prova.desktop"
printf '[Desktop Entry]\nName=Icona\nExec=icona\nType=Application\n' > "$HOME/Desktop/icona.desktop"
printf '[Desktop Entry]\nName=Script\nExec=sh -c "x"\nType=Application\n' > "$HOME/Desktop/script.desktop"
cp "$HOME/Desktop/icona.desktop" "$T/icona.orig"
"$UV" --applica
grep -q '^Exec=unavolta prova %u$' "$HOME/.local/share/applications/prova.desktop"
grep -q '^Exec=unavolta icona$' "$HOME/Desktop/icona.desktop"
grep -q '^Exec=sh -c "x"$' "$HOME/Desktop/script.desktop"
"$UV" --applica | grep -q "su 0 lanciatori"   # seconda volta: niente da fare
# programma aggiornato da apt: la copia vecchia si rifa'; programma tolto: la copia sparisce
sleep 1; printf '[Desktop Entry]\nName=Prova2\nExec=prova2\nType=Application\n' > "$UNAVOLTA_SYS_DIR/prova.desktop"
"$UV" --applica >/dev/null
grep -q '^Exec=unavolta prova2$' "$HOME/.local/share/applications/prova.desktop" || { echo "FALLITO: copia non aggiornata"; exit 1; }
printf '[Desktop Entry]\nName=Via\nExec=via\nType=Application\n' > "$UNAVOLTA_SYS_DIR/via.desktop"
"$UV" --applica >/dev/null; rm "$UNAVOLTA_SYS_DIR/via.desktop"; "$UV" --applica >/dev/null
[ ! -f "$HOME/.local/share/applications/via.desktop" ] || { echo "FALLITO: copia orfana rimasta"; exit 1; }
printf '[Desktop Entry]\nName=Prova\nExec=prova %%u\nType=Application\n' > "$UNAVOLTA_SYS_DIR/prova.desktop"
"$UV" --applica >/dev/null
echo "ok: copie allineate ai programmi installati"
"$UV" --ripristina
[ ! -f "$HOME/.local/share/applications/prova.desktop" ]
cmp -s "$HOME/Desktop/icona.desktop" "$T/icona.orig"
grep -q '^Exec=prova %u$' "$UNAVOLTA_SYS_DIR/prova.desktop"
echo "ok: applica / ripristina"
rm -rf "$T"
echo "OK unavolta"
