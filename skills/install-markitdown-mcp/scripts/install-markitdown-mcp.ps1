<#
.SYNOPSIS
  Installs markitdown-mcp and registers it in Claude Desktop config.
  Safe to re-run: backs up the config and keeps all other MCP servers.
#>
$ErrorActionPreference = 'Stop'

function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path','User')
}

# 1. Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host 'Python not found - installing via winget...'
    winget install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements
    Update-SessionPath
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        throw 'Python installed but not on PATH yet. Open a new terminal and re-run this script.'
    }
}

# 2. markitdown-mcp
python -m pip install --upgrade markitdown-mcp
if ($LASTEXITCODE -ne 0) { throw 'pip install failed.' }

# Locate the executable (Scripts folder may not be on PATH)
$exe = (Get-Command markitdown-mcp -ErrorAction SilentlyContinue).Source
if (-not $exe) {
    $scripts = python -c "import sysconfig;print(sysconfig.get_path('scripts'))"
    $exe = Join-Path $scripts 'markitdown-mcp.exe'
}
if (-not (Test-Path $exe)) { throw "markitdown-mcp executable not found: $exe" }

# 3. Claude Desktop config (merge, never overwrite)
$cfgPath = Join-Path $env:APPDATA 'Claude\claude_desktop_config.json'
New-Item -ItemType Directory -Force -Path (Split-Path $cfgPath) | Out-Null
if (Test-Path $cfgPath) {
    Copy-Item $cfgPath "$cfgPath.bak" -Force
    $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
} else {
    $cfg = [pscustomobject]@{}
}
if (-not $cfg.PSObject.Properties['mcpServers']) {
    $cfg | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([pscustomobject]@{})
}
$entry = [pscustomobject]@{ command = $exe; args = @() }
$cfg.mcpServers | Add-Member -NotePropertyName markitdown -NotePropertyValue $entry -Force
$cfg | ConvertTo-Json -Depth 10 | Set-Content $cfgPath -Encoding UTF8

Write-Host "OK. markitdown registered in $cfgPath"
Write-Host 'Restart Claude Desktop to load it.'
