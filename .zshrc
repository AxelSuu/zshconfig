# ─── PERFORMANCE ────────────────────────────────────────────────────────────
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -c '%Y' ~/.zcompdump 2>/dev/null | xargs -I{} date -d @{} +'%j' 2>/dev/null)" ]; then
  compinit
else
  compinit -C
fi

# ─── HISTORY ────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicates
setopt HIST_IGNORE_SPACE      # Commands starting with space aren't saved
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks
setopt INC_APPEND_HISTORY     # Write immediately, not on shell exit
setopt SHARE_HISTORY          # Share history across terminals
setopt HIST_VERIFY            # Show command before running it from history

# ─── COMPLETION ─────────────────────────────────────────────────────────────
zstyle ':completion:*' menu select
zstyle ':completion::complete:*' use-cache yes
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ─── OPTIONS ────────────────────────────────────────────────────────────────
setopt AUTO_CD
setopt AUTO_PUSHD             # cd pushes to stack
setopt PUSHD_IGNORE_DUPS      # No duplicates in stack
setopt PUSHD_SILENT           # Don't print stack after pushd
setopt CORRECT
setopt NO_BEEP
bindkey -e

# ─── PROMPT ─────────────────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ─── PLUGINS ────────────────────────────────────────────────────────────────
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#888888"
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=1
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# ─── MODERN CLI TOOLS ───────────────────────────────────────────────────────
eval "$(zoxide init zsh)" 2>/dev/null
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'
export FZF_CTRL_R_OPTS='--sort --exact'

# ─── ALIASES ────────────────────────────────────────────────────────────────
# Modern replacements (fallback to originals if not installed)
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -la --icons --git'
  alias tree='eza --tree --icons'
else
  alias ls='ls --color=auto -hv'
  alias ll='ls -lah --color=auto'
fi

if command -v batcat &>/dev/null; then
  alias cat='batcat --paging=never'
  alias bat='batcat'
elif command -v bat &>/dev/null; then
  alias cat='bat --paging=never'
fi

command -v rg &>/dev/null && alias grep='rg' || alias grep='grep --color=auto'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias d='dirs -v'
alias c='clear'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -15'
alias gd='git diff'

# Config
alias zrc='code ~/.zshrc'
alias src='source ~/.zshrc'


# ── tmux ──────────────────────────────────────────────────────────────────────

# Smart attach: attach if session exists, create if not
# Usage: t          → attaches to/creates "main"
#        t robot    → attaches to/creates "robot"
function t() {
  local name=${1:-main}
  tmux attach -t "$name" 2>/dev/null || tmux new-session -s "$name"
}

# Kill a session
function tk() {
  local name=${1:-main}
  tmux kill-session -t "$name" && echo "killed: $name"
}

# Fuzzy-pick a session with fzf (falls back to list if no fzf)
function ts() {
  if command -v fzf &>/dev/null; then
    local session
    session=$(tmux ls 2>/dev/null | fzf --height=10 --reverse | cut -d: -f1)
    [[ -n "$session" ]] && tmux attach -t "$session"
  else
    tmux ls 2>/dev/null || echo "no sessions running"
  fi
}

# Quick project launchers — edit these to match your actual paths
function tdev() {
  local name="fintech"
  tmux has-session -t "$name" 2>/dev/null && tmux attach -t "$name" && return

  tmux new-session  -d -s "$name" -n "backend"  -c ~/projects/fintech
  tmux new-window       -t "$name"  -n "frontend" -c ~/projects/fintech
  tmux new-window       -t "$name"  -n "db"       -c ~/projects/fintech
  tmux send-keys    -t "$name:db" "psql" Enter
  tmux select-window    -t "$name:backend"
  tmux attach       -t "$name"
}

function trobot() {
  local name="robot"
  tmux has-session -t "$name" 2>/dev/null && tmux attach -t "$name" && return

  tmux new-session  -d -s "$name" -n "code"   -c ~/projects/robot
  tmux new-window       -t "$name"  -n "pi"     -c ~/projects/robot
  tmux new-window       -t "$name"  -n "serial" -c ~/projects/robot
  # auto-ssh into pi on that window (adjust hostname)
  tmux send-keys    -t "$name:pi" "ssh pi@raspberrypi.local" Enter
  tmux select-window    -t "$name:code"
  tmux attach       -t "$name"
}

# Aliases
alias tl='tmux ls 2>/dev/null || echo "no sessions"'
alias tka='tmux kill-server'                     # nuclear — kills everything
alias tn='tmux new-session -s'                   # tn mysession

# If we're in a terminal (not already in tmux), show active sessions on shell start
if [[ -z "$TMUX" ]] && tmux ls &>/dev/null; then
  echo "── tmux sessions ──"
  tmux ls
  echo "───────────────────"
fi

# ─── FUNCTIONS ──────────────────────────────────────────────────────────────
mkcd() { mkdir -p "$1" && cd "$1" }

extract() {
  case "$1" in
    *.tar.gz|*.tgz) tar xzf "$1" ;;
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.xz) tar xJf "$1" ;;
    *.zip) unzip "$1" ;;
    *.7z) 7z x "$1" ;;
    *.gz) gunzip "$1" ;;
    *) echo "Unknown format: $1" ;;
  esac
}

timer() {
  local secs=$((${1:-25} * 60))
  while [ $secs -gt 0 ]; do
    printf "\r%02d:%02d" $((secs/60)) $((secs%60))
    sleep 1
    ((secs--))
  done
  printf "\r00:00\n" && notify-send "Timer done" 2>/dev/null || echo "\a"
}

take() {
  if [[ $1 =~ ^https?:// || $1 =~ \.git$ ]]; then
    git clone "$1" && cd "$(basename "$1" .git)"
  else
    mkcd "$1"
  fi
}

väder() {
  curl wttr.in/Linköping
}

cheat() { curl "cheat.sh/$1" }

define() { curl "dict.org/d:$1" }

alias myip='curl ifconfig.me'

qr() { curl "qrenco.de/$1" }

rate() { curl "rate.sx/$1" }

alias parrot='curl parrot.live'
alias starwars='telnet towel.blinkenlights.nl'

alias tmap='telnet mapscii.me'

alias co='git checkout'

news() { curl "getnews.tech/${1:-world}" }

stock() {
  tickrs -s $1
}

start() {
  cd kandidat/code
  code .
  
}

# Upload a file directly from the terminal and get a shareable URL back.
# Files are stored for 14 days. Excellent for quick sharing.
transfer() {
  if [ -z "$1" ] || [ ! -f "$1" ]; then
    echo "Usage: transfer <filename>"
    return 1
  fi
  curl --upload-file "$1" "https://transfer.sh/$(basename "$1")"
  echo ""
}

# Go up N directories
up() { local d=""; for ((i=0; i<${1:-1}; i++)); do d="../$d"; done; cd "$d" || return; }

# Lazy commit: stage all, commit, push
yeet() {
  git add -A
  git commit -m "${1:-quick save}"
  git push
}


# Find files by name (fuzzy)
ff() { find . -iname "*$1*" 2>/dev/null }

# Find and open in $EDITOR
fe() { local f=$(fzf --preview 'bat --color=always {}' 2>/dev/null) && [[ -n "$f" ]] && ${EDITOR:-vim} "$f" }


lt() {
  echo "  fun stuff: "
  echo "  stock <ticker> — Graphs and market data for stocks"
  echo "  claude         — claude code"
  echo "  väder          — forecast for Linköping"
  echo "  tmap           — ASCII world map (telnet)"
  echo "  rate <coin>    — currency/crypto rates"
  echo "  "
  echo "  productivity stuff: "
  echo "  qr <url>       — generate QR code in terminal"
  echo "  lazygit        — git TUI"
  echo "  glow <file>    — render markdown in terminal"
  echo "  yeet [msg]     — git add+commit+push"
  echo "  up <n>         — go up N directories"
  echo "  ff <name>      — fuzzy find files"
  
}

# ─── DIRECTORY BOOKMARKS ────────────────────────────────────────────────────
# Customize these to your paths
hash -d code=~/code 2>/dev/null
hash -d proj=~/projects 2>/dev/null
hash -d dl=~/Downloads 2>/dev/null

# ─── ENVIRONMENT ────────────────────────────────────────────────────────────
export EDITOR='nvim'  # Change to your preference
export GPG_TTY=$(tty)
export PATH="$HOME/.local/bin:$PATH"

# NVM (lazy-load)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use

# SSH agent
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" > /dev/null 2>&1
fi
export PATH="/home/axel/.npm-global/bin:$PATH"

lt
