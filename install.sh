#!/bin/sh -e

#
# install.sh
#   Installs files and creates symbolic links to use the tools in the
#   MacConfig repository.
#
#   The follow steps are performed:
#   - Clone the MacConfig repository to ~/bin/MacConfig.
#   - Create symbolic links for dot files in the home directory.
#   - Create symbolic links for workflow files to add services.
#

# Location of repository.
REPO_NAME='MacConfig'
LOCAL_REPO_DIR="$HOME/bin/$REPO_NAME"

clone_repo()
{
	echo "--- CLONING REPO $REPO_NAME ---"
	git clone https://github.com/DavidPotter/$REPO_NAME.git $LOCAL_REPO_DIR
}

# If the repository doesn't exist on the local disk, clone it.
[ -d $LOCAL_REPO_DIR ] || clone_repo

# Update the repository from the remote -- best-effort, never fatal.  A local
# install should always install whatever is in the working tree, so this step
# is allowed to skip: it fast-forwards only when that is unambiguously safe (on
# a branch that tracks an upstream, with a clean working tree, and the upstream
# is strictly ahead), and otherwise prints why it skipped and installs the
# working tree as-is.  That lets install.sh run on a "dirty" machine -- mid-
# change, on a feature branch, or offline -- without failing.
#
# (There is deliberately no "source the remote's bash_profile" step here.  An
# older version did that to load create_link, but this script defines its own
# create_link below, so the step was dead code -- and it carried a bug: the
# temp-file name was single-quoted, so mktemp never ran and a literally
# backtick-named file was written into the repo dir.)
update_repo()
{
	echo "--- UPDATE REPO $REPO_NAME FROM REMOTE ---"

	# Run in a subshell so the cd is scoped, and trail with '|| true' so a
	# non-zero exit can never trip the top-level `set -e` and abort the install.
	(
		cd "$LOCAL_REPO_DIR" || exit 0

		local branch upstream
		branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)" || {
			echo "$REPO_NAME: detached HEAD; skipping remote update (installing working tree as-is)"
			exit 0
		}

		upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)" || {
			echo "$REPO_NAME: branch '$branch' has no upstream; skipping remote update (installing working tree as-is)"
			exit 0
		}

		if ! git diff --quiet || ! git diff --cached --quiet
		then
			echo "$REPO_NAME: working tree is dirty; skipping remote update (installing working tree as-is)"
			exit 0
		fi

		if ! git fetch --quiet origin 2>/dev/null
		then
			echo "$REPO_NAME: could not fetch from remote (offline?); installing working tree as-is"
			exit 0
		fi

		# Fast-forward only.  Skip if the branch has diverged (local commits not
		# on the upstream) rather than create a surprise merge.
		if [ "$(git rev-parse HEAD)" = "$(git rev-parse "$upstream")" ]
		then
			echo "$REPO_NAME: already up to date with $upstream"
		elif git merge-base --is-ancestor HEAD "$upstream" 2>/dev/null
		then
			echo "$REPO_NAME: fast-forwarding $branch to $upstream"
			git merge --ff-only --quiet "$upstream"
		else
			echo "$REPO_NAME: '$branch' has local commits not on $upstream; skipping remote update (installing working tree as-is)"
		fi
	) || true
}

update_repo

# Helper function to create a link if the destination doesn't exist
# or display an error message detailing why it failed.
create_link()
{
	local SRC="$1"
	local DST="$2"

	if [ ! -e "$DST" ]
	then
		ln -sv "$SRC" "$DST"
	else
		printf '%s' "$REPO_NAME: $DST already" >&2
		if [ -L "$DST" ]
		then
			if [ "`readlink "$DST"`" = "$SRC" ] >&2
			then
				printf '%s' ' defined properly' >&2
			fi
			echo " (pointing to `readlink "$DST"`)" >&2
		else
			echo ' exists (not a symlink)' >&2
		fi
	fi

}

# Install a shell rc file (~/.bash_profile, ~/.zshrc, ...) as a local file that
# sources the shared loader from the repo, instead of symlinking the rc file
# straight into the repo.  Some tool installers append "export ..." lines to
# these rc files; when the file is a symlink into the repo those edits get
# written through the link into version control and leak onto every other
# machine.  Keeping the rc file in the home directory -- with the repo loader
# alongside the machine-local lines -- avoids that.
#
#  $1 - Destination rc file (e.g. "$HOME/.zshrc").
#  $2 - Loader line to ensure is present
#       (e.g. 'source "$HOME/bin/MacConfig/dotfiles/zshrc"').
install_shell_loader()
{
	local DST="$1"
	local LOADER="$2"

	# Already sources the repo loader: leave the file (and any tool-appended
	# lines) untouched.  This makes the installer idempotent.
	if [ -f "$DST" ] && [ ! -L "$DST" ] && grep -qF "$LOADER" "$DST"
	then
		echo "$REPO_NAME: $DST already sources the repo loader (leaving it intact)"
		return
	fi

	# An existing regular file (a stock rc file, or one a tool manages): inject
	# the loader line at the top, preserving everything already there below it.
	# We do not clobber content we did not write.
	if [ -f "$DST" ] && [ ! -L "$DST" ]
	then
		local TMP
		TMP="$(mktemp)"
		{
			echo "# --- MacConfig: load shared shell configuration (added by install.sh) ---"
			echo "$LOADER"
			echo "# --- end MacConfig ---"
			echo
			cat "$DST"
		} > "$TMP"
		cat "$TMP" > "$DST"
		rm -f "$TMP"
		echo "$REPO_NAME: injected repo loader at the top of $DST"
		return
	fi

	# A symlink (an older install style, possibly pointing into the repo) or a
	# broken link: replace it with a fresh local stub.
	if [ -L "$DST" ]
	then
		echo "$REPO_NAME: migrating $DST from symlink to local stub"
		rm -f "$DST"
	fi

	cat > "$DST" <<-EOF
		# $(basename "$DST") -- local loader (NOT tracked in the MacConfig repo).
		#
		# Sources the shared shell configuration from the repo, then lets
		# machine-local tool installers append their own lines below.  Keeping this
		# file in \$HOME -- not a symlink into the repo -- stops those edits from
		# leaking into version control.
		$LOADER
	EOF
	echo "$REPO_NAME: wrote local stub $DST"
}

# Ensure ~/.gitconfig pulls in the repo's tracked Git configuration (base
# settings + aliases).  Like the shell loaders above, ~/.gitconfig is a
# machine-local file -- it holds your identity, GPG signing key, commit
# template, etc. -- that we deliberately do NOT symlink into the repo; instead
# we make sure it *includes* the tracked config files, so those edits never get
# written back into version control.
#
# We inject the [include] at the TOP so personal settings below still override
# the shared base (matching the hand-written convention, and the file's own
# "base configuration" framing), and we never rewrite content we did not write
# -- only the missing include path(s) are added.  We target ~/.gitconfig by
# name rather than `git config --global` because git ALWAYS reads ~/.gitconfig
# (even when an XDG ~/.config/git/config exists, which `git config --global`
# would write to instead), so appending here is effective on every machine.
# Idempotent: once both includes are present, a re-run changes nothing.
install_gitconfig_include()
{
	local DST="$HOME/.gitconfig"
	local base='~/bin/MacConfig/config/gitconfig-base'
	local aliases='~/bin/MacConfig/config/gitconfig-aliases'

	# Which include paths are already referenced?  Match on the path value with
	# grep -F, so any indentation or spacing around '=' still counts as present.
	local have_base=0 have_aliases=0
	if [ -f "$DST" ]
	then
		if grep -qF "$base"    "$DST"; then have_base=1; fi
		if grep -qF "$aliases" "$DST"; then have_aliases=1; fi
	fi

	if [ "$have_base" -eq 1 ] && [ "$have_aliases" -eq 1 ]
	then
		echo "$REPO_NAME: $DST already includes the repo git config (leaving it intact)"
		return
	fi

	# Build an [include] block holding only the path(s) not already present, so
	# a partially-configured file never gets a duplicate entry.
	local block
	block='# --- MacConfig: include shared git configuration (added by install.sh) ---
[include]
'
	if [ "$have_base"    -eq 0 ]; then block="${block}	path = ${base}
"; fi
	if [ "$have_aliases" -eq 0 ]; then block="${block}	path = ${aliases}
"; fi
	block="${block}# --- end MacConfig ---"

	if [ -f "$DST" ]
	then
		# Inject at the top, preserving everything already there below it.
		local TMP
		TMP="$(mktemp)"
		{
			printf '%s\n\n' "$block"
			cat "$DST"
		} > "$TMP"
		cat "$TMP" > "$DST"
		rm -f "$TMP"
		echo "$REPO_NAME: injected repo git config include at the top of $DST"
	else
		# No ~/.gitconfig yet: create it with just the include block.  You still
		# add your own name/email/signing key here as usual.
		printf '%s\n' "$block" > "$DST"
		echo "$REPO_NAME: created $DST with the repo git config include"
	fi
}

# INSTALL SHELL LOADERS
# Both bash and zsh load from the same repo.  Each rc file in $HOME is a local
# file (not a symlink into the repo) that sources the matching shared loader, so
# tool installers that append lines cannot write through into version control.
# bash_profile and zshrc are therefore skipped by the dotfile symlink loop below.
echo '--- INSTALL SHELL LOADERS ---'
install_shell_loader "$HOME/.bash_profile" 'source "$HOME/bin/MacConfig/dotfiles/bash_profile"'
install_shell_loader "$HOME/.zshrc" 'source "$HOME/bin/MacConfig/dotfiles/zshrc"'

# INSTALL GIT CONFIG INCLUDE
# Make ~/.gitconfig include the repo's tracked git config (base + aliases),
# without symlinking or clobbering the machine-local identity it holds.
echo '--- INSTALL GIT CONFIG INCLUDE ---'
install_gitconfig_include

# CREATE SYMBOLIC LINKS FOR DOT FILES
# Loop through the files in the dotfiles directory and create a symlink to
# each one from a file with the same name but with a dot prefix (a dotfile) in
# the home directory.  The shell loaders (bash_profile, zshrc) are skipped: they
# are installed as local stubs above so tool installers cannot write through
# them into the repo.
echo '--- CREATE SYMBOLIC LINKS FOR DOT FILES ---'
find $LOCAL_REPO_DIR/dotfiles -maxdepth 1 -type f -not -name 'install.sh' -not -name 'README*' -not -name 'bash_profile' -not -name 'zshrc' | while read SRC
do
	DST="$HOME/`echo "$SRC" | sed -e 's#.*/#.#'`"
	create_link "$SRC" "$DST"
done

# CREATE POWERSHELL PROFILES
# Create the PowerShell config directory first if it doesn't exist.
echo '-- CREATE POWERSHELL PROFILES ---'
if [ ! -d "$HOME/.config/powershell" ]; then
    mkdir "$HOME/.config/powershell"
fi
# Create symlink for profile stored in repo.
echo ". '$LOCAL_REPO_DIR/PowerShell/profile/profile.ps1'" | tee "$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"
create_link "$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1" "$HOME/.config/powershell/Microsoft.VSCode_profile.ps1"

# INSTALL APPLICATION CONFIGURATIONS
# Tell the sourced aggregator where it lives.  A sourced POSIX script can't find
# its own path ($0 reflects this installer, and bash's $BASH_SOURCE isn't
# portable), so we pass the directory explicitly.
echo '--- INSTALL APPLICATION CONFIGURATIONS ---'
MACCONFIG_APP_CONFIGS_DIR="$LOCAL_REPO_DIR/Application-Config"
export MACCONFIG_APP_CONFIGS_DIR
. "$LOCAL_REPO_DIR/Application-Config/install-application-configs.sh"

# FINAL INSTRUCTIONS
# Report the reload command for the shell the user is actually using.  We can't
# use $0/$SHELL of this script -- install.sh always runs under /bin/sh (its
# shebang), whatever shell launched it -- so infer the caller's interactive
# shell from the parent process (the tab that ran ./install.sh), stripping a
# login shell's leading '-' and any path.  Fall back to the login shell
# ($SHELL), then to a generic hint if we still can't tell.
CALLER_SHELL="$(ps -o comm= -p "$PPID" 2>/dev/null | sed -e 's#^-##' -e 's#.*/##')"
case "$CALLER_SHELL" in
	zsh|bash) ;;                                    # trust the parent process
	*)        CALLER_SHELL="$(basename "${SHELL:-}")" ;;
esac

case "$CALLER_SHELL" in
	zsh)  RELOAD_CMD='source ~/.zshrc' ;;
	bash) RELOAD_CMD='source ~/.bash_profile' ;;
	*)    RELOAD_CMD='source ~/.bash_profile   # or ~/.zshrc, depending on your shell' ;;
esac

echo ' '
echo '#'
echo '# Invoke the following commands to complete the installation:'
echo "#   ${RELOAD_CMD}"
echo "#   source ${LOCAL_REPO_DIR}/install-tools.sh"
echo '#'
echo ' '
