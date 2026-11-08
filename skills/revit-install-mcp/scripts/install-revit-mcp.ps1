<#
  Cai dat tu dong Revit MCP (mcp-server-for-revit-python) cho Claude.
  Chay lai nhieu lan van an toan (idempotent).

  Cach chay (PowerShell):
    powershell -ExecutionPolicy Bypass -File .\install-revit-mcp.ps1

  Tuy chon:
    -Ref <commit|branch>   Phien ban extension (mac dinh 4e8ec5f = ban truoc khi co co che ghep noi, dung cho pyRevit 6.5.2)
    -UseMaster             Dung nhanh master (ban moi, co xac thuc; can pyRevit chuyen duoc HTTP header)
    -ServerName <ten>      Ten server trong Claude (mac dinh Revit-Connector)
    -SkipFirewall          Bo qua quy tac chan cong 48884
    -SkipRoutes            Khong sua pyRevit_config.ini
    -Yes                   Khong hoi xac nhan truoc khi cai Git / uv (mac dinh script hoi Y/N)

  Neu may khong co winget, script tu tai va cai Git (GitHub release chinh thuc, kiem tra SHA256)
  va uv (https://astral.sh/uv/install.ps1) sau khi ban dong y.
#>
[CmdletBinding()]
param(
    [string]$Ref = '4e8ec5f',
    [switch]$UseMaster,
    [string]$ServerName = 'Revit-Connector',
    [switch]$SkipFirewall,
    [switch]$SkipRoutes,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$RepoUrl = 'https://github.com/mcp-servers-for-revit/mcp-server-for-revit-python.git'
$ExtDir  = Join-Path $env:APPDATA 'pyRevit\Extensions\mcp-server-for-revit-python.extension'
$Port    = 48884

function Step($m) { Write-Host ""; Write-Host "== $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "   [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "   [!]  $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "   [LOI] $m" -ForegroundColor Red; throw $m }

# Chay lenh ngoai (git, uv...) ma khong bi PowerShell 5.1 coi stderr la loi
function Run {
    param([string]$Exe, [string[]]$Arguments)
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $Exe @Arguments 2>&1 | ForEach-Object { Write-Host "      $_" }
    $code = $LASTEXITCODE
    $ErrorActionPreference = $old
    return $code
}

function Find-Uv {
    $c = Get-Command uv -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    $cands = @()
    $pk = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (Test-Path $pk) {
        $cands += Get-ChildItem $pk -Directory -Filter 'astral-sh.uv*' -ErrorAction SilentlyContinue |
                  ForEach-Object { Join-Path $_.FullName 'uv.exe' }
    }
    $cands += (Join-Path $env:USERPROFILE '.local\bin\uv.exe')
    $cands += (Join-Path $env:USERPROFILE '.cargo\bin\uv.exe')
    foreach ($p in $cands) { if (Test-Path $p) { return $p } }
    return $null
}

function Refresh-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
    foreach ($d in @('C:\Program Files\Git\cmd', (Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd'))) {
        if ((Test-Path $d) -and ($env:Path -notlike "*$d*")) { $env:Path += ";$d" }
    }
}

function Confirm-Action([string]$Text) {
    if ($Yes) { return $true }
    $a = Read-Host "   $Text (Y/N)"
    return ($a -match '^(y|yes)$')
}

function Test-Admin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Download the official Git for Windows installer from GitHub releases and run it silently.
function Install-GitDirect {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $rel = Invoke-RestMethod 'https://api.github.com/repos/git-for-windows/git/releases/latest' -Headers @{ 'User-Agent' = 'install-revit-mcp' }
    $asset = $rel.assets | Where-Object { $_.name -match '^Git-[\d\.]+-64-bit\.exe$' } | Select-Object -First 1
    if (-not $asset) { throw 'Could not find the 64-bit Git installer in the latest release.' }
    $tmp = Join-Path $env:TEMP $asset.name
    Write-Host "      Downloading $($asset.name) ..."
    Invoke-WebRequest $asset.browser_download_url -OutFile $tmp -UseBasicParsing
    if ($asset.digest -match '^sha256:(.+)$') {
        $actual = (Get-FileHash $tmp -Algorithm SHA256).Hash
        if ($actual -ine $Matches[1]) { Remove-Item $tmp -Force; throw 'SHA256 mismatch, installer deleted.' }
        Write-Host '      SHA256 verified.'
    } else { Write-Host '      [!] No SHA256 published for this asset; checksum not verified.' -ForegroundColor Yellow }
    $installArgs = @('/VERYSILENT','/NORESTART','/SUPPRESSMSGBOXES')
    if (-not (Test-Admin)) { $installArgs += '/CURRENTUSER' }
    $p = Start-Process $tmp -ArgumentList $installArgs -Wait -PassThru
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    return $p.ExitCode
}

# Official uv installer (installs to %USERPROFILE%\.local\bin).
function Install-UvDirect {
    $cmd = '[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; irm https://astral.sh/uv/install.ps1 | iex'
    return (Run 'powershell' @('-NoProfile','-ExecutionPolicy','Bypass','-Command',$cmd))
}

# ---------------------------------------------------------------- 1. Kiem tra
Step '1/8 Kiem tra moi truong'
$pyrevitDir = Join-Path $env:APPDATA 'pyRevit'
if (-not (Test-Path $pyrevitDir)) {
    Warn "Khong thay $pyrevitDir . Hay cai pyRevit va mo Revit it nhat 1 lan truoc."
    Fail 'Chua cai pyRevit.'
}
Ok "pyRevit: $pyrevitDir"

$revit = Get-ChildItem 'C:\Program Files\Autodesk' -Directory -Filter 'Revit 20*' -ErrorAction SilentlyContinue
if ($revit) { Ok ("Revit: " + (($revit | ForEach-Object Name) -join ', ')) }
else { Warn 'Khong thay Revit trong C:\Program Files\Autodesk (co the cai o cho khac).' }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Warn 'Chua co Git.'
    if (-not (Confirm-Action 'Git is required. Install Git for Windows now?')) {
        Fail 'Git la bat buoc. Cai thu cong tu https://git-scm.com roi chay lai script.'
    }
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host '   Dang cai Git bang winget...'
        [void](Run 'winget' @('install','--id','Git.Git','-e','--accept-source-agreements','--accept-package-agreements'))
        Refresh-Path
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Warn 'No winget (or it failed). Downloading the official Git for Windows installer from GitHub...'
        try { $gc = Install-GitDirect; if ($gc -ne 0) { Warn "Git installer exit code: $gc" } }
        catch { Warn "Direct Git install failed: $($_.Exception.Message)" }
        Refresh-Path
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Fail 'Khong cai duoc Git. Cai thu cong tu https://git-scm.com, mo PowerShell moi roi chay lai script.'
    }
}
Ok 'Git san sang'

# ---------------------------------------------------------------- 2. uv
Step '2/8 Cai uv'
$uv = Find-Uv
if (-not $uv) {
    if (-not (Confirm-Action 'uv (Python manager) is required. Install uv now?')) { Fail 'uv la bat buoc. Cai thu cong: https://docs.astral.sh/uv/' }
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        [void](Run 'winget' @('install','--id','astral-sh.uv','-e','--accept-source-agreements','--accept-package-agreements'))
        $uv = Find-Uv
    }
    if (-not $uv) {
        Warn 'No winget (or it failed). Installing uv with the official installer (astral.sh)...'
        [void](Install-UvDirect)
        Refresh-Path
        $uv = Find-Uv
    }
}
if (-not $uv) { Fail 'Khong tim thay uv sau khi cai. Mo lai PowerShell roi chay lai.' }
Ok "uv: $uv"

# ---------------------------------------------------------------- 3. Extension
Step '3/8 Lay extension'
if (-not (Test-Path (Join-Path $ExtDir '.git'))) {
    if (Test-Path $ExtDir) { Fail "$ExtDir da ton tai nhung khong phai repo git. Doi ten/xoa thu muc roi chay lai." }
    $code = Run 'git' @('clone', $RepoUrl, $ExtDir)
    if ($code -ne 0) { Fail 'git clone that bai (kiem tra mang/proxy cong ty).' }
}
Ok "Thu muc: $ExtDir"

Push-Location $ExtDir
try {
    if ($UseMaster) {
        [void](Run 'git' @('fetch','--all'))
        $code = Run 'git' @('switch','master')
        if ($code -ne 0) { Fail 'Khong chuyen duoc sang master.' }
        Ok 'Dung nhanh master (co xac thuc - can pyRevit chuyen header; xem huong dan)'
    } else {
        $branch = 'local/pre-pairing'
        & git rev-parse --verify $branch *> $null
        if ($LASTEXITCODE -eq 0) {
            [void](Run 'git' @('switch',$branch))
        } else {
            $code = Run 'git' @('switch','-c',$branch,$Ref)
            if ($code -ne 0) { Fail "Khong checkout duoc $Ref" }
        }
        Ok "Dung phien ban $Ref (nhanh $branch)"
    }

    # ------------------------------------------------------------ 4. Python deps
    Step '4/8 Cai thu vien Python (uv sync)'
    [void](Run $uv @('python','install','3.13'))
    $code = Run $uv @('sync','--frozen','--link-mode=copy')
    if ($code -ne 0) {
        Warn 'uv sync loi, thu lai voi duong dan Python day du...'
        $pyexe = (& $uv python find 3.13 2>$null)
        if ($pyexe) { $code = Run $uv @('sync','--frozen','--link-mode=copy','--python',$pyexe) }
    }
    if ($code -ne 0) {
        Warn 'Van loi: neu .venv bi khoa, dong Revit/Claude, doi ten .venv thanh .venv-old roi chay lai.'
        Fail 'uv sync that bai.'
    }
    Ok 'Da cai thu vien'

    Step '5/8 Kiem tra server khoi dong duoc'
    $code = Run $uv @('run','--frozen','python','-c',"import main; print('IMPORT_OK')")
    if ($code -ne 0) { Fail 'Khong import duoc main.py.' }
    Ok 'main.py import thanh cong'
}
finally { Pop-Location }

# ---------------------------------------------------------------- 6. Routes
Step '6/8 Bat pyRevit Routes'
if ($SkipRoutes) {
    Warn 'Bo qua (-SkipRoutes). Tu bat trong Revit: pyRevit > Settings > Routes.'
} else {
    $ini = Join-Path $pyrevitDir 'pyRevit_config.ini'
    if (-not (Test-Path $ini)) {
        Warn 'Chua co pyRevit_config.ini (mo Revit 1 lan, sau do bat Routes trong pyRevit > Settings > Routes).'
    } else {
        Copy-Item $ini "$ini.bak" -Force
        $lines = [System.Collections.Generic.List[string]](Get-Content $ini)
        $start = -1
        for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i].Trim() -ieq '[routes]') { $start = $i; break } }
        if ($start -lt 0) {
            $lines.Add(''); $lines.Add('[routes]'); $lines.Add('enabled = true')
        } else {
            $end = $lines.Count
            for ($j = $start + 1; $j -lt $lines.Count; $j++) { if ($lines[$j].Trim().StartsWith('[')) { $end = $j; break } }
            $found = $false
            for ($k = $start + 1; $k -lt $end; $k++) {
                if ($lines[$k] -match '^\s*enabled\s*=') { $lines[$k] = 'enabled = true'; $found = $true; break }
            }
            if (-not $found) { $lines.Insert($start + 1, 'enabled = true') }
        }
        [System.IO.File]::WriteAllLines($ini, $lines, (New-Object System.Text.UTF8Encoding($false)))
        Ok 'Da dat [routes] enabled = true (da sao luu .bak). Can KHOI DONG LAI Revit.'
    }
}

# ---------------------------------------------------------------- 7. Claude config
Step '7/8 Dang ky voi Claude'
$cfgDirs = @((Join-Path $env:APPDATA 'Claude'))
$store = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Packages') -Directory -Filter 'Claude_*' -ErrorAction SilentlyContinue
foreach ($s in $store) { $cfgDirs += (Join-Path $s.FullName 'LocalCache\Roaming\Claude') }
$cfgDirs = $cfgDirs | Where-Object { Test-Path $_ }
if (-not $cfgDirs) { $cfgDirs = @((Join-Path $env:APPDATA 'Claude')); New-Item -ItemType Directory -Path $cfgDirs[0] -Force | Out-Null }

foreach ($d in $cfgDirs) {
    $cfgPath = Join-Path $d 'claude_desktop_config.json'
    if (Test-Path $cfgPath) {
        Copy-Item $cfgPath "$cfgPath.bak" -Force
        $raw = Get-Content $cfgPath -Raw
        if ([string]::IsNullOrWhiteSpace($raw)) { $cfg = [pscustomobject]@{} } else { $cfg = $raw | ConvertFrom-Json }
    } else { $cfg = [pscustomobject]@{} }

    if (-not ($cfg.PSObject.Properties.Name -contains 'mcpServers')) {
        $cfg | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([pscustomobject]@{})
    }
    $server = [pscustomobject]@{
        command = $uv
        args    = @('run','--frozen','--directory',$ExtDir,'mcp','run',(Join-Path $ExtDir 'main.py'))
    }
    $cfg.mcpServers | Add-Member -NotePropertyName $ServerName -NotePropertyValue $server -Force
    [System.IO.File]::WriteAllText($cfgPath, ($cfg | ConvertTo-Json -Depth 20), (New-Object System.Text.UTF8Encoding($false)))
    Ok "Claude Desktop: $cfgPath"
}

$claudeCli = Get-Command claude -ErrorAction SilentlyContinue
if ($claudeCli) {
    [void](Run 'claude' @('mcp','remove','-s','user',$ServerName))
    $code = Run 'claude' @('mcp','add','-s','user',$ServerName,'--',$uv,'run','--frozen','--directory',$ExtDir,'mcp','run',(Join-Path $ExtDir 'main.py'))
    if ($code -eq 0) { Ok 'Claude Code (CLI) da dang ky' } else { Warn 'Dang ky Claude Code that bai (bo qua).' }
} else { Warn 'Khong co lenh claude (CLI) - bo qua Claude Code.' }

# ---------------------------------------------------------------- 8. Firewall
Step '8/8 Tuong lua (chan truy cap tu may khac vao cong 48884)'
if ($SkipFirewall) {
    Warn 'Bo qua (-SkipFirewall).'
} else {
    $ruleName = "Block pyRevit Routes $Port inbound"
    $isAdmin = Test-Admin
    if (-not $isAdmin) {
        Warn 'Khong co quyen Administrator. Mo PowerShell bang "Run as administrator" va chay:'
        Write-Host "   New-NetFirewallRule -DisplayName `"$ruleName`" -Direction Inbound -Protocol TCP -LocalPort $Port -Action Block" -ForegroundColor Gray
    } elseif (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue) {
        Ok 'Quy tac da ton tai'
    } else {
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $Port -Action Block | Out-Null
        Ok 'Da tao quy tac chan'
    }
}

# ---------------------------------------------------------------- Xong
Write-Host ""
Write-Host "HOAN TAT. Lam tiep:" -ForegroundColor Green
Write-Host "  1. Dong HAN Revit, mo lai, mo mot model (khong dung Reload pyRevit)."
Write-Host "  2. Quit HAN Claude Desktop (chuot phai bieu tuong khay he thong > Quit), mo lai."
Write-Host "  3. Mo chat moi va hoi: 'Kiem tra trang thai ket noi Revit'."
Write-Host ""
Write-Host "Kiem tra bang tay (sau khi Revit da mo model):"
Write-Host "  cd `"$ExtDir`""
Write-Host "  & `"$uv`" run --frozen python -c `"import anyio; from main import revit_get; print(anyio.run(revit_get, '/status/'))`""
