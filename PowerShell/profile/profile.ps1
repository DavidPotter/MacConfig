# Define aliases

Set-Alias -Name d -Value Get-ChildItem

# Define functions

function da {
    $input | Get-ChildItem -Force @args
}

# Import externally-defined functions and commands.

. $PSScriptRoot/ExchangeSession.ps1

# Set up key handling.

Set-PSReadLineKeyHandler -Key Tab -Function TabCompleteNext
Set-PSReadLineKeyHandler -Key Shift+Tab -Function TabCompletePrevious
