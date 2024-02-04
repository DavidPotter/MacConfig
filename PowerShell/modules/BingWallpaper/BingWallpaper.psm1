class WallpaperItem {
    [string] $Date
    [string] $Name
    [string] $Culture
    [string] $Id
    [string] $Dimensions
    $File
    [int] $Length
}

# Import the commands.
Get-ChildItem $PSScriptRoot\commands\*.ps1 -File | ForEach-Object {
    . $_.FullName
}
