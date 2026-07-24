#!/bin/sh
#
# safe-restart.sh
#   Clobber-safe restart of macOS Terminal.app so that the Home/End key
#   mappings written by install.sh actually become live.
#
#   Why this is needed: Terminal caches every profile's keymap in memory when
#   it launches and never re-reads it (not even for new tabs).  It also
#   rewrites its whole preferences from that in-memory copy when it quits.  So
#   on a machine whose Terminal has been running since before install.sh ran,
#   the mapping is correct on disk / in cfprefsd but not live, and an ordinary
#   Cmd-Q would clobber the good on-disk values with Terminal's stale in-memory
#   copy.  The only reliable fix is: quit Terminal, re-apply install.sh while it
#   is DOWN, then relaunch -- the fresh launch reads the corrected values and
#   they become permanent (this is exactly why a profile that was mapped before
#   the running Terminal launched, e.g. an old manual "Pro" mapping, survives
#   every quit).
#
#   The catch: this has to quit the very Terminal that is running the script,
#   which would kill the script.  So the real work runs in a detached launchd
#   LaunchAgent that OUTLIVES Terminal (a gui-domain agent is tied to the login
#   session, not to Terminal).  That worker waits for Terminal to exit, proves
#   whether a clobber happened, re-applies install.sh, relaunches Terminal, and
#   then removes itself from launchd.
#
#   Re-runnable any time: each run stages a fresh one-shot agent and cleans up
#   after itself.  Safe when Terminal is NOT running too -- it just re-applies
#   the mapping and launches Terminal.
#
# Usage:
#   Application-Config/Terminal/safe-restart.sh            # arm, then quit Terminal
#   Application-Config/Terminal/safe-restart.sh --worker   # internal (launchd only)
#

set -u

LABEL='com.macconfig.terminal-restart'
UID_NUM="$(id -u)"
DOMAIN='com.apple.Terminal'
AGENT_PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
LOG="$HOME/.macconfig-terminal-restart.log"
PREQUIT="$HOME/.macconfig-terminal-restart.prequit.plist"
POSTQUIT="$HOME/.macconfig-terminal-restart.postquit.plist"

# Absolute path to this very script (launchd needs an absolute program path)
# and to its sibling install.sh.  This script is executed, not sourced (the user
# runs it, and the LaunchAgent re-runs it), so $0 is its own path -- there is no
# POSIX equivalent of bash's $BASH_SOURCE.
SELF="$(cd "$(dirname "$0")" && pwd -P)/$(basename "$0")"
INSTALL_SH="$(dirname "$SELF")/install.sh"

# True while a real Terminal.app process is alive.  Match the app binary path,
# NOT `pgrep -x Terminal` -- the latter does not match Terminal.app reliably.
terminal_running()
{
    ps -axo command= 2>/dev/null | grep -q '[/]Terminal.app/Contents/MacOS/Terminal'
}

wlog()
{
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"
}

# ----------------------------------------------------------------------------
# Worker mode: runs detached under launchd, so it survives Terminal quitting.
# ----------------------------------------------------------------------------
if [ "${1:-}" = '--worker' ]
then
    # Delete our own LaunchAgent file immediately, so even an interrupted run
    # can never re-fire at the next login.  (Removing the file does not unload
    # the already-running job; we bootout at the very end.)
    rm -f "$AGENT_PLIST"

    # launchd hands us a minimal environment; use a known-good PATH.
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin

    wlog "worker: started (pid $$); waiting for Terminal to quit"

    waited=0
    while terminal_running
    do
        sleep 1
        waited=$((waited + 1))
        if [ "$waited" -ge 900 ]
        then
            wlog "worker: timed out after ${waited}s waiting for Terminal to quit; aborting with NO changes"
            launchctl bootout "gui/${UID_NUM}/${LABEL}" 2>/dev/null || :
            exit 0
        fi
    done

    wlog "worker: Terminal is down after ${waited}s; letting cfprefsd settle"
    sleep 2

    # Prove whether Terminal's quit clobbered the mapping.  Compare a non-Pro
    # profile's Home key (F729) before the quit vs. after.  Diagnostic only --
    # we re-apply regardless, so correctness never depends on this.
    defaults export "$DOMAIN" "$POSTQUIT" 2>/dev/null || :
    check_profile="$(plutil -extract 'Window Settings' raw -o - "$PREQUIT" 2>/dev/null \
                     | grep -v '^Pro$' | head -1)"
    if [ -n "$check_profile" ]
    then
        # Escape '.' as '\.' for plutil's key-path grammar (POSIX sh has no
        # ${var//./\.} pattern substitution -- do it with sed).
        check_escaped="$(printf '%s' "$check_profile" | sed 's/\./\\./g')"
        pre_val="$(plutil -extract "Window Settings.${check_escaped}.keyMapBoundKeys.F729" raw -o - "$PREQUIT"  2>/dev/null)"
        post_val="$(plutil -extract "Window Settings.${check_escaped}.keyMapBoundKeys.F729" raw -o - "$POSTQUIT" 2>/dev/null)"
        wlog "worker: clobber check on profile '${check_profile}' F729 -> pre='${pre_val:-<none>}' post='${post_val:-<none>}'"
        if [ -n "$pre_val" ] && [ -z "$post_val" ]
        then
            wlog "worker: CLOBBER CONFIRMED -- Terminal's quit wiped the mapping on disk; re-applying now"
        elif [ -n "$post_val" ]
        then
            wlog "worker: no clobber -- mapping survived the quit; re-applying anyway (idempotent)"
        fi
    else
        wlog "worker: clobber check inconclusive (no non-Pro profile in snapshot)"
    fi

    # Re-apply the mapping while Terminal is DOWN, so nothing can clobber it.
    if [ -f "$INSTALL_SH" ]
    then
        wlog "worker: running $INSTALL_SH"
        sh "$INSTALL_SH" >> "$LOG" 2>&1 || wlog "worker: install.sh returned nonzero (see above)"
    else
        wlog "worker: ERROR install.sh not found at $INSTALL_SH"
    fi

    # Relaunch Terminal; the fresh launch reads the corrected keymaps and they
    # become permanent.  `open` hands off to LaunchServices (which parents
    # Terminal to launchd, not to this worker) and returns at once.
    wlog "worker: relaunching Terminal"
    open -a Terminal 2>>"$LOG" || wlog "worker: 'open -a Terminal' failed"

    # Confirm Terminal is actually back up before we exit.  This is not needed
    # to keep Terminal alive (it's a child of launchd, not of us), but it makes
    # this log the authoritative record of whether the relaunch succeeded --
    # the user's interactive session is gone by now, so the log is all they
    # have.  Wait up to 30s.
    up=0
    while [ "$up" -lt 30 ]
    do
        if terminal_running
        then
            wlog "worker: Terminal is back up after ${up}s"
            break
        fi
        sleep 1
        up=$((up + 1))
    done
    if ! terminal_running
    then
        wlog "worker: WARNING Terminal did not come up within ${up}s; the mapping IS correct on disk -- relaunch Terminal from the Dock/Finder to pick it up"
    fi

    wlog "worker: done"
    # Boot ourselves out LAST, only after confirming the relaunch above.
    launchctl bootout "gui/${UID_NUM}/${LABEL}" 2>/dev/null || :
    exit 0
fi

# ----------------------------------------------------------------------------
# Launcher mode: invoked by the user from inside Terminal.  Arms the worker.
# ----------------------------------------------------------------------------
: > "$LOG"
wlog "launcher: arming clobber-safe Terminal restart"
echo "safe-restart: arming clobber-safe Terminal restart (log: $LOG)"

if [ ! -f "$INSTALL_SH" ]
then
    echo "safe-restart: ERROR cannot find install.sh at $INSTALL_SH" >&2
    exit 1
fi

# Snapshot the current (correct) prefs so the worker can prove a clobber later.
if defaults export "$DOMAIN" "$PREQUIT" 2>/dev/null
then
    wlog "launcher: snapshotted current prefs to $PREQUIT"
else
    wlog "launcher: WARNING could not snapshot prefs; clobber check will be skipped"
fi

# Clear any stale agent from a previous run (ignore if absent).
launchctl bootout "gui/${UID_NUM}/${LABEL}" 2>/dev/null || :
rm -f "$AGENT_PLIST"

# Write the one-shot LaunchAgent: runs this script in --worker mode immediately
# (RunAtLoad) and once (no KeepAlive).  stdout/stderr also go to the log.
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$AGENT_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>${SELF}</string>
        <string>--worker</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${LOG}</string>
    <key>StandardErrorPath</key>
    <string>${LOG}</string>
</dict>
</plist>
PLIST

if ! plutil -lint "$AGENT_PLIST" >/dev/null 2>&1
then
    echo "safe-restart: ERROR generated LaunchAgent is invalid" >&2
    wlog "launcher: ERROR generated LaunchAgent failed plutil -lint"
    exit 1
fi

if launchctl bootstrap "gui/${UID_NUM}" "$AGENT_PLIST" 2>>"$LOG"
then
    wlog "launcher: worker staged; now waiting for Terminal to quit"
else
    echo "safe-restart: ERROR could not start the background worker" >&2
    wlog "launcher: ERROR launchctl bootstrap failed"
    exit 1
fi

cat <<EOF

  ============================================================
   Clobber-safe Terminal restart is ARMED.

   Now QUIT Terminal completely (Cmd-Q).  While Terminal is
   down, a background helper re-applies the Home/End mapping
   and relaunches Terminal automatically.

   NOTE: this closes ALL Terminal windows and ends this shell
   session.  Progress is logged to:
     $LOG
  ============================================================

EOF
