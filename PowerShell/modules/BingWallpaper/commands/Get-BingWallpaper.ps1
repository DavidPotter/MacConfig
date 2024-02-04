function Get-BingWallpaper {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Source = "."
    )

    [array] $culturePreference = @(
        "EN-US"
        "ROW"
        "EN-CA"
        "EN-GB"
        "EN-AU"
    )

    $fileNamePattern = "^(?<date>\d+)_(?<name>.+)_(?<culture>[A-Za-z-]+)(?<id>\d+)_(?<size>\d+x\d+)"

    # Find all image files in the source directory that match the pattern.
    $Destination, $Source | Select-Object -Unique | Get-ChildItem -File `
    | ForEach-Object {
        if ($_.Name -match $fileNamePattern) {
            return [WallpaperItem] @{
                Date       = $Matches.date
                Name       = $Matches.name
                Culture    = $Matches.culture
                Id         = [int] $Matches.id
                Dimensions = $Matches.size
                File       = $_
                Length     = $_.Length
            }
        }
        else {
            Write-Warning "Invalid name format: $($_.Name)"
        }
    } `

    # Group image files by name and length of file.
    | Group-Object Name, Length `

    # Find preferred version of each image.
    | ForEach-Object {
        if ($_.Count -eq 1) {
            return [PSCustomObject] @{
                Master     = $_.Group | Select-Object -First 1
                Duplicates = $null
            }
        }

        [ref] $selectedItem = $null
        [ref] $cultureIndex = [int]::MaxValue
        $_.Group | ForEach-Object {
            $currentIndex = $culturePreference.IndexOf($_.Culture)
            if ($currentIndex -ge 0 -and $currentIndex -lt $cultureIndex.Value) {
                $selectedItem.Value = $_
                $cultureIndex.Value = $currentIndex
            }
        }

        if ($selectedItem.Value) {
            return [PSCustomObject] @{
                Master     = $selectedItem.Value
                Duplicates = $_.Group | Where-Object { $_ -ne $selectedItem.Value }
            }
        }

        return [PSCustomObject]@{
            Master     = $_.Group | Select-Object -First 1
            Duplicates = $_.Group | Select-Object -Skip 1
        }
    }
}

Export-ModuleMember Get-BingWallpaper
