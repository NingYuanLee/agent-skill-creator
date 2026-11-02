param(
  [Parameter(Mandatory = $true)][string]$Name,
  [string]$SourceRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
  [string]$InstallRoot = (Join-Path $env:USERPROFILE '.agents\skills')
)

$ErrorActionPreference = 'Stop'

if ($Name -notmatch '^[a-z][a-z0-9-]*$') {
  throw "invalid skill name: '$Name' (must match ^[a-z][a-z0-9-]*$; underscores and uppercase are rejected by skill())"
}

$src = Join-Path $SourceRoot $Name
$skill = Join-Path $src 'SKILL.md'
if (-not (Test-Path -LiteralPath $skill)) {
  throw "missing source skill file: $skill"
}

$head = [IO.File]::ReadAllText($skill)
if ($head.Length -gt 2000) { $head = $head.Substring(0, 2000) }
$namePattern = '(?m)^name:\s*' + [regex]::Escape($Name) + '\s*$'
if ($head -notmatch $namePattern) {
  throw "frontmatter name in $skill does not match directory name '$Name'"
}

$inst = Join-Path $InstallRoot $Name
if (-not (Test-Path -LiteralPath $InstallRoot)) {
  New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
}
if (Test-Path -LiteralPath $inst) {
  $item = Get-Item -LiteralPath $inst -Force
  if ($item.LinkType) {
    if ($item.LinkType -ne 'Junction') { throw "existing install is not a junction: $inst" }
    [IO.Directory]::Delete($inst)
  }
  else {
    throw "existing install is a real directory; refusing to delete: $inst"
  }
}

New-Item -ItemType Junction -Path $inst -Target $src | Out-Null

$check = Get-Item -LiteralPath $inst -Force
if ($check.LinkType -ne 'Junction') {
  throw "install failed: $inst is not a junction"
}
$firstLine = (Get-Content -LiteralPath (Join-Path $inst 'SKILL.md') -TotalCount 1)
Write-Output "installed: $inst -> $src (junction, first line: $firstLine)"
