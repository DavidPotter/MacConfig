#!/bin/bash -e

#
# install.sh
#   Makes the Home and End keys jump to the start/end of the line in every
#   macOS Terminal.app profile.
#
#   Why this is needed: Terminal.app captures Home/End for its own scrollback
#   by default, so the keys never reach the shell.  Telling each profile to
#   "Send Text" the escape sequences \033[H (Home) and \033[F (End) hands the
#   keys to the shell instead.  The shell then acts on them because its
#   line-editor bindings map those sequences to beginning-of-line /
#   end-of-line (for bash, dotfiles/inputrc).  BOTH layers are required: the
#   Send Text mapping alone gets the bytes to the shell, and the shell binding
#   alone is useless while Terminal keeps eating the keys.
#
#   How it writes the setting: Terminal stores per-profile key mappings under
#   "Window Settings" -> <profile> -> keyMapBoundKeys in
#   com.apple.Terminal.plist, keyed by function-key code (F729 = Home,
#   F72B = End).  This map is an OVERLAY on Terminal's built-in defaults, so we
#   MERGE just those two keys into each profile and leave every other mapping
#   (arrows, F-keys, and any the user added) untouched -- we never replace a
#   profile's whole keymap.
#
#   Why plutil (not PlistBuddy): plutil takes each key path as a real argument
#   and treats '.' as the only separator, so profile names containing spaces,
#   apostrophes ("Dave's Theme"), or colons ("SSH: Prod") are handled safely
#   once their dots are escaped.  PlistBuddy re-parses its -c argument as a
#   mini-language, so an apostrophe in a name breaks its quoting (and would,
#   under the parent installer's `set -e`, abort every sibling app installer)
#   and a colon silently mis-targets the path.  The one name plutil still can't
#   express reliably is one containing a backslash (its key-path escape char),
#   so such a profile is skipped with a warning rather than mis-mapped -- no
#   real Terminal profile name contains a backslash.
#
#   The write goes through `defaults` (cfprefsd), not a raw edit of the plist
#   file, so it is safe to run while Terminal is open; changes apply to new
#   tabs/windows (fully reliable after Terminal is restarted).
#
#   NOTE: this file is sourced (not executed) by
#   Application-Config/install-application-configs.sh, from inside a `while
#   read` pipeline -- i.e. a subshell.  It therefore does all of its work in a
#   function that uses `return` (never `exit`): an `exit` here would terminate
#   that subshell and skip the sibling application installers.  Each per-profile
#   write is also called with a trailing `|| :` so that even a profile whose
#   stored keymap is malformed can't make a failing write abort the run under
#   the parent's `set -e` (the post-write check decides success instead).
#

# Build a plutil key path into a profile's keyMapBoundKeys.  plutil treats '.'
# as the path separator, so any '.' inside the profile name must be escaped as
# '\.' -- otherwise "v1.2 build" would be read as nested keys v1 -> 2 build.
#  $1 - profile name
#  $2 - trailing sub-path (e.g. "keyMapBoundKeys" or "keyMapBoundKeys.F729")
__terminal_keypath()
{
    local profile="$1" leaf="$2"
    printf 'Window Settings.%s.%s' "${profile//./\\.}" "$leaf"
}

# Set one keyMapBoundKeys entry on one profile in the given working plist,
# merging into whatever keymap the profile already has (creating the dict if
# absent).  Idempotent: -replace updates an existing leaf, -insert creates a
# missing one.  Returns nonzero only if the value could not be written.
#  $1 - working plist path
#  $2 - profile name
#  $3 - function-key code (F729 / F72B)
#  $4 - string value to send
__terminal_set_keymap_entry()
{
    local work_plist="$1" profile="$2" keycode="$3" value="$4"
    local dict_path leaf_path
    dict_path="$(__terminal_keypath "$profile" 'keyMapBoundKeys')"
    leaf_path="$(__terminal_keypath "$profile" "keyMapBoundKeys.${keycode}")"

    # Ensure the keyMapBoundKeys dict exists (create it only if absent, so an
    # existing keymap is never wiped).
    plutil -extract "$dict_path" raw -o - "$work_plist" >/dev/null 2>&1 \
        || plutil -insert "$dict_path" -dictionary "$work_plist" >/dev/null 2>&1

    # Replace the key if present, otherwise insert it.
    plutil -replace "$leaf_path" -string "$value" "$work_plist" >/dev/null 2>&1 \
        || plutil -insert  "$leaf_path" -string "$value" "$work_plist" >/dev/null 2>&1
}

__terminal_install_home_end_keys()
{
    local domain='com.apple.Terminal'
    local prefs="$HOME/Library/Preferences/${domain}.plist"
    local backup="${prefs}.macconfig-bak"

    # Function-key codes Terminal uses for these keys, and the bytes to send.
    # \033 is ESC; \033[H / \033[F are exactly what the GUI "Send Text" writes.
    local home_keycode='F729' end_keycode='F72B'
    local home_send end_send
    home_send="$(printf '\033')[H"
    end_send="$(printf '\033')[F"

    # Bail out cleanly where Terminal.app prefs don't exist (non-macOS, or a
    # machine that has never run Terminal) so a shared installer doesn't error.
    if ! defaults read "$domain" "Window Settings" >/dev/null 2>&1
    then
        echo "Terminal: com.apple.Terminal has no Window Settings; skipping Home/End key mapping"
        return 0
    fi

    echo '--- MAP HOME/END KEYS IN TERMINAL PROFILES ---'

    # Work on an exported copy, then import it back.  Editing the export (not
    # the live file) avoids racing cfprefsd; importing routes the change
    # through cfprefsd so a running Terminal picks it up.
    # Use the exact path mktemp creates -- don't append an extension.  On BSD
    # mktemp (macOS), `-t <arg>` treats <arg> as a prefix and appends its own
    # random suffix, so `$(mktemp -t x).plist` would name a *different* file
    # than the one mktemp created, leaking the original on every run.  `defaults`
    # and `plutil` detect the plist format from content, so no ".plist" suffix
    # is needed.
    local work_plist
    work_plist="$(mktemp -t "${domain}")"

    if ! defaults export "$domain" "$work_plist"
    then
        echo "Terminal: could not export $domain prefs; skipping" >&2
        rm -f "$work_plist"
        return 0
    fi

    # One-time backup of the real prefs before we ever modify them.
    if [ ! -f "$backup" ] && [ -f "$prefs" ]
    then
        cp -p "$prefs" "$backup"
        echo "Terminal: backed up existing prefs to $backup"
    fi

    # Enumerate profiles from the exported copy.  `plutil -extract ... raw`
    # prints one profile name per line, preserving spaces, without handing the
    # ESC bytes in the file to an XML parser.
    local profile count=0
    while IFS= read -r profile
    do
        [ -n "$profile" ] || continue

        # plutil uses '\' as a key-path escape character, and its grammar for
        # a backslash inside a key is inconsistent across macOS versions, so a
        # name containing one can't be expressed as a reliable key path -- it
        # would land in a junk sibling key instead of the real profile.  Skip
        # such a profile (warn, don't abort) rather than mis-map it silently;
        # no real Terminal profile name contains a backslash.
        case "$profile" in
            *\\*)
                echo "Terminal: profile '$profile' contains a backslash; skipping (cannot map safely)" >&2
                continue
                ;;
        esac

        # The trailing '|| :' is essential, not decorative.  These calls are
        # bare (their exit status isn't otherwise consumed), and under the
        # parent installer's sourced `set -e` a function whose work fails would
        # abort the whole run and skip sibling app installers.  '|| :' suspends
        # `set -e` for the entire function body, so a profile with a malformed
        # keyMapBoundKeys (e.g. a scalar instead of a dict, from corrupted or
        # hand-edited prefs) can't take the run down -- the post-write check
        # below is what actually decides success, and simply reports a skip.
        __terminal_set_keymap_entry "$work_plist" "$profile" "$home_keycode" "$home_send" || :
        __terminal_set_keymap_entry "$work_plist" "$profile" "$end_keycode"  "$end_send"  || :

        # Confirm the write actually landed (guards against a pathological name
        # we didn't anticipate, or a profile we skipped writing) before claiming
        # success for this profile.
        if plutil -extract "$(__terminal_keypath "$profile" "keyMapBoundKeys.${home_keycode}")" \
                raw -o - "$work_plist" >/dev/null 2>&1
        then
            echo "Terminal: mapped Home/End in profile '$profile'"
            count=$((count + 1))
        else
            echo "Terminal: could not map Home/End in profile '$profile'; skipped" >&2
        fi
    done <<EOF
$(plutil -extract "Window Settings" raw -o - "$work_plist" 2>/dev/null)
EOF

    if [ "$count" -eq 0 ]
    then
        echo "Terminal: no profiles updated; nothing to import"
        rm -f "$work_plist"
        return 0
    fi

    # Push the edited copy back through cfprefsd.
    if defaults import "$domain" "$work_plist"
    then
        echo "Terminal: mapped Home/End in $count profile(s)."
        echo "Terminal: restart Terminal (or open a new window) for the change to take full effect."
    else
        echo "Terminal: failed to import updated prefs (original left unchanged)" >&2
    fi

    rm -f "$work_plist"
    return 0
}

__terminal_install_home_end_keys
unset -f __terminal_install_home_end_keys __terminal_set_keymap_entry __terminal_keypath
