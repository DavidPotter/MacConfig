#!/bin/sh

#
# install-python.sh
#   Installs uv (via Homebrew) and uses it to install Python and make it the
#   default `python` / `python3`.
#
#   Plain POSIX sh: it is verified to run under /bin/sh (dash and bash --posix),
#   bash, and zsh -- no bashisms.  (`date -j` below is BSD/macOS-only, which is
#   fine because this repo only targets macOS.)
#
#   Run it directly (`sh install-python.sh`) or let install-tools.sh run it.
#   Re-running it is safe, and is also how you move to a newer Python later.
#
#   PATH: this script deliberately does NOT run `uv python update-shell`.  That
#   command appends `export PATH="$HOME/.local/bin:$PATH"` to ~/.zshenv (zsh)
#   or ~/.bash_profile and ~/.bashrc (bash), and fails outright when run from
#   plain sh.  The repo's shell.d/3-path.sh already adds ~/.local/bin to PATH
#   for both bash and zsh (deduplicated, and only once the directory exists),
#   so the extra lines would be redundant and would bypass that logic.
#   (3-path.sh puts ~/.local/bin at the FRONT of PATH so that uv's `python` and
#   `python3` win over the stubs in /usr/bin.)
#
#   Version policy: installs the newest stable Python only once it is at least
#   MIN_AGE_DAYS (60) days old; before that it installs the previous minor
#   version.  See the comment above MIN_AGE_DAYS for why.
#

# Make sure brew is reachable.  A non-login shell (or a fresh machine where
# Homebrew was just installed) may not have it on PATH yet.
if ! command -v brew > /dev/null 2>&1; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo '** Homebrew not installed yet. Aborting.' >&2
    exit 1
  fi
fi

brew install uv

# Why wait: a brand-new Python feature release (3.x.0) ships before the rest of
# the ecosystem is ready.  Third-party packages, especially ones with compiled
# extensions, often have no prebuilt wheels for it yet, so installs fall back to
# building from source or simply fail, and the first patch releases still fix
# early bugs.  Waiting about two months lets that settle, so until the newest
# version is at least MIN_AGE_DAYS old we install the previous one instead.
MIN_AGE_DAYS=60

# Newest stable Python version uv can install, and the one before it
VERSIONS=$(uv python list --only-downloads \
  | grep -oE '^cpython-3\.[0-9]+\.[0-9]+-' \
  | cut -d- -f2 | cut -d. -f1,2 | sort -u -t. -k2,2n | tail -2)
PREV=$(echo "$VERSIONS" | head -1)
LATEST=$(echo "$VERSIONS" | tail -1)

# When the newest version was first released
RELEASED=$(curl -fsS "https://endoflife.date/api/python/$LATEST.json" \
  | sed -nE 's/.*"releaseDate": *"([0-9]{4}-[0-9]{2}-[0-9]{2})".*/\1/p')

if [ -n "$RELEASED" ]; then
  AGE_DAYS=$(( ( $(date +%s) - $(date -j -f %Y-%m-%d "$RELEASED" +%s) ) / 86400 ))
else
  AGE_DAYS=0   # date unavailable: play it safe and treat as brand-new
fi

if [ "$AGE_DAYS" -ge "$MIN_AGE_DAYS" ]; then
  PY_VERSION=$LATEST
else
  PY_VERSION=$PREV
fi

echo "Python $LATEST released ${RELEASED:-unknown} ($AGE_DAYS days ago); installing $PY_VERSION"
uv python install "$PY_VERSION" --default
