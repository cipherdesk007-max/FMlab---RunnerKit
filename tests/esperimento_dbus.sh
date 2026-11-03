#!/bin/sh
# Esperimento: quanto aspetta GetAddress se il servizio attivato esce senza prendere il nome?
T=$(mktemp -d); export XDG_DATA_HOME="$T/share"; mkdir -p "$XDG_DATA_HOME/dbus-1/services"
prova() {  # $1 = corpo dello script del servizio
  printf '#!/bin/sh\n%s\n' "$1" > "$T/svc"; chmod +x "$T/svc"
  printf '[D-BUS Service]\nName=org.a11y.Bus\nExec=%s\n' "$T/svc" > "$XDG_DATA_HOME/dbus-1/services/org.a11y.Bus.service"
  eval "$(dbus-launch --sh-syntax)"
  i=$(date +%s.%N)
  r=$(timeout 30 dbus-send --session --print-reply --reply-timeout=28000 --dest=org.a11y.Bus /org/a11y/bus org.a11y.Bus.GetAddress 2>&1 | tail -1 | cut -c1-90)
  echo "$(printf '%-40s' "$2") $(echo "$(date +%s.%N) - $i" | bc | cut -c1-5)s  $r"
  kill $DBUS_SESSION_BUS_PID
}
prova 'exit 0' "exit 0"
prova 'exit 1' "exit 1"
prova 'sleep 5 </dev/null >/dev/null 2>&1 & exit 0' "figlio in sottofondo"
prova '(setsid sleep 5 </dev/null >/dev/null 2>&1 &); exit 0' "figlio setsid"
prova 'exec 3>&- 4>&- 5>&- 6>&- 7>&- 8>&- 9>&-; (setsid sleep 5 </dev/null >/dev/null 2>&1 &); exit 0' "figlio setsid fd chiusi"
ls -l /proc/self/fd
prova 'ls -l /proc/$$/fd >&2; exit 0' "elenco fd"
