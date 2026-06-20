# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Personal macOS configuration files — dotfiles, shell scripts, and application settings — deployed via symlinks. No build system or tests.

## Key Conventions

**Dotfiles**: `install.sh` symlinks every file in `dotfiles/` to `~/.<filename>` (adds a dot prefix). `bash_profile` is the shell entry point.

**Shell loading chain**: `bash_profile` sources all of `bash.d/*` in glob order (numbered files like `1-functions.sh` load first), then adds `scripts/` to `$PATH`, then sources all of `~/.bash.d/*` for machine-local overrides not tracked in this repo.

**Application configs**: `Application-Config/install-application-configs.sh` auto-discovers and runs every `install.sh` one level below it. Each sub-`install.sh` symlinks its sibling files into the app's support directory (e.g. `VisualStudioCode/` → `~/Library/Application Support/Code/User/`). These scripts can call `create_link` directly — it's available because `bash.d/1-functions.sh` is already sourced by the time they run.
