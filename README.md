## My .zshrc config

### Example functions

väder() {
  curl wttr.in/Linköping
}

stock() {
  tickrs -s $1
}

qr() { curl "qrenco.de/$1" }

yeet() {
  git add -A
  git commit -m "${1:-quick save}"
  git push
}

ff() { find . -iname "*$1*" 2>/dev/null }

up() { local d=""; for ((i=0; i<${1:-1}; i++)); do d="../$d"; done; cd "$d" || return; }
