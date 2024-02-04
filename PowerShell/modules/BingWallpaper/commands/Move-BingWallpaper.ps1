function Move-BingWallpaper {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter()]
        [string]
        $Source = ".",

        [Parameter(
            Mandatory
        )]
        [string]
        $Destination = "."
    )

    $trash = "~/.Trash"

    Get-BingWallpaper -Source $Source | ForEach-Object {
        $_.Master.File | Move-Item -Destination $destination

        if ($_.Duplicates) {
            $_.Duplicates | ForEach-Object {
                $_.File | Move-Item -Destination $trash
            }
        }
    }
}

Export-ModuleMember Move-BingWallpaper
