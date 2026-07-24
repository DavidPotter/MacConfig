#!/bin/sh -e

#
# install.sh
#   Makes the Home and End keys jump to the start/end of the line in every
#   macOS Terminal.app profile, and seeds each profile with Terminal's built-in
#   default key map so the profile's Keyboard settings show the complete list
#   of mappings rather than only the two keys we add.
#
#   Why Home/End need mapping: Terminal.app captures Home/End for its own
#   scrollback by default, so the keys never reach the shell.  Telling each
#   profile to "Send Text" the escape sequences \033[H (Home) and \033[F (End)
#   hands the keys to the shell instead.  The shell then acts on them because
#   its line-editor bindings map those sequences to beginning-of-line /
#   end-of-line (for bash, dotfiles/inputrc).  BOTH layers are required: the
#   Send Text mapping alone gets the bytes to the shell, and the shell binding
#   alone is useless while Terminal keeps eating the keys.
#
#   How Terminal stores this: per-profile key mappings live under "Window
#   Settings" -> <profile> -> keyMapBoundKeys in com.apple.Terminal.plist, keyed
#   by function-key code (F729 = Home, F72B = End).  That dict is an OVERLAY on
#   Terminal's built-in default key map (Terminal.app/Contents/Resources/
#   keyMappings.plist, 58 entries): a code absent from a profile's keyMapBoundKeys
#   still works because Terminal falls through to the built-in default.  So the
#   two keys alone are enough to FUNCTION.
#
#   Why we also seed the full default map: the Keyboard settings pane displays
#   only what a profile actually stores, NOT the effective overlay.  A profile
#   that stored just F729/F72B therefore showed only Home and End in the UI --
#   every arrow and function key still worked, but the list looked empty.  To
#   make the UI show "all the keys it normally would," we copy Terminal's own
#   built-in defaults into each profile, then add Home/End on top.  Every profile
#   ends up with the same 58 defaults + Home + End.  (Terminal's stock "Pro"
#   profile happens to ship with 56 of the 58 defaults already stored -- it is
#   missing #F704-#F707, Cmd-F1..F4 -- so seeding also completes Pro.)
#
#   How the seed avoids clobbering: we use `plutil -insert`, which creates a key
#   only if it is ABSENT and refuses (harmlessly) to overwrite one that already
#   exists.  So a profile that has genuinely customized, say, the left-arrow
#   mapping keeps its value; we only fill in the gaps.  Home/End are then forced
#   with a replace-or-insert so they always land on our sequences.
#
#   Caveat (intentional): materializing the defaults FREEZES them.  If a future
#   macOS shipped a different built-in sequence for some key, a seeded profile
#   would keep the value we wrote instead of falling through to the new default.
#   These are decades-stable VT100/xterm sequences, so this is a theoretical
#   corner; it is the direct, accepted consequence of storing the full map so
#   the UI can display it.
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
#   real Terminal profile name contains a backslash.  The default-map key codes
#   themselves (e.g. "#F704", "$F702", "^F702", "~^F728") contain no '.' or '\',
#   so they are safe literal path segments.
#
#   The write goes through `defaults` (cfprefsd), not a raw edit of the plist
#   file, so it is safe to run while Terminal is open.  BUT a running Terminal
#   caches every profile's keymap in memory at launch and neither re-reads it
#   for new tabs/windows nor adopts this change until it is fully quit and
#   relaunched.  Worse, Terminal rewrites its entire prefs from that in-memory
#   copy when it quits, so an ordinary quit can clobber the values just written.
#   The only reliable way to make the change live on a machine whose Terminal is
#   already running is a clobber-safe restart: quit Terminal, re-apply this
#   script while it is down, then relaunch.  Application-Config/Terminal/
#   safe-restart.sh automates exactly that; after writing, this script detects a
#   running Terminal and points the user to it.
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
    local profile="$1" leaf="$2" escaped
    # Escape every '.' in the profile name as '\.' for plutil's key-path
    # grammar.  POSIX sh has no ${var//./\.} pattern substitution, so do it with
    # sed: the replacement '\\.' emits a literal backslash followed by a dot.
    escaped="$(printf '%s' "$profile" | sed 's/\./\\./g')"
    printf 'Window Settings.%s.%s' "$escaped" "$leaf"
}

# Set one keyMapBoundKeys entry on one profile in the given working plist,
# merging into whatever keymap the profile already has (creating the dict if
# absent).  Idempotent and FORCING: -replace updates an existing leaf, -insert
# creates a missing one, so the value always ends up as $4.  Used for Home/End,
# which must land on our sequences regardless of any prior value.
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

# Locate Terminal.app's built-in default key map.  It has lived under
# /System/Applications/Utilities on modern macOS and under /Applications/
# Utilities on older releases.  Prints the path and returns 0 if found.
__terminal_default_keymap_file()
{
    local p
    for p in \
        '/System/Applications/Utilities/Terminal.app/Contents/Resources/keyMappings.plist' \
        '/Applications/Utilities/Terminal.app/Contents/Resources/keyMappings.plist'
    do
        if [ -f "$p" ]
        then
            printf '%s' "$p"
            return 0
        fi
    done
    return 1
}

# Seed one profile's keyMapBoundKeys with the built-in default map, inserting
# only keys that are ABSENT (plutil -insert refuses to overwrite, so a profile's
# own customization is preserved).  Reads the default map from the caller via
# dynamic scoping: $__def_map holds one "key<TAB>value" record per line (POSIX
# sh has no arrays).  The key codes and ESC values are verified free of tabs and
# newlines, so this delimiting round-trips them exactly.
#  $1 - working plist path
#  $2 - profile name
__terminal_seed_default_keymap()
{
    local work_plist="$1" profile="$2"
    local dict_path def_key def_val tab
    tab="$(printf '\t')"
    dict_path="$(__terminal_keypath "$profile" 'keyMapBoundKeys')"

    # The keyMapBoundKeys dict must exist before we can insert leaves into it.
    plutil -extract "$dict_path" raw -o - "$work_plist" >/dev/null 2>&1 \
        || plutil -insert "$dict_path" -dictionary "$work_plist" >/dev/null 2>&1

    # Split each record on its single TAB (IFS=TAB): field 1 is the key code,
    # the remainder is the value.  A leading space in a value is preserved
    # because space is not in IFS.
    printf '%s\n' "$__def_map" | while IFS="$tab" read -r def_key def_val
    do
        [ -n "$def_key" ] || continue
        # Insert-if-absent: fills a gap, harmlessly refuses an existing key.
        plutil -insert "$(__terminal_keypath "$profile" "keyMapBoundKeys.${def_key}")" \
            -string "$def_val" "$work_plist" >/dev/null 2>&1 || :
    done
}

__terminal_install_home_end_keys()
{
    local domain='com.apple.Terminal'
    local prefs="$HOME/Library/Preferences/${domain}.plist"
    local backup="${prefs}.macconfig-bak"

    # Resolve this script's directory so we can point at the sibling
    # safe-restart.sh.  When sourced by install-application-configs.sh the
    # aggregator exports MACCONFIG_APP_INSTALL_DIR (a sourced POSIX script can't
    # find its own path -- $0 is the executor and bash's $BASH_SOURCE isn't
    # portable).  Fall back to $0 for the standalone/executed case (e.g. the
    # safe-restart worker runs this file directly).
    local script_dir
    script_dir="${MACCONFIG_APP_INSTALL_DIR:-$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)}"

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

    # Load Terminal's built-in default key map into a TAB-delimited record
    # string ("keycode<TAB>value" per line) so we can stamp it into every
    # profile.  POSIX sh has no arrays; the key codes and ESC values are
    # verified tab/newline-free, so this delimiting round-trips them exactly.
    # Enumerate keys jq-free (jq isn't on a stock Mac) via the XML <key> tags --
    # keyMappings.plist is a flat dict, so every <key> is a real entry; values
    # are read back with `plutil -extract ... raw`, preserving the literal ESC
    # bytes.  If the file is missing we simply skip seeding and still map
    # Home/End (the functional requirement).
    local __def_map default_map def_key def_val def_count tab
    tab="$(printf '\t')"
    __def_map=''
    def_count=0
    if default_map="$(__terminal_default_keymap_file)"
    then
        while IFS= read -r def_key
        do
            [ -n "$def_key" ] || continue
            def_val="$(plutil -extract "$def_key" raw -o - "$default_map" 2>/dev/null)" || continue
            __def_map="${__def_map}${def_key}${tab}${def_val}
"
            def_count=$((def_count + 1))
        done <<EOF
$(plutil -convert xml1 -o - "$default_map" 2>/dev/null | grep -oE '<key>[^<]*</key>' | sed -E 's#</?key>##g')
EOF
        echo "Terminal: loaded ${def_count} built-in default key mappings from $default_map"
    else
        echo "Terminal: built-in default keymap not found; mapping Home/End only" >&2
    fi

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
        #
        # Seed the full default map first (insert-if-absent), then FORCE
        # Home/End on top so they always land on our sequences.
        __terminal_seed_default_keymap "$work_plist" "$profile" || :
        __terminal_set_keymap_entry "$work_plist" "$profile" "$home_keycode" "$home_send" || :
        __terminal_set_keymap_entry "$work_plist" "$profile" "$end_keycode"  "$end_send"  || :

        # Confirm the write actually landed (guards against a pathological name
        # we didn't anticipate, or a profile we skipped writing) before claiming
        # success for this profile.
        if plutil -extract "$(__terminal_keypath "$profile" "keyMapBoundKeys.${home_keycode}")" \
                raw -o - "$work_plist" >/dev/null 2>&1
        then
            echo "Terminal: mapped Home/End (+default keymap) in profile '$profile'"
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
        # A running Terminal won't adopt this until it is fully quit and
        # relaunched, and its quit can clobber what we just wrote (see the
        # header comment).  Detect that case and point at the safe restart;
        # match the real app binary, not `pgrep -x Terminal` (which misses it).
        if ps -axo command= 2>/dev/null | grep -q '[/]Terminal.app/Contents/MacOS/Terminal'
        then
            echo "Terminal: Terminal is running -- the change is on disk but NOT yet live."
            echo "Terminal: run '${script_dir}/safe-restart.sh' to quit, re-apply, and relaunch it safely."
        else
            echo "Terminal: launch Terminal to pick up the change (it reads keymaps at startup)."
        fi
    else
        echo "Terminal: failed to import updated prefs (original left unchanged)" >&2
    fi

    rm -f "$work_plist"
    return 0
}

__terminal_install_home_end_keys
unset -f __terminal_install_home_end_keys __terminal_set_keymap_entry \
         __terminal_keypath __terminal_seed_default_keymap \
         __terminal_default_keymap_file
