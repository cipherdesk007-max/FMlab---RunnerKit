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
pkill -x uvtestsleep || true
[ "$n" = 1 ] || { echo "FALLITO: avviati $n processi invece di 1"; exit 1; }
echo "ok: 5 tocchi -> 1 avvio"

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
"$UV" --ripristina
[ ! -f "$HOME/.local/share/applications/prova.desktop" ]
cmp -s "$HOME/Desktop/icona.desktop" "$T/icona.orig"
grep -q '^Exec=prova %u$' "$UNAVOLTA_SYS_DIR/prova.desktop"
echo "ok: applica / ripristina"
rm -rf "$T"
echo "OK unavolta"
