# The New-PSSession command to connect to Microsoft.Exchange doesn't work with the latest
# version of OpenSSL (1.1) but it does work with v1.0.  These functions switch the version
# of OpenSSL between those two installed versions around the use of that command.
#
# Reference: https://github.com/PowerShell/PowerShell/issues/5561#issuecomment-639101511
function switch-openssl {
    # Install the right version of openssl if it is not already installed.
    if (-not (brew info openssl | Select-String 1.0.2t)) {
        Write-Output ">Installing openssl v1.0..."
        brew install https://github.com/tebelorg/Tump/releases/download/v1.0.0/openssl.rb
        if (-not (brew info openssl | Select-String 1.0.2t)) {
            throw "Could not install openssl v1.0.2t"
        }
    }
    Write-Output ">Switching openssl to v1.0.2t..."
    brew switch openssl 1.0.2t
}

function reset-openssl {
    Write-Output ">Switching openssl to v1.1.1g..."
    brew switch openssl@1.1 1.1.1g
}

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
    Write-Output ">Getting credentials for Office 365..."
    $Global:Office365UserCredential = Get-Credential -ErrorAction Stop

    if (-not $Global:Office365UserCredential) {
        Write-Host 'No valid credential entered.  Session not created' -ForegroundColor Red
        return
    }

    switch-openssl

    # Create the session with Office 365.
    Write-Output ">Creating a new session with Office 365..."
    $Global:Office365Session = New-PSSession `
        -ConfigurationName Microsoft.Exchange `
        -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
        -Credential $Global:Office365UserCredential `
        -Authentication Basic `
        -AllowRedirection `
        -ErrorAction Stop

    if (-not $Global:Office365Session) {
        Write-Host 'Session failed to be created.' -ForegroundColor Red
        reset-openssl
        return
    }

    # Import commands from the session for interacting with Office 365.
    Write-Output ">Importing commands for interacting with Office 365..."
    Import-PSSession $Global:Office365Session -DisableNameChecking -AllowClobber
    reset-openssl
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
