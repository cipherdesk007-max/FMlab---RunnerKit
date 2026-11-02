# RunnerKit Terminale - prompt, colori, statistiche e scorciatoie per bash su LinuxRunner.
# Caricato da ~/.bashrc. Tutto e' scritto in bash puro, leggendo /proc: niente programmi
# lanciati a ogni prompt, perche' su LinuxRunner ogni processo costa.
case $- in *i*) ;; *) return ;; esac
RK_TERM_VERSIONE="1.0.0"

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
  local k v t=0 a=0
  while read -r k v _; do
    case $k in MemTotal:) t=$v ;; MemAvailable:) a=$v ;; esac
  done < /proc/meminfo
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
  echo '  ╭─ RunnerKit ─────────────────────────────╮'
  printf '  │ %-40s│\n' "$(date '+%A %d %B, %H:%M')"
  echo '  ╰─────────────────────────────────────────╯'
  printf '%s' "$(_rk_n 0)"
  printf '  RAM    %s  %s/%s MB\n' "$(_rk_barra "$pct")" "$used" "$total"
  [[ -n $dp ]] && printf '  Disco  %s  %s/%s GB\n' "$(_rk_barra "${dp%\%}")" "$du" "$dt"
  printf '  Acceso da %s · carico %s · processi %s\n' "$(_rk_uptime)" "${load:-?}" "${procs#*/}"
  [[ -n $jit ]] && printf '  JIT: %s\n' "$jit"
  printf '  %sComandi RunnerKit: rk%s\n' "$(_rk_n 2)" "$(_rk_n 0)"
}

# ---------- monitor dal vivo ----------
rktop() {
  local used total pct load
  trap 'printf "\033[?25h"; return' INT
  printf '\033[?25l'
  while :; do
    read -r used total pct <<< "$(_rk_ram)"
    read -r load _ < /proc/loadavg
    printf '\033[H\033[2J%sRunnerKit monitor%s  (Ctrl+C per uscire)\n\n' "$(_rk_n '1;35')" "$(_rk_n 0)"
    printf '  RAM    %s  %s/%s MB\n' "$(_rk_barra "$pct" 30)" "$used" "$total"
    printf '  Carico %s\n\n' "$load"
    ps -eo pid,rss,pcpu,comm --sort=-rss 2>/dev/null | awk 'NR==1{printf "  %6s %8s %6s  %s\n","PID","RAM MB","CPU%","PROGRAMMA"; next} NR<=12 {printf "  %6s %8.0f %6s  %s\n",$1,$2/1024,$3,$4}'
    sleep 3
  done
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
PROMPT_COMMAND=_rk_prompt

# ---------- scorciatoie ----------
alias ll='ls -lh' la='ls -lAh' l='ls -CF'
alias ..='cd ..' ...='cd ../..' ....='cd ../../..'
alias aggiorna='apt update && apt full-upgrade -y'
alias installa='apt install' cerca='apt search' rimuovi='apt remove'
alias spazio='df -h /' memoria='free -h'
alias boost='runnerboost' pulisci='pulizia'
alias rkaggiorna='curl -fsSL https://raw.githubusercontent.com/cipherdesk007-max/mia/main/install.sh | sh'
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
rk() {
  printf '%sRunnerKit%s — comandi\n' "$(_rk_n '1;35')" "$(_rk_n 0)"
  cat <<'EOF'
  touchpad          mouse, tasto destro e tastiera touch (pallino nell'angolo)
  unavolta --log    cosa e' successo agli ultimi avvii (anti doppia apertura)
  pulizia           report disco · pulizia --sicura per pulire
  runnerboost       diagnosi velocita' · runnerboost --test per misurare
  rkinfo / rktop    statistiche · monitor dal vivo
  aiphone FILE      copia verso l'app File dell'iPhone · dalliphone per aprire la cartella
  aggiorna          aggiorna Debian · rkaggiorna aggiorna RunnerKit
  estrai FILE       estrae qualsiasi archivio · mkcd DIR crea ed entra
EOF
}

[[ ${RK_BANNER:-1} = 1 ]] && rkinfo
