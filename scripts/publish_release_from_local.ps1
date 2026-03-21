param(
    [Parameter(Mandatory = $true)]
    [string]$Tag,
    [string]$Repo = "idshklein/haiz-0-94-kart",
    [string]$Remote = "origin",
    [string]$Branch = "main",
    [string]$Gpkg = "kart_repo.gpkg",
    [string]$Qgs = "proj.qgs",
    [switch]$SkipBranchPush
)

$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found in PATH: $Name"
    }
}

Require-Command "kart"
Require-Command "gh"

if (-not (Test-Path $Gpkg)) {
    throw "Missing file: $Gpkg"
}
if (-not (Test-Path $Qgs)) {
    throw "Missing file: $Qgs"
}

$repoRoot = (Get-Location).Path
$gpkgPath = (Resolve-Path $Gpkg).Path
$qgsPath = (Resolve-Path $Qgs).Path

$localTags = (& kart tag) -split "`r?`n" | Where-Object { $_ -ne "" }
if (-not ($localTags -contains $Tag)) {
    throw "Local tag '$Tag' does not exist. Create it first with: kart tag $Tag"
}

Write-Host "Publishing release from local machine for tag $Tag"

if (-not $SkipBranchPush) {
    Write-Host "Pushing branch $Branch to $Remote"
    & kart push $Remote $Branch
}

Write-Host "Pushing tag $Tag to $Remote"
& kart push $Remote $Tag

$tempDir = Join-Path $env:TEMP ("kart_release_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempDir | Out-Null

$bundlePath = Join-Path $tempDir "haiz_release_bundle.zip"
$checksumsPath = Join-Path $tempDir "SHA256SUMS.txt"

Compress-Archive -Path $gpkgPath, $qgsPath -DestinationPath $bundlePath -Force

$gpkgName = [System.IO.Path]::GetFileName($gpkgPath)
$qgsName = [System.IO.Path]::GetFileName($qgsPath)
$gpkgHash = (Get-FileHash $gpkgPath -Algorithm SHA256).Hash.ToLower()
$qgsHash = (Get-FileHash $qgsPath -Algorithm SHA256).Hash.ToLower()

@(
    "$gpkgHash  $gpkgName"
    "$qgsHash  $qgsName"
) | Set-Content -Path $checksumsPath -Encoding UTF8

$releaseExists = $true
try {
    & gh release view $Tag --repo $Repo --json tagName | Out-Null
}
catch {
    $releaseExists = $false
}

if ($releaseExists) {
    Write-Host "Release $Tag exists. Uploading/overwriting assets."
    & gh release upload $Tag $bundlePath --repo $Repo --clobber
    & gh release upload $Tag $checksumsPath --repo $Repo --clobber
    & gh release upload $Tag $gpkgPath --repo $Repo --clobber
    & gh release upload $Tag $qgsPath --repo $Repo --clobber
}
else {
    Write-Host "Creating new release $Tag with local assets."
    & gh release create $Tag $bundlePath $checksumsPath $gpkgPath $qgsPath --repo $Repo --title $Tag --notes "Published from local machine"
}

Write-Host "Release published."
& gh release view $Tag --repo $Repo --json assets,url

Remove-Item -Path $tempDir -Recurse -Force
