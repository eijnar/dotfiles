# dotfiles

My shell, tmux, vim and git setup, plus per-machine extras, managed with
[chezmoi](https://www.chezmoi.io/). Arch Linux everywhere, including WSL.

## Quick setup

```sh
# Arch (also WSL), logged in as yourself with sudo:
sudo pacman -Syu --needed chezmoi git
chezmoi init --apply eijnar        # add --branch chezmoi until it's merged to main
exec bash -l                       # or open a new terminal: you land in zsh
```

Machine already has configs you care about? Run `chezmoi init eijnar`, then
`chezmoi diff`, then `chezmoi apply`. Later: `chezmoi update` pulls and applies.

## New machine

```sh
sudo pacman -Syu --needed chezmoi git
chezmoi init --apply eijnar
```

To try a branch before it's merged: `chezmoi init --apply --branch <branch> eijnar`.

That clones this repo to `~/.local/share/chezmoi` and sets the machine up:

1. **Asks for a git identity, on work machines only.** It's stored in that
   machine's `~/.config/chezmoi/chezmoi.toml`, never in this repo.
2. **Installs the packages** in [`packages.yaml`](home/.chezmoidata/packages.yaml),
   only the missing ones. This needs sudo. Skip it with
   `DOTFILES_SKIP_PACKAGES=1 chezmoi apply`.
3. **Writes the configs**, and clones the tmux plugins and the vim
   colorscheme.
4. **Runs the per-machine setup**: the ssh-agent user service, a PipeWire
   restart for the audio config, and the morbit-setup offer.

Existing files are overwritten: back up your current `~/.zshrc`,
`~/.tmux.conf`, `~/.vimrc` and `~/.gitconfig` first, or run
`chezmoi init eijnar`, then `chezmoi diff`, then `chezmoi apply`.
`~/.bash_profile` is only created if it's missing. `~/.bashrc` is rebuilt
(see [Shells](#shells-bash-hands-over-to-zsh)): from an existing one, only the
marked blocks other tools wrote (`# >>> name … >>>` to `# <<< name <<<`) are
kept, so move anything else to `~/.config/shell/local.d/` first.

On a fresh WSL install, run `pacman -Syu` first: the image's package database
is usually old.

## Day to day

| Task | Command |
|---|---|
| Edit a config | `chezmoi edit ~/.tmux.conf`, then `chezmoi apply` |
| Edited a plain file in `~` directly (`.vimrc`, `starship.toml`, `~/.local/bin/*`, the audio configs) | `chezmoi re-add ~/.vimrc` |
| Edited a template (`.zshrc`, `.tmux.conf`, `.gitconfig`) in `~` | `chezmoi merge ~/.zshrc`, or redo it with `chezmoi edit` (re-add skips templates) |
| See pending changes | `chezmoi diff` |
| Pull the repo and apply | `chezmoi update` |
| Go to the repo | `chezmoi cd` (then commit and push as usual) |

## Machines

[`machines.yaml`](home/.chezmoidata/machines.yaml) lists the home machines by
short hostname, with flags for what each one gets. Anything not listed, and
every WSL install whatever its hostname, gets the `default` profile. That
profile is work-safe: no SSH or morbit, no home hardware, and the git identity
is asked once. Commits to this repo always use the personal identity, also on
work machines.

| | strumpdator | default (work, WSL, unknown) |
|---|---|---|
| zsh (via bash), starship, fastfetch, tmux, vim, git | ✓ | ✓ |
| `jaktkollen` | ✓ | ✓ |
| Scarlett 4i4 PipeWire split + pro-audio lock | ✓ | |
| WirePlumber: disable unused sound cards | ✓ | |
| `monitor_on` / `monitor_off` / `monitor-toggle` | ✓ | |
| `whitelight`, Hack Nerd Font | ✓ | |
| ssh-agent user service | ✓ | |
| morbit in zsh, morbit-setup offer | ✓ | |
| GitHub SSH via the YubiKey (`~/.ssh/config` block, `ssh-keygen -K` offer) | ✓ | |

To add a home machine, add it under `hosts` with the flags that differ from
`default`, push, and run `chezmoi init --apply eijnar` on it. Never list work
machines: this repo is public.

## Shells: bash hands over to zsh

The login shell stays `/bin/bash`, as set in FreeIPA. Setting zsh there would
break logins on machines without zsh. Instead, `~/.bashrc` replaces an
interactive bash in a terminal with zsh, when zsh is installed. bash stays when:

- it runs a command (`bash -c`, `bash -ic`), or stdin isn't a terminal
  (scp, rsync, scripts),
- it was started from zsh (typing `bash` in zsh),
- it runs a script (`bash -i script.sh`),
- zsh or `~/.zshrc` is missing, or zsh fails to start,
- `DOTFILES_NO_ZSH` is set: `DOTFILES_NO_ZSH=1 bash`, `DOTFILES_NO_ZSH=1 exec bash`
  to switch in place, or over SSH: `ssh -t host env DOTFILES_NO_ZSH=1 bash -l`.

`~/.bashrc` is rebuilt on every apply: the part above its "Kept on chezmoi
apply" line comes from this repo, and everything below that line is kept, so
lines installers append survive. Edit it with `chezmoi edit ~/.bashrc`, and
never `chezmoi add`/`re-add` it (that would replace the template with a copy of
your local file).

Turn the handoff off for a machine with `zsh: false` in `machines.yaml`.

Shared settings are in `~/.config/shell/env.sh` and `aliases.sh`. **Machine-local
settings** (anything that must not be in this public repo) go in
`~/.config/shell/local.d/*.sh`, which bash and zsh both source, and in
`~/.config/git/local` for git.

## morbit

The `morbit` flag makes zsh load the env block that `bin/morbit-setup` (in the
infrastructure repo) writes into `~/.bashrc`, under ksh emulation. That needs
the zsh support in `bin/morbit-env.sh` (until that checkout has it, zsh skips
morbit with a one-line note and `morbit-*` work in bash). Settings such as
`MORBIT_SSH_BASTION` go in `~/.config/shell/local.d/morbit.sh`: a line after the
block in `~/.bashrc` is never seen by zsh. You're offered a morbit-setup run
(SSH config, jump hosts) once the infrastructure repo is checked out at
`~/Projects/infrastructure`. The SSH config for the servers comes from
morbit-setup, not from here.

## GitHub with the YubiKey

On machines with `github_yubikey: true`, git talks to GitHub with a FIDO2 key
that lives on the YubiKey (`ssh:github`, separate from the morbit keys):

- The first apply offers `cd ~/.ssh && ssh-keygen -K`. It asks for the
  YubiKey PIN, then a passphrase per key file: use the one in Bitwarden.
- `~/.ssh/config` gets one marked block (`# >>> dotfiles: github …`) pointing
  at `~/.ssh/id_ed25519_sk_rk_github` with `AddKeysToAgent yes`. Nothing else
  in that file is touched. You type the passphrase once per login, then
  every push needs a touch.
- On a server: `ssh -A server` for that session, and touch the key at your
  desk when git asks. Servers that only pull get their own read-only deploy key.
- Work machines never get anything under `~/.ssh` from this repo.

## Layout

```
.chezmoiroot                 chezmoi's source is in home/
home/
  .chezmoi.toml.tmpl         init: git identity on unlisted machines
  .chezmoidata/              machines.yaml, packages.yaml, tools.yaml (git, tmux plugins)
  .chezmoitemplates/         machine.json: this machine's flags
  .chezmoiignore             files only some machines get
  .chezmoiexternal.toml.tmpl tmux plugins, nord-vim
  .chezmoiscripts/           packages, ssh-agent, PipeWire restart, morbit offer
  modify_private_dot_bashrc  ~/.bashrc (managed part + what other tools add)
  create_private_dot_bash_profile  ~/.bash_profile, only if missing
  private_dot_ssh/modify_private_config  the GitHub block in ~/.ssh/config
  dot_zshrc.tmpl, dot_tmux.conf.tmpl, dot_vimrc, dot_gitconfig.tmpl, …
archive/hyprland/            old Hyprland/waybar/kitty/foot/wpaperd configs (not installed)
```
