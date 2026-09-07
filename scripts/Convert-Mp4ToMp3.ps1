<#
.SYNOPSIS
    Extracts the audio track from an MP4 file into an MP3 file.

.PARAMETER Path
    Path to the MP4 file to convert. The MP3 is written next to it with the
    same base name.

.EXAMPLE
    .\Convert-Mp4ToMp3.ps1 -Path .\lecture.mp4
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path
)

$ErrorActionPreference = 'Stop'

$ffmpeg = 'C:\tools\ffmpeg\ffmpeg.exe'
if (-not (Test-Path -LiteralPath $ffmpeg)) {
    throw "ffmpeg not found at $ffmpeg"
}

$inputFile = Get-Item -LiteralPath $Path
$output = Join-Path $inputFile.DirectoryName ($inputFile.BaseName + '.mp3')

& $ffmpeg -i $inputFile.FullName -vn -c:a libmp3lame -q:a 2 $output
if ($LASTEXITCODE -ne 0) {
    throw "ffmpeg failed with exit code $LASTEXITCODE"
}

Write-Host "Done: $output" -ForegroundColor Green
