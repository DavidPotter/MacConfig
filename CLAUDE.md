# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Personal macOS configuration files — dotfiles, shell scripts, and application settings — deployed via symlinks. No build system or tests.

## Key Conventions

**Dotfiles**: `install.sh` symlinks every file in `dotfiles/` to `~/.<filename>` (adds a dot prefix), **except** the shell loaders `bash_profile` and `zshrc`. Those two are installed as local files in `$HOME` (via `install_shell_loader`) that *source* the repo loader, rather than symlinks into the repo — so machine-local lines that tool installers append to `~/.bash_profile`/`~/.zshrc` never get written back through a symlink into version control. `scripts/migrate-bash-profile-stub` and `scripts/migrate-zshrc-stub` convert older installs to this scheme.

**Shell config is split three ways** so bash and zsh share everything portable and differ only where they must:

- `shell.d/` — shell-agnostic core (functions, env, `PATH`, aliases, ruby). Sourced by **both** shells. Must stay polyglot: POSIX-compatible bash/zsh (no `[[ == ]]`, no bash-only array/word-split idioms). Numbered files (`1-`, `2-`, …) load first in glob order.
- `bash.d/` — bash-only adapters (`completion.sh`, `history.sh`, `prompt.sh`) using readline / `PROMPT_COMMAND`.
- `zsh.d/` — zsh-only adapters (`1-completion.zsh`, `2-history.zsh`, `3-prompt.zsh`, `4-zle.zsh`) using compinit / `PROMPT` / `zle`. Numbering is single-digit to match `shell.d`/`bash.d`.

**Shell loading chain**:
- `dotfiles/bash_profile` sources `shell.d/*` then `bash.d/*` (glob order), adds `scripts/` to `$PATH`, then sources `~/.shell.d/*` (shared machine-local) then `~/.bash.d/*` (bash-only machine-local), neither tracked here.
- `dotfiles/zshrc` sources `shell.d/*` then `zsh.d/*` (using a `(.N)` glob), adds `scripts/` to `$PATH`, then sources `~/.shell.d/*` and `~/.zsh.d/*` for machine-local overrides. It locates the repo root with zsh's `%x` prompt expansion (`${${(%):-%x}:A:h:h}`) and **guards `brew shellenv`** so it doesn't re-run (and reorder `$PATH`) when `~/.zprofile` already ran it.
- `~/.shell.d/*` is the shared machine-local drop-in sourced by **both** loaders, so config that applies to both shells (e.g. `go`/`nvm` PATH setup) is written once. `~/.bash.d/*` and `~/.zsh.d/*` hold shell-specific machine-local config. As with `shell.d/`, files in `~/.shell.d/` must be polyglot.

**`inputrc` is bash-only**: `dotfiles/inputrc` configures GNU readline. zsh ignores it; the equivalent keybindings are reconstructed in `zsh.d/4-zle.zsh`. Keep the two in sync when changing key bindings.

**Application configs**: `Application-Config/install-application-configs.sh` auto-discovers and runs every `install.sh` one level below it. Each sub-`install.sh` symlinks its sibling files into the app's support directory (e.g. `VisualStudioCode/` → `~/Library/Application Support/Code/User/`). These scripts can call `create_link` directly — it's available because `shell.d/1-functions.sh` is already sourced by the time they run.
