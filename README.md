# dotfiles

My shell, tmux, vim and git setup, plus per-machine extras, managed with
[chezmoi](https://www.chezmoi.io/). Arch Linux everywhere, including WSL.

## Quick guide

### Set up a machine

```sh
# Arch (also WSL), logged in as yourself with sudo:
sudo pacman -Syu --needed chezmoi git
chezmoi init --apply eijnar
exec bash -l                       # or open a new terminal: you land in zsh
```

Machine already has configs you care about? Run `chezmoi init eijnar`, then
`chezmoi diff`, then `chezmoi apply`. A new home machine must be listed in
[`machines.yaml`](home/.chezmoidata/machines.yaml) first, or it gets the work
profile.

### Keep a machine up to date

```sh
chezmoi update        # pull this repo and apply it (also installs new packages)
sudo pacman -Syu      # the system itself; reboot after a kernel update
```

chezmoi doesn't update by itself, but new terminals remind you: a line like
`dotfiles: 2 new change(s) on GitHub, run: chezmoi update` when this machine is
behind, or `dotfiles: local changes not pushed yet` when it has dotfiles
changes to commit and push. The check is instant; GitHub is fetched in the
background at most every 4 hours, so a new change shows up within a few hours
(in the terminal after the one that fetched). Turn it off with
`DOTFILES_NO_UPDATE_CHECK=1`.

tmux plugins refresh weekly on `chezmoi update`; `chezmoi update
--refresh-externals` does it now. GNOME keeps its extensions updated itself.

### Change something

1. Change it (see the table), then `chezmoi apply`. `chezmoi diff` shows what
   an apply would do.
2. Save it for the other machines: `chezmoi cd`, then
   `git add -A && git commit -m "..." && git push`, then `exit`.
   This repo is public: no secrets, no work or SSH details.
3. On the other machines: `chezmoi update`.

| To change | How |
|---|---|
| A config file | `chezmoi edit ~/.tmux.conf` |
| A file you already edited in `~` | plain files (`.vimrc`, `starship.toml`, `~/.local/bin/*`, Alacritty, audio): `chezmoi re-add <file>`; templates (`.zshrc`, `.tmux.conf`, `.gitconfig`): `chezmoi merge <file>` |
| `~/.bashrc` | `chezmoi edit ~/.bashrc`, never `chezmoi add` it. Lines just for this machine: `~/.config/shell/local.d/*.sh` |
| Packages | [`packages.yaml`](home/.chezmoidata/packages.yaml); the next apply installs what's missing |
| What a machine gets, or a new machine | [`machines.yaml`](home/.chezmoidata/machines.yaml) |
| pacman options | [`pacman.yaml`](home/.chezmoidata/pacman.yaml) |
| tmux plugins | [`tools.yaml`](home/.chezmoidata/tools.yaml) |
| Alacritty theme | uncomment an `import` line in `~/.config/alacritty/alacritty.toml`, then `chezmoi re-add` it |
| GNOME extension settings | change them in the extension's preferences, then save them to the repo: `dconf dump /org/gnome/shell/extensions/<name>/ > "$(chezmoi source-path)/.chezmoitemplates/gnome/<name>.ini"` |
| GNOME extensions | [`gnome.yaml`](home/.chezmoidata/gnome.yaml) plus a settings `.ini`; the next apply installs them (click Install in GNOME's dialog) |

## New machine

```sh
sudo pacman -Syu --needed chezmoi git
chezmoi init --apply eijnar
```

To try a branch before it's merged: `chezmoi init --apply --branch <branch> eijnar`.

That clones this repo to `~/.local/share/chezmoi` and sets the machine up:

1. **Asks for a git identity, on work machines only.** It's stored in that
   machine's `~/.config/chezmoi/chezmoi.toml`, never in this repo.
2. **Sets pacman options** in `/etc/pacman.conf` from
   [`pacman.yaml`](home/.chezmoidata/pacman.yaml): colour, 10 parallel
   downloads, the old/new version table and the Pac-Man progress bar. Only
   those lines change, and sudo is only asked for when one has to. Checked on
   every apply.
3. **Installs the packages** in [`packages.yaml`](home/.chezmoidata/packages.yaml),
   only the missing ones. This needs sudo. Skip it with
   `DOTFILES_SKIP_PACKAGES=1 chezmoi apply`.
4. **Writes the configs**, and clones the tmux plugins.
5. **Runs the per-machine setup**: the ssh-agent user service, a PipeWire
   restart for the audio config, the YubiKey and morbit-setup offers, the
   Super+Enter shortcut and the GNOME extensions (GNOME asks you to confirm
   each install).

Existing files are overwritten: back up your current `~/.zshrc`,
`~/.tmux.conf`, `~/.vimrc` and `~/.gitconfig` first, or run
`chezmoi init eijnar`, then `chezmoi diff`, then `chezmoi apply`.
`~/.bash_profile` is only created if it's missing. `~/.bashrc` is rebuilt
(see [Shells](#shells-bash-hands-over-to-zsh)): from an existing one, only the
marked blocks other tools wrote (`# >>> name … >>>` to `# <<< name <<<`) are
kept, so move anything else to `~/.config/shell/local.d/` first.

On a fresh WSL install, run `pacman -Syu` first: the image's package database
is usually old.

## Machines

[`machines.yaml`](home/.chezmoidata/machines.yaml) lists the home machines by
short hostname, with flags for what each one gets. Anything not listed, and
every WSL install whatever its hostname, gets the `default` profile. That
profile is work-safe: no SSH or morbit, no home hardware, and the git identity
is asked once. Commits to this repo always use the personal identity, also on
work machines.

| | strumpdator (desktop) | strumptop (laptop) | default (work, WSL, unknown) |
|---|---|---|---|
| zsh (via bash), starship, fastfetch, tmux, vim, git | ✓ | ✓ | ✓ |
| `jaktkollen` | ✓ | ✓ | ✓ |
| tmux mouse: wheel scroll, click pane, drag borders (nothing else) | ✓ | ✓ | ✓ |
| `ssh` sends TERM=xterm-256color from Alacritty/tmux | ✓ | ✓ | ✓ |
| pacman.conf: colour, parallel downloads, version table | ✓ | ✓ | ✓ |
| Scarlett 4i4 split into named devices (while plugged in) + pro-audio lock | ✓ | ✓ | |
| WirePlumber: disable unused sound cards | ✓ | | |
| `monitor_on` / `monitor_off` / `monitor-toggle` | ✓ | | |
| `whitelight` | ✓ | | |
| Alacritty: no border, padding, Hack Nerd Font, light transparency, themes to try | ✓ | ✓ | |
| GNOME shortcut Super+Enter → Alacritty | ✓ | ✓ | |
| GNOME extensions: rounded corners + shadows, Blur my Shell (Alacritty only) | ✓ | ✓ | |
| ssh-agent user service | ✓ | ✓ | |
| morbit in zsh, morbit-setup offer | ✓ | ✓ | |
| YubiKey SSH keys: `setup-yubikey`, GitHub block in `~/.ssh/config` | ✓ | ✓ | |

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

## Focusrite Scarlett 4i4

On machines with `focusrite: true`, the Scarlett is split into Scarlett VoIP
(1+2), Scarlett HiFi (3+4), Front 1, Front 2 and Back 3+4, but only while it is
plugged in. A WirePlumber script
(`~/.local/share/wireplumber/scripts/scarlett-4i4-split.lua`) creates the split
devices when the card shows up and removes them when it goes away, so a laptop
without the Scarlett keeps its own speakers and mic as defaults. The split
itself is defined in `~/.config/wireplumber/wireplumber.conf.d/60-scarlett-4i4-split.conf`.
The card is locked to its pro-audio profile, so GNOME's output list can't switch
it away from what the split needs.

## GitHub with the YubiKey

On machines with `github_yubikey: true`, git talks to GitHub with a FIDO2 key
that lives on the YubiKey (`ssh:github`, separate from the morbit keys):

- `setup-yubikey` fetches the SSH keys stored on the YubiKey into `~/.ssh`
  (GitHub plus the morbit keys morbit-setup needs) and tests GitHub. It asks
  for the YubiKey PIN, then a passphrase per key file: for GitHub, the one in
  Bitwarden. The first apply offers to run it; run it again any time (e.g. the
  YubiKey wasn't plugged in). Key files already in `~/.ssh` are never
  overwritten.
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
  .chezmoidata/              machines.yaml, packages.yaml, pacman.yaml, gnome.yaml, tools.yaml (git, tmux plugins)
  .chezmoitemplates/         machine.json (this machine's flags), gnome/*.ini (extension settings)
  .chezmoiignore             files only some machines get
  .chezmoiremove             files this repo used to install, deleted on apply
  .chezmoiexternal.toml.tmpl tmux plugins
  .chezmoiscripts/           pacman.conf, packages, ssh-agent, PipeWire restart, YubiKey and morbit offers,
                             GNOME shortcut and extensions
  modify_private_dot_bashrc  ~/.bashrc (managed part + what other tools add)
  create_private_dot_bash_profile  ~/.bash_profile, only if missing
  private_dot_ssh/modify_private_config  the GitHub block in ~/.ssh/config
  dot_zshrc.tmpl, dot_tmux.conf.tmpl, dot_vimrc, dot_gitconfig.tmpl, …
archive/hyprland/            old Hyprland/waybar/kitty/foot/wpaperd configs (not installed)
```
