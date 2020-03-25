# NOTE:
#   The New-PSSession command in the Start-Office365Session function requires a specific
#   version of OpenSSL.  Look at this issue for details:
#       https://github.com/PowerShell/PowerShell/issues/5561#issuecomment-592476131
#
# Start a session to Office 365 and import commands to use against that session.
# Execute `Stop-Office365Session` when done to free up resources on the server.
function Start-Office365Session {
    if ($Global:Office365Session) {
        throw 'Session already exists.  Use Stop-Session before starting another session.'
    }

    # Get the user's credentials.  This will prompt for a username and a password.
    $Global:Office365UserCredential = Get-Credential -ErrorAction Stop

    if (-not $Global:Office365UserCredential) {
        Write-Host 'No valid credential entered.  Session not created' -ForegroundColor Red
        return
    }

    # Create the session with Office 365.
    $Global:Office365Session = New-PSSession `
        -ConfigurationName Microsoft.Exchange `
        -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
        -Credential $Global:Office365UserCredential `
        -Authentication Basic `
        -AllowRedirection `
        -ErrorAction Stop

    if (-not $Global:Office365Session) {
        Write-Host 'Session failed to be created.' -ForegroundColor Red
        return
    }

    # Import commands from the session for interacting with Office 365.
    Import-PSSession $Global:Office365Session -DisableNameChecking -AllowClobber
}

function Stop-Office365Session {
    Remove-Variable Office365UserCredential -Scope Global -ErrorAction SilentlyContinue

    if (-not $Global:Office365Session) {
        Write-Host 'No session exists.' -ForegroundColor Red
        return
    }

    Remove-PSSession $Global:Office365Session -Verbose -ErrorAction Stop

    Remove-Variable Office365Session -Scope Global
}
