# Environment shared by bash and zsh (interactive shells), sourced from
# ~/.bashrc and ~/.zshrc. Managed by chezmoi: edit with `chezmoi edit`.

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac
export PATH

export EDITOR=vim
export VISUAL=vim

# OpenSSH's ssh-agent user service (ssh-agent.socket, enabled on machines with
# ssh_agent: true). In an SSH session with a forwarded agent, that one is kept.
if { [ -z "${SSH_CONNECTION:-}" ] || [ ! -S "${SSH_AUTH_SOCK:-}" ]; } &&
   [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi
