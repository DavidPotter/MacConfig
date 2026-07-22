# Migrating from bash to zsh

This document explains how this repo was restructured to support zsh alongside
bash, the reasoning behind each decision, and the concrete steps to move a
machine from bash to zsh. Both shells are supported **indefinitely** — bash
remains a fully working fallback, so this is a safe, reversible migration.

---

## 1. Why anything had to change

The original repo was bash-only:

- `dotfiles/bash_profile` was the single entry point.
- All configuration lived in `bash.d/*`, sourced by that profile.
- `dotfiles/inputrc` configured line-editing keys.

macOS already uses **zsh** as the default login shell; the only reason this
setup ran bash was that the Terminal "Grass" profile was configured to launch
`bash` explicitly. So "migrating to zsh" really means: stop forcing bash in the
Terminal profile, and give zsh an equivalent configuration.

The goal was to keep the zsh experience **as close to the bash one as
possible** while not duplicating the parts that are genuinely shell-agnostic.

---

## 2. The new layout

Configuration is split into three directories so the shells share everything
portable and diverge only where they must:

```
shell.d/     ← shared core, sourced by BOTH shells
  1-functions.sh   addToPathIfExists, up, pman, create_link, startAndroid
  2-env.sh         LSCOLORS, PAGER, JAVA_HOME, Android, Perforce, LastPass
  3-path.sh        Xcode, VS Code, Yarn, Android, ~/.local/bin, ~/bin
  aliases.sh       cd shortcuts, ls/dir, grep colors, network, Finder toggles
  ruby.sh          RVM

bash.d/      ← bash-only adapters
  completion.sh    git-completion, npm, yarn, bash-completion, complete -d
  history.sh       HISTSIZE/HISTCONTROL/HISTTIMEFORMAT + histappend
  prompt.sh        readline colors + PROMPT_COMMAND driven PS1

zsh.d/       ← zsh-only adapters
  1-completion.zsh compinit + zstyle (case-insensitive, menu) + compdef
  2-history.zsh    HISTFILE/HISTSIZE/SAVEHIST + share/extended/dedup setopts
  3-prompt.zsh     PROMPT_SUBST + single static PROMPT string
  4-zle.zsh        bindkey reconstruction of inputrc (incl. Home/End)

dotfiles/bash_profile  ← bash loader: shell.d/* then bash.d/*
dotfiles/zshrc         ← zsh loader:  shell.d/* then zsh.d/*
dotfiles/inputrc       ← bash only (readline); zsh ignores it entirely
```

Both loaders end by sourcing machine-local directories that are **not** tracked
in this repo:

- bash: `~/.bash.d/*`
- zsh: `~/.shell.d/*` then `~/.zsh.d/*`

The numbering (`1-`, `2-`, …) is single-digit and **matches across all three
directories**, so load order is obvious no matter which shell you're reading.

### Why a shared core instead of duplicating

The functions, env vars, PATH logic, aliases, and Ruby setup have nothing
shell-specific about them. Duplicating them into `zsh.d/` would mean every
future change has to be made twice and kept in sync by hand. Putting them in
`shell.d/` — sourced verbatim by both loaders — means a change to an alias or a
`PATH` entry is picked up by both shells automatically.

The price is that `shell.d/` files must be **polyglot**: they cannot use
bash-only syntax. The one place this bit us was a `[ "$X" == "Y" ]` test in
`2-env.sh` (zsh's `[` rejects `==`), rewritten to POSIX `[ "$X" = "Y" ]` plus
`command -v`. `addToPathIfExists` was likewise rewritten to use a
colon-substring test instead of bash array splitting.

---

## 3. How the two loaders differ (and why)

Most of the loader logic is identical in spirit; a few things had to change
because zsh is not bash:

| Concern | bash (`bash_profile`) | zsh (`zshrc`) | Why |
| --- | --- | --- | --- |
| Find repo root | `${BASH_SOURCE[0]}` + readlink loop | `${${(%):-%x}:A:h:h}` | zsh has no `BASH_SOURCE`; `%x` is the running file, `:A` canonicalizes symlinks, `:h:h` climbs two dirs. `%N` would give the *function* name inside a function, so `%x` is required. |
| Source a directory | `for f in $1` (glob in a string) | `for f in "$1"/*(.N)` | zsh does **not** expand a glob stored in a variable. `(.N)` = regular files only (`.`), null-glob (`N`) so a missing/empty dir is silently skipped. |
| Keep `PATH` unique | manual substring check | same check **plus** `typeset -U path` | zsh can tie `$PATH` to a deduped array; belt-and-suspenders against duplicates. |
| Remove helper functions | `unset name` | `unset -f name` | In zsh, `unset name` removes only variables, never functions. |
| `brew shellenv` | run unconditionally | **guarded**: only if `$HOMEBREW_PREFIX` is unset | See the warning below. |

### ⚠️ The `brew shellenv` guard (important)

On this machine `~/.zprofile` already runs `eval "$(brew shellenv)"` and then
prepends `~/.sf-pin/bin` to `$PATH` to pin a Salesforce CLI node version. If the
zsh loader re-ran `brew shellenv`, it would re-prepend `/opt/homebrew/bin` **in
front of** `~/.sf-pin/bin`, demoting the pin and reintroducing a node@26 crash.

The loader therefore only runs `brew shellenv` when `$HOMEBREW_PREFIX` is empty
(i.e. it hasn't already run). This was verified: with `HOMEBREW_PREFIX` preset,
`/opt/homebrew/bin` appears exactly once in `$PATH` after sourcing the loader.

---

## 4. The prompt

The bash prompt is built imperatively in a `PROMPT_COMMAND` hook so it can read
`$?` and conditionally append the exit code. zsh doesn't need a hook — prompt
escapes read shell state at display time — so a single static `PROMPT` string
reproduces it exactly:

```
[HH:MM:SS] user@host:cwd (git-branch state) (exit-code) >
```

Escape translation:

| bash | zsh | meaning |
| --- | --- | --- |
| `\t` | `%*` | time |
| `\u@\h` | `%n@%m` | user@host |
| `\w` | `%~` | cwd with `~` |
| `\[\e[0;32m\]` | `%F{green}` … `%f` | color on/off |
| `\[\e[38;5;240m\]` | `%F{240}` | dim gray |
| `if [ $? -ne 0 ]; …` | `%(?..X)` | show `X` only when `$?` ≠ 0 |

Two subtleties:

- `setopt PROMPT_SUBST` is required so `$(__git_ps1 …)` runs on every redraw.
- Inside `%(?..X)`, the closing paren of a literal `(code)` must be written
  `%)` or zsh reads it as the end of the conditional. The correct exit-code
  segment is `%(?.. %F{240}(%?%)%f)`.

`git-prompt.sh` is already dual bash/zsh, so it is sourced verbatim in both —
no `vcs_info` rewrite needed.

---

## 5. History: "live shared history" (a question you asked)

**What you chose:** live shared history — a command run in one terminal is
immediately available in another.

**Is it standard zsh behavior?** No. It's a well-supported, very common opt-in,
but it is **not** on by default. It's enabled with `setopt SHARE_HISTORY`.
`zsh.d/2-history.zsh` enables it along with:

- `EXTENDED_HISTORY` — record a timestamp with each command (the analog of
  bash's `HISTTIMEFORMAT`).
- `HIST_IGNORE_DUPS` — don't record a command identical to the one before it
  (analog of bash's `HISTCONTROL=ignoredups`).
- `HIST_REDUCE_BLANKS` — trim redundant whitespace before saving.
- `APPEND_HISTORY` — append rather than overwrite (implied by `SHARE_HISTORY`,
  stated for clarity; analog of bash's `shopt -s histappend`).

**Can bash do it?** Only approximately. bash has no true shared history; the
usual trick is `PROMPT_COMMAND='history -a; history -c; history -r'`, which
flushes and re-reads the history file on every prompt. It works but has rough
edges: it interleaves *all* sessions' commands into one timeline, re-reads the
whole file each prompt, and interacts awkwardly with `HISTCONTROL`. The current
bash config deliberately does **not** do this — it uses plain `histappend`, so
each bash session keeps its own ordering and merges on exit. This is one of the
few places the two shells intentionally behave differently.

**Community feedback / trade-offs to be aware of:**

- The main complaint about `SHARE_HISTORY` is that up-arrow can surface a
  command you just ran in a *different* window, which some people find
  disorienting. If that bothers you, the common middle ground is to drop
  `SHARE_HISTORY` but keep `INC_APPEND_HISTORY` (write immediately, but only
  *import* other sessions' history on shell start). Easy to switch later by
  editing `zsh.d/2-history.zsh`.
- `HIST_IGNORE_DUPS` only collapses *consecutive* duplicates. If you want to
  drop *all* earlier duplicates, `HIST_IGNORE_ALL_DUPS` is the stronger option.
- If you ever share screenshots/screen-shares, remember shared history means
  another window's secrets could appear on up-arrow.

---

## 6. Word motion: how zsh defaults differ (a question you asked)

**What you chose:** learn the zsh defaults rather than force bash-identical
behavior. So `WORDCHARS` is left at its zsh default and **not** overridden.

**How they differ:** "word" means different things to readline (bash) and zle
(zsh) when you use word motions (`Ctrl`/`Alt`-arrow, `Ctrl-W`, `Alt-B/F`,
`Alt-D`):

- **readline / bash** treats a word as *alphanumerics only*. Every run of
  punctuation is its own boundary, so word motion stops at almost every symbol.
  Jumping across `foo-bar.baz/qux` takes several hops.
- **zle / zsh** additionally treats the characters in `$WORDCHARS` as part of a
  word. The default `WORDCHARS` is:

  ```
  *?_-.[]~=/&;!#$%^(){}<>
  ```

  So `foo-bar.baz/qux` is (mostly) **one** word — motions are coarser and jump
  farther. In practice: `Ctrl-W` in zsh deletes more at once, and
  `Alt-B`/`Alt-F` skip over paths and hyphenated names in a single move.

If the coarser behavior ever gets annoying, you can make zsh behave more like
bash by shrinking `WORDCHARS` in `zsh.d/4-zle.zsh`, e.g.:

```zsh
# Make word motion stop at path separators and dots, like readline.
WORDCHARS='*?_-~=&;!#$%^(){}<>'
```

For now it is intentionally left alone.

### Keybindings generally

`dotfiles/inputrc` has **zero effect** in zsh — it configures readline, and zsh
uses its own line editor (`zle`). Every binding was reconstructed in
`zsh.d/4-zle.zsh` with `bindkey`, mirroring the escape sequences in `inputrc`:

- Up/down = history search anchored to what you've typed
  (`up-line-or-beginning-search` ≈ readline's `history-search-backward`).
- Ctrl/Alt-arrow = word motion.
- Delete / Insert.
- Home/End = start/end of line, covering every common escape variant.
- Space = `magic-space` (history expansion).

> When you change a key binding, change it in **both** `dotfiles/inputrc` (bash)
> and `zsh.d/4-zle.zsh` (zsh) to keep the shells in sync.

---

## 7. Home / End keys (fixed as a prerequisite)

While preparing this migration we discovered that plain Home/End never worked
in the existing bash setup either: the Terminal "Grass" profile sends `\e[1~` /
`\e[4~`, which `inputrc` didn't bind. That was fixed independently and
committed first, binding every common Home/End escape variant in `inputrc`
(bash) and later in `zsh.d/4-zle.zsh` (zsh). So both shells now get working
Home/End regardless of terminal.

---

## 8. Installer changes

- `install.sh` gained a generic `install_shell_loader <rc-file> <loader-line>`
  (replacing the bash-specific `install_bash_profile_stub`). It installs both
  `~/.bash_profile` and `~/.zshrc` as local files that source the repo loader,
  injecting the loader line at the top of an existing rc file (preserving the
  rest) and never clobbering hand-written content. It is idempotent.
- Both loaders (`bash_profile`, `zshrc`) are excluded from the dotfile symlink
  loop, since they're installed as stubs.
- Dead code removed: the `/bashrc` special-case (there is no `bashrc` in
  `dotfiles/`) and the `Library/Services/*.workflow` loop (no such directory).
- New `scripts/migrate-zshrc-stub` injects the loader into an existing
  `~/.zshrc`, backing it up first; safe to run repeatedly.
- `git-flow` was removed entirely (no longer used): from `install-tools.sh`,
  `bash.d/completion.sh`, and the README.
- Fixed `scripts/term`'s shebang from `#!/bin/sh` to `#!/bin/bash` (it uses
  `[[ ]]` and a C-style `for`).

---

## 9. Migrating a machine, step by step

This is safe and reversible — bash stays fully configured the whole time.

1. **Pull the repo** so the machine has `shell.d/`, `zsh.d/`, `dotfiles/zshrc`,
   and the updated `install.sh`:

   ```bash
   cd ~/bin/MacConfig && git pull
   ```

2. **Install the zsh loader** into `~/.zshrc` (preserves existing lines):

   ```bash
   ~/bin/MacConfig/scripts/migrate-zshrc-stub
   ```

   (Or re-run `install.sh`, which now installs both loaders.)

3. **Reconcile machine-local config.** If this machine has bash-only local
   files in `~/.bash.d/` that should apply to zsh too (e.g. `go.sh`, `nvm.sh`),
   move the shell-agnostic ones to `~/.shell.d/` so both shells pick them up;
   leave anything bash-specific in `~/.bash.d/`. zsh-only local config goes in
   `~/.zsh.d/`.

4. **Try zsh without committing to it.** Open a new shell and just run `zsh`, or
   `source ~/.zshrc`. Verify: the prompt looks right (time, user@host, cwd, git
   branch, dim exit code on failure), `path` prints entries one per line, tab
   completion works, Home/End/Ctrl-arrow behave, and history is shared across
   windows.

5. **Flip the Terminal profile to stop forcing bash.** In Terminal ▸ Settings ▸
   Profiles ▸ (your profile) ▸ Shell, change "Run command" away from launching
   `bash` so the profile uses the default login shell (zsh). Alternatively set
   the login shell explicitly:

   ```bash
   chsh -s /bin/zsh
   ```

6. **Live in it.** Everything shared comes from `shell.d/`; anything that feels
   off in zsh is almost certainly in one of the four `zsh.d/` adapters.

### Rolling back

Because nothing about bash was removed:

- Point the Terminal profile back at `bash` (or `chsh -s /bin/bash`).
- `~/.bash_profile` still sources `dotfiles/bash_profile`, which still sources
  `shell.d/*` then `bash.d/*`. Nothing to undo.

---

## 10. Verification performed

The zsh loader and adapters were tested in a clean `zsh -f` shell:

- All shared functions present (`addToPathIfExists`, `up`, `pman`,
  `create_link`, `startAndroid`); loader helpers (`__source_dir`, `ROOT_DIR`)
  cleaned up afterward.
- `scripts/` added to `$PATH`; `brew shellenv` guard verified
  (`/opt/homebrew/bin` appears exactly once).
- History options (`share_history`, `extended_history`, `hist_ignore_dups`,
  `hist_reduce_blanks`) all set; `HISTFILE`/`HISTSIZE`/`SAVEHIST` correct.
- Prompt renders correctly, including the git segment and the dim-gray exit
  code shown only on non-zero exit.
- Home/End, arrow, Ctrl-arrow, and `magic-space` bindings all active.
- `install.sh`, `install-tools.sh`, `scripts/migrate-zshrc-stub`, and
  `scripts/term` all pass `bash -n`.
- `migrate-zshrc-stub` verified for the three cases (existing file → injected +
  backed up, re-run → idempotent, missing file → fresh stub).
