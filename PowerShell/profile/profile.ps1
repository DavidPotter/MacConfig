# Define aliases

Set-Alias -Name d -Value Get-ChildItem

# Define functions

# Display all child items, including hidden and non-hidden.
function da {
    $input | Get-ChildItem -Force @args
}

# Import externally-defined functions and commands.

. $PSScriptRoot/ExchangeSession.ps1

# Set up key handling.

Set-PSReadLineKeyHandler -Key Tab -Function TabCompleteNext
Set-PSReadLineKeyHandler -Key Shift+Tab -Function TabCompletePrevious

# Add the modules directory to the path.

$modulesPath = Resolve-Path $PSScriptRoot/../modules
switch ($PSVersionTable.Platform) {
    Windows { $pathSeparator = ";" }
    Default { $pathSeparator = ":" }
}

if ($modulesPath -and $env:PSModulePath -notmatch "$pathSeparator$([regex]::Escape($modulesPath.Path))($pathSeparator|$)") {
    $env:PSModulePath += "$pathSeparator$($modulesPath.Path)"
}

Import-Module BingWallpaper
