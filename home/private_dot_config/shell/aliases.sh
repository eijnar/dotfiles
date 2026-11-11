# Aliases shared by bash and zsh. Managed by chezmoi: edit with `chezmoi edit`.

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Servers often lack the terminfo for alacritty or tmux-256color, which garbles
# backspace, less and vim there. Every server knows xterm-256color, so ssh gets
# that instead. The local TERM is unchanged, and nothing on the servers changes.
ssh() {
  case ${TERM:-} in
    alacritty*|tmux*|screen*) TERM=xterm-256color command ssh "$@" ;;
    *) command ssh "$@" ;;
  esac
}
