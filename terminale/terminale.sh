# RunnerKit Terminale - prompt, colori, statistiche e scorciatoie per bash su LinuxRunner.
# Caricato da ~/.bashrc. Tutto e' scritto in bash puro, leggendo /proc: niente programmi
# lanciati a ogni prompt, perche' su LinuxRunner ogni processo costa.
case $- in *i*) ;; *) return ;; esac
RK_TERM_VERSIONE="1.4.0"
[ -r "$HOME/.config/runnerkit/terminale" ] && . "$HOME/.config/runnerkit/terminale"   # RK_FISSO=0/1
# lingua scelta con "rk italiano"
if [ -r "$HOME/.config/runnerkit/lingua" ]; then
  LANG="$(cat "$HOME/.config/runnerkit/lingua")"; LANGUAGE="${LANG%%_*}:en"; export LANG LANGUAGE
fi

# ---------- storia comandi ----------
HISTSIZE=20000; HISTFILESIZE=40000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%d/%m %H:%M  '
shopt -s histappend checkwinsize cdspell autocd globstar 2>/dev/null
[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion

# ---------- colori ----------
command -v dircolors >/dev/null && eval "$(dircolors -b)"
alias ls='ls --color=auto --group-directories-first'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
export LESS='-R -i -M'
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

_c() { printf '\[\033[%sm\]' "$1"; }
_rk_n() { printf '\033[%sm' "$1"; }

# ---------- funzioni veloci (solo /proc, nessun processo) ----------
_rk_ram() {  # usati totale percentuale (MB)
  local k v t=0 a=-1 lib=0
  while read -r k v _; do
    case $k in MemTotal:) t=$v ;; MemAvailable:) a=$v ;; MemFree:|Buffers:|Cached:|SReclaimable:) lib=$((lib + v)) ;; esac
  done < /proc/meminfo
  (( a <= 0 )) && a=$lib   # alcuni ambienti (Terminal dell'app) non danno MemAvailable
  echo $(( (t - a) / 1024 )) $(( t / 1024 )) $(( t ? (t - a) * 100 / t : 0 ))
}
_rk_barra() {  # $1 percentuale, $2 larghezza
  local p=$1 w=${2:-20} f i s="" col=32
  (( p > 70 )) && col=33; (( p > 85 )) && col=31
  f=$(( p * w / 100 ))
  for (( i = 0; i < w; i++ )); do (( i < f )) && s+="█" || s+="░"; done
  printf '\033[%sm%s\033[0m %3d%%' "$col" "$s" "$p"
}
_rk_uptime() { local u; read -r u _ < /proc/uptime; u=${u%.*}; printf '%dh %02dm' $((u / 3600)) $((u % 3600 / 60)); }
_rk_git() {  # ramo git leggendo .git/HEAD, senza lanciare git
  local d=$PWD h
  while [[ -n $d ]]; do
    if [[ -r $d/.git/HEAD ]]; then read -r h < "$d/.git/HEAD"; printf ' (%s)' "${h##*/}"; return; fi
    d=${d%/*}
  done
}

# ---------- schermata iniziale con statistiche ----------
rkinfo() {
  local u t p used total pct disk jit="" load procs
  read -r used total pct <<< "$(_rk_ram)"
  read -r load _ _ procs _ < /proc/loadavg 2>/dev/null
  disk=$(df -Pk / 2>/dev/null | awk 'NR==2{printf "%d %d %d", $3/1048576, $2/1048576, $5}')
  read -r du dt dp <<< "$disk"
  [[ -r /proc/ish/jit ]] && jit=$(grep -m1 -i mode /proc/ish/jit 2>/dev/null)
  printf '%s' "$(_rk_n '1;35')"
  echo '  ╭─ FMlab - RunnerKit ─────────────────────╮'
  printf '  │ %-40s│\n' "$(date '+%A %d %B, %H:%M')"
  echo '  ╰─────────────────────────────────────────╯'
  printf '%s' "$(_rk_n 0)"
  printf '  RAM    %s  %s/%s MB\n' "$(_rk_barra "$pct")" "$used" "$total"
  [[ -n $dp ]] && printf '  Disco  %s  %s/%s GB\n' "$(_rk_barra "${dp%\%}")" "$du" "$dt"
  printf '  Acceso da %s · carico %s · processi %s\n' "$(_rk_uptime)" "${load:-?}" "${procs#*/}"
  local gpu="software"
  case ${LR_GUI_GPU_ACTIVE:-} in mesa-metal-resident) gpu="Metal (GPU del telefono)";; mesa-metal-verify) gpu="Metal (verifica)";; esac
  [[ -z ${LR_GUI_GPU_ACTIVE:-} && -c /dev/linuxrunner-gpu ]] && gpu="Metal disponibile"
  printf '  GPU: %s' "$gpu"
  [[ -n $jit ]] && printf ' · JIT: %s' "${jit##*: }"
  echo
  printf '  %sComandi RunnerKit: rk%s\n' "$(_rk_n 2)" "$(_rk_n 0)"
}

# ---------- monitor dal vivo ----------
rktop() {
  local used total pct load _rk_via=0
  trap '_rk_via=1' INT          # Ctrl+C esce dal monitor (la trap si toglie all'uscita)
  printf '\033[?25l'
  while (( ! _rk_via )); do
    read -r used total pct <<< "$(_rk_ram)"
    read -r load _ < /proc/loadavg
    printf '\033[H\033[2J%sRunnerKit monitor%s  (Ctrl+C per uscire)\n\n' "$(_rk_n '1;35')" "$(_rk_n 0)"
    printf '  RAM    %s  %s/%s MB\n' "$(_rk_barra "$pct" 30)" "$used" "$total"
    printf '  Carico %s\n\n' "$load"
    ps -eo pid,rss,pcpu,comm --sort=-rss 2>/dev/null | awk 'NR==1{printf "  %6s %8s %6s  %s\n","PID","RAM MB","CPU%","PROGRAMMA"; next} NR<=12 {printf "  %6s %8.0f %6s  %s\n",$1,$2/1024,$3,$4}'
    sleep 3 || break
  done
  trap - INT
  printf '\033[?25h\n'
}

# ---------- prompt: utente, cartella, ramo git, esito e durata del comando ----------
_rk_t0=""
_rk_prima() { [[ -z $_rk_t0 ]] && _rk_t0=$SECONDS; }
trap '_rk_prima' DEBUG
_rk_prompt() {
  local e=$? dur="" utente
  if [[ -n $_rk_t0 ]]; then local d=$((SECONDS - _rk_t0)); (( d >= 3 )) && dur=" ⏱${d}s"; fi
  _rk_t0=""
  history -a
  if (( EUID == 0 )); then utente="$(_c '1;31')\u"; else utente="$(_c '1;32')\u"; fi
  local esito=""; (( e != 0 )) && esito="$(_c 31)✘$e "
  PS1="$esito$utente$(_c 0)@$(_c 36)\h $(_c '1;34')\w$(_c 33)$(_rk_git)$(_c 35)$dur$(_c 0)\n$(_c '1;35')❯$(_c 0) "
}
# ---------- barra di stato fissa in cima ----------
# Righe 1-2 riservate (area di scorrimento DECSTBM sotto): i comandi scorrono senza coprirla.
# Si ridisegna a ogni prompt, quindi torna anche dopo clear, reset o programmi a tutto schermo.
_rk_disco_t=0; _rk_disco=""
_rk_riga1() {
  local used total pct gpu="software" jit=""
  read -r used total pct <<< "$(_rk_ram)"
  if (( SECONDS - _rk_disco_t > 60 || _rk_disco_t == 0 )); then   # df al massimo una volta al minuto
    _rk_disco=$(df -Pk / 2>/dev/null | awk 'NR==2{print $5}'); _rk_disco_t=$SECONDS
  fi
  case ${LR_GUI_GPU_ACTIVE:-} in mesa-metal-resident) gpu="Metal";; esac
  [[ -z ${LR_GUI_GPU_ACTIVE:-} && -c /dev/linuxrunner-gpu ]] && gpu="Metal disp."
  if [[ -r /proc/ish/jit ]]; then jit=$(grep -m1 -i mode /proc/ish/jit 2>/dev/null); jit=${jit##*: }; fi
  printf '\033[1;45;97m FMlab·RunnerKit \033[0;100;97m RAM %s %3d%% \033[0;100;97m│ Disco %s \033[0;100;97m│ GPU %s%s \033[0m' \
    "$(_rk_barra_mini "$pct")" "$pct" "${_rk_disco:-?}" "$gpu" "${jit:+ │ JIT $jit}"
}
_rk_barra_mini() { local p=$1 f=$(( $1 * 8 / 100 )) i s=""; for (( i = 0; i < 8; i++ )); do (( i < f )) && s+="▮" || s+="▯"; done; printf '%s' "$s"; }
_rk_riga2() { printf '\033[2m rk = comandi · rk collaudo · rk backup · rk copia/incolla (appunti iPhone) · rk fisso off\033[0m'; }
_RK_H=2
_rk_righe() {  # altezza del terminale (LINES puo' essere vuoto al primo prompt)
  local r=${LINES:-0}
  (( r > 0 )) || read -r r _ < <(stty size 2>/dev/null)
  echo "${r:-0}"
}
_rk_fisso() {
  # Disegna la barra nelle righe 1-2 e fa scorrere i comandi solo dalla riga 3 in giu'.
  # Non chiede nulla al terminale (alcuni non rispondono): salva e rimette il cursore.
  [[ ${RK_FISSO:-1} == 1 && -t 1 ]] || return 0
  local rows; rows=$(_rk_righe)
  (( rows >= 10 )) || return 0
  printf '\0337\033[%d;%dr\033[1;1H\033[2K%s\033[2;1H\033[2K%s\0338' \
    $((_RK_H + 1)) "$rows" "$(_rk_riga1)" "$(_rk_riga2)"
  return 0
}
_rk_prompt_tutto() { local e=$?; _rk_fisso; (exit $e); _rk_prompt; }
# PROMPT_COMMAND di altri programmi (es. venv, direnv) restano: il nostro si aggiunge
case ";${PROMPT_COMMAND:-};" in *";_rk_prompt_tutto;"*) ;; *) PROMPT_COMMAND="_rk_prompt_tutto${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;; esac
# all'uscita dal terminale si libera l'area di scorrimento (chi apre dopo trova lo schermo normale)
trap '[[ -t 1 ]] && printf "\033[r"' EXIT
# telefono ruotato / finestra ridimensionata: la barra si rimette subito al suo posto
trap '_rk_fisso' WINCH

# ---------- scorciatoie ----------
alias ll='ls -lh' la='ls -lAh' l='ls -CF'
alias ..='cd ..' ...='cd ../..' ....='cd ../../..'
alias aggiorna='apt update && apt full-upgrade -y'
alias installa='apt install' cerca='apt search' rimuovi='apt remove'
alias spazio='df -h /' memoria='free -h'
alias boost='runnerboost' pulisci='pulizia'
# aggiorna RunnerKit e ricarica subito il terminale con la versione nuova
rkaggiorna() { command rkaggiorna && exec bash; }
mkcd() { mkdir -p "$1" && cd "$1"; }
estrai() {  # estrae qualsiasi archivio
  case "$1" in
    *.tar.gz|*.tgz) tar xzf "$1" ;; *.tar.xz) tar xJf "$1" ;; *.tar.bz2) tar xjf "$1" ;;
    *.tar) tar xf "$1" ;; *.zip) unzip "$1" ;; *.gz) gunzip "$1" ;; *.xz) unxz "$1" ;;
    *.7z) 7z x "$1" ;; *) echo "formato non riconosciuto: $1" ;;
  esac
}
aiphone() {  # copia file nella cartella che vedi dall'app File dell'iPhone
  local d=/mnt/LinuxRunnerShared; [[ -d $d ]] || d=~/Shared
  [[ -d $d ]] || { echo "cartella condivisa non trovata"; return 1; }
  cp -rv "$@" "$d"/ && echo "-> app File: In questo iPhone > LinuxRunner > Shared"
}
dalliphone() { local d=/mnt/LinuxRunnerShared; [[ -d $d ]] || d=~/Shared; cd "$d" && ls -lh; }
rk() {  # comando unico di RunnerKit: rk, rk aggiorna, rk versioni, rk gpu, ...
  case "${1:-}" in
    aggiorna) rkaggiorna ;;
    versioni|v)
      printf '%sRunnerKit%s — versioni installate\n' "$(_rk_n '1;35')" "$(_rk_n 0)"
      printf '  TouchPad     %s\n' "$(grep -m1 '__version__' /usr/local/bin/touchpad 2>/dev/null | cut -d'"' -f2)"
      printf '  UnaVolta     %s\n' "$(unavolta --versione 2>/dev/null | cut -d' ' -f2)"
      printf '  Pulizia      %s\n' "$(pulizia --versione 2>/dev/null | cut -d' ' -f2)"
      printf '  RunnerBoost  %s\n' "$(runnerboost --versione 2>/dev/null | cut -d' ' -f2)"
      printf '  Terminale    %s\n' "$RK_TERM_VERSIONE"
      if [[ -r /usr/local/share/runnerkit/versione ]]; then printf '  RunnerKit    %s\n' "$(cat /usr/local/share/runnerkit/versione)"; fi
      if [[ -r /usr/local/share/runnerkit/installato ]]; then printf '  installato   %s\n' "$(cat /usr/local/share/runnerkit/installato)"; fi ;;
    info) rkinfo ;;
    top) rktop ;;
    gpu) runnerboost --gpu ;;
    boost) runnerboost ;;
    pulizia) pulizia ;;
    pulisci) pulizia --sicura ;;
    log) unavolta --log; echo; tail -20 ~/.touchpad.log 2>/dev/null ;;
    collaudo) rkcollaudo ;;
    disinstalla) shift; rkdisinstalla "$@" ;;
    centro) (rkcentro "${2:-sistema}" >/dev/null 2>&1 &) ;;
    backup) shift; rkbackup "$@" ;;
    ripristina) shift; rkbackup --ripristina "$@" ;;
    italiano) if [[ ${2:-} == off ]]; then rkitaliano --off; else rkitaliano --on; fi ;;
    copia)  # verso gli appunti dell'iPhone: rk copia testo  |  rk copia < file  |  comando | rk copia
      [[ -w /dev/clipboard ]] || { echo "appunti dell'iPhone non raggiungibili (/dev/clipboard)"; return 1; }
      if (( $# > 1 )); then shift; if [[ -f $1 && $# == 1 ]]; then cat "$1" > /dev/clipboard; else printf '%s' "$*" > /dev/clipboard; fi
      else cat > /dev/clipboard; fi
      echo "Copiato negli appunti dell'iPhone." ;;
    incolla) [[ -r /dev/clipboard ]] && { cat /dev/clipboard; echo; } || echo "appunti dell'iPhone non raggiungibili" ;;
    fisso)
      mkdir -p ~/.config/runnerkit
      if [[ ${2:-on} == off ]]; then echo 'RK_FISSO=0' > ~/.config/runnerkit/terminale; RK_FISSO=0; printf '\033[r'; command clear; echo "Barra fissa spenta."
      else echo 'RK_FISSO=1' > ~/.config/runnerkit/terminale; RK_FISSO=1; echo "Barra fissa accesa."; fi ;;
    *)
      printf '%sRunnerKit%s — comandi  (rk versioni · rk aggiorna)\n' "$(_rk_n '1;35')" "$(_rk_n 0)"
      cat <<'EOF'
  rk info · rk top     statistiche · monitor dal vivo
  rk gpu · rk boost    prova GPU · diagnosi velocita'
  rk pulizia           report del disco · rk pulisci = pulizia sicura
  rk log               ultimi avvii (UnaVolta) e errori di TouchPad
  rk aggiorna          aggiorna RunnerKit (e ricarica il terminale)
  rk versioni          versioni installate
  touchpad             mouse, tasto destro, tastiera, pallini
  aiphone FILE         copia verso l'app File dell'iPhone · dalliphone apre la cartella
  aggiorna             aggiorna Debian · installa/cerca/rimuovi PACCHETTO
  estrai FILE · mkcd   estrae qualsiasi archivio · crea ed entra in una cartella
  rk centro [pulizia|processi]  finestra con sistema, pulizia e processi
  rk collaudo          prova tutto sul telefono e salva un report da mandare
  rk backup · rk ripristina   salva/ripristina impostazioni e file (cartella dell'app File)
  rk copia TESTO · rk incolla  appunti condivisi con l'iPhone (anche: comando | rk copia)
  rk italiano [off]    Linux in italiano
  rk fisso on|off      barra di stato fissa in cima al terminale
  rk disinstalla       toglie RunnerKit e rimette tutto come prima
  clear (o Ctrl+L)     pulisce lo schermo, la barra resta
EOF
      ;;
  esac
}

# clear e Ctrl+L puliscono lo schermo ma la schermata RunnerKit resta sempre in alto
clear() {
  command clear 2>/dev/null || printf '\033[H\033[2J'
  if [[ ${RK_FISSO:-1} == 1 && -t 1 ]]; then
    _rk_fisso; printf '\033[%d;1H' $((_RK_H + 1))      # barra subito in cima, cursore sotto
  elif [[ ${RK_BANNER:-1} = 1 ]]; then rkinfo; fi
}
bind -x '"\C-l": clear' 2>/dev/null

# all'apertura: barra fissa in cima e statistiche complete sotto
if [[ ${RK_FISSO:-1} == 1 && -t 1 ]]; then clear; fi
if [[ ${RK_BANNER:-1} = 1 ]]; then rkinfo; fi
