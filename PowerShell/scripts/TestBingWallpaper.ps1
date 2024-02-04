Set-Location /Users/david/Pictures/BingDailyWallpaper

Import-Module $PSScriptRoot/../modules/BingWallpaper/BingWallpaper.psd1 -Force

Get-BingWallpaper | Format-List
