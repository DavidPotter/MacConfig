#!/bin/bash -e

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

function clone_repo()
{
	echo "--- CLONING REPO $REPO_NAME ---"
	git clone https://github.com/DavidPotter/$REPO_NAME.git $LOCAL_REPO_DIR
}

# If the repository doesn't exist on the local disk, clone it.
[ -d $LOCAL_REPO_DIR ] || clone_repo

# Pull from the remote repository.
(
	set -e
	cd $LOCAL_REPO_DIR

	echo "--- PULL FROM REPO $REPO_NAME ---"

	TEMP_FILE='`mktemp -t install.XXXXXX`'
	trap '{ rm -f "$TEMP_FILE"; }' EXIT

	set +e
	git fetch origin
	git show origin/master:dotfiles/bash_profile > "$TEMP_FILE"
	echo "Executing $TEMP_FILE"
	source "$TEMP_FILE"
	set -e

	git pull
)

# Helper function to create a link if the destination doesn't exist
# or display an error message detailing why it failed.
function create_link()
{
	local SRC="$1"
	local DST="$2"

	if [ ! -e "$DST" ]
	then
		ln -sv "$SRC" "$DST"
	else
		echo -n "$REPO_NAME: $DST already" >&2
		if [ -L "$DST" ]
		then
			if [ "`readlink "$DST"`" = "$SRC" ] >&2
			then
				echo -n ' defined properly' >&2
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
function install_shell_loader()
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

# INSTALL SHELL LOADERS
# Both bash and zsh load from the same repo.  Each rc file in $HOME is a local
# file (not a symlink into the repo) that sources the matching shared loader, so
# tool installers that append lines cannot write through into version control.
# bash_profile and zshrc are therefore skipped by the dotfile symlink loop below.
echo '--- INSTALL SHELL LOADERS ---'
install_shell_loader "$HOME/.bash_profile" 'source "$HOME/bin/MacConfig/dotfiles/bash_profile"'
install_shell_loader "$HOME/.zshrc" 'source "$HOME/bin/MacConfig/dotfiles/zshrc"'

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
echo '--- INSTALL APPLICATION CONFIGURATIONS ---'
source $LOCAL_REPO_DIR/Application-Config/install-application-configs.sh

# FINAL INSTRUCTIONS
echo ' '
echo '#'
echo '# Invoke the following commands to complete the installation:'
echo '#   source ~/.bash_profile   # or ~/.zshrc, depending on your shell'
echo "#   source ${LOCAL_REPO_DIR}/install-tools.sh"
echo '#'
echo ' '
