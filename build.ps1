<#
.SYNOPSIS
    Build script for WhatsAppLite (Pake + Tauri wrapper around web.whatsapp.com).

.DESCRIPTION
    Automates the steps from the README's "Build From Source" section:
      0. Enable Windows Long Paths (requires admin + reboot)
      1. Check/prompt for Node.js
      2. Install pnpm
      3. Check/prompt for Rust (rustup)
      4. Check/prompt for MSVC Build Tools
      5. Check/prompt for WebView2 Runtime
      6. Install Pake CLI
      7. Run the Pake build command

.NOTES
    Run this from a normal PowerShell window. Steps that require Administrator
    rights (Long Paths) will trigger an elevation prompt automatically.

    Re-run the script any time — it skips steps that are already satisfied.
#>

[CmdletBinding()]
param(
    [string]$AppName   = "WhatsAppLite",
    [string]$IconPath  = "",            # e.g. ".\icon.ico" — leave blank to use Pake's default
    [int]$Width        = 1200,
    [int]$Height       = 800,
    [switch]$SkipLongPathsCheck         # pass this if you've already enabled Long Paths and rebooted
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "    [OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "    [!]  $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "    [X]  $Message" -ForegroundColor Red
}

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Test-IsAdmin {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# -----------------------------------------------------------------------------
# Step 0 — Long Paths
# -----------------------------------------------------------------------------
Write-Step "Step 0: Checking Windows Long Paths setting"

if ($SkipLongPathsCheck) {
    Write-Warn "Skipping Long Paths check (-SkipLongPathsCheck passed)."
} else {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
    $current = (Get-ItemProperty -Path $regPath -Name LongPathsEnabled -ErrorAction SilentlyContinue).LongPathsEnabled

    if ($current -eq 1) {
        Write-Ok "Long Paths is already enabled."
    } else {
        Write-Warn "Long Paths is NOT enabled. This commonly causes mysterious build failures"
        Write-Warn "(e.g. inside deep pnpm/cargo paths like AppData\Local\pnpm\store\v11\...)."

        if (-not (Test-IsAdmin)) {
            Write-Host ""
            Write-Host "    This requires Administrator rights. Re-launching this script elevated..." -ForegroundColor Yellow
            $scriptPath = $MyInvocation.MyCommand.Path
            Start-Process powershell -Verb RunAs -ArgumentList "-NoExit -File `"$scriptPath`" -SkipLongPathsCheck:`$false"
            Write-Host "    A new elevated window has opened to set the registry key. Continuing in THIS window assuming it's already set, or close this one and use the elevated window instead." -ForegroundColor Yellow
        }

        try {
            reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f | Out-Null
            Write-Ok "Long Paths registry key set."
            Write-Warn "You MUST reboot your computer before this takes effect."
            $reboot = Read-Host "    Reboot now? (y/n)"
            if ($reboot -eq "y") {
                Restart-Computer -Confirm
                exit
            } else {
                Write-Warn "Remember to reboot before building, or the build may fail with path-length errors."
            }
        } catch {
            Write-Fail "Could not set the registry key automatically. Run this manually as Administrator:"
            Write-Host '        reg add HKLM\SYSTEM\CurrentControlSet\Control\FileSystem /v LongPathsEnabled /t REG_DWORD /d 1 /f'
            Write-Host "        Then reboot."
        }
    }
}

# -----------------------------------------------------------------------------
# Step 1 — Node.js
# -----------------------------------------------------------------------------
Write-Step "Step 1: Checking Node.js"

if (Test-CommandExists "node") {
    $nodeVersion = node -v
    Write-Ok "Node.js found: $nodeVersion"
} else {
    Write-Fail "Node.js not found."
    Write-Host "    Install it from: https://nodejs.org (LTS, 18+ minimum, 22+ recommended)"
    Write-Host "    After installing, close this window, open a NEW terminal, and re-run this script."
    exit 1
}

# -----------------------------------------------------------------------------
# Step 2 — pnpm
# -----------------------------------------------------------------------------
Write-Step "Step 2: Checking / installing pnpm"

if (Test-CommandExists "pnpm") {
    $pnpmVersion = pnpm -v
    Write-Ok "pnpm found: $pnpmVersion"
} else {
    Write-Warn "pnpm not found. Installing via npm..."
    try {
        npm install -g pnpm
        Write-Ok "pnpm installed."
    } catch {
        Write-Fail "Failed to install pnpm."
        Write-Host "    If you see 'running scripts is disabled', run as Administrator:"
        Write-Host "        Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
        exit 1
    }
}

# -----------------------------------------------------------------------------
# Step 3 — Rust
# -----------------------------------------------------------------------------
Write-Step "Step 3: Checking Rust toolchain"

if (Test-CommandExists "cargo") {
    $cargoVersion = cargo --version
    Write-Ok "Rust/Cargo found: $cargoVersion"
} else {
    Write-Fail "Rust (cargo) not found."
    Write-Host "    Install it from: https://rustup.rs (download rustup-init.exe, accept defaults)"
    Write-Host "    After installing, close this window, open a NEW terminal, and re-run this script."
    exit 1
}

# -----------------------------------------------------------------------------
# Step 4 — MSVC Build Tools (best-effort check)
# -----------------------------------------------------------------------------
Write-Step "Step 4: Checking for MSVC Build Tools (linker)"

$linkFound = $false
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
    $vsInstalls = & $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
    if ($vsInstalls) { $linkFound = $true }
}

if ($linkFound) {
    Write-Ok "MSVC C++ Build Tools detected."
} else {
    Write-Warn "Could not confirm MSVC C++ Build Tools are installed."
    Write-Warn "If the build later fails with 'link.exe not found', install them from:"
    Write-Warn "https://visualstudio.microsoft.com/visual-cpp-build-tools/ (select 'Desktop development with C++')"
}

# -----------------------------------------------------------------------------
# Step 5 — WebView2 Runtime (best-effort check)
# -----------------------------------------------------------------------------
Write-Step "Step 5: Checking for WebView2 Runtime"

$webview2Key = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
$webview2KeyAlt = "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"

if ((Test-Path $webview2Key) -or (Test-Path $webview2KeyAlt)) {
    Write-Ok "WebView2 Runtime detected."
} else {
    Write-Warn "Could not confirm WebView2 Runtime is installed."
    Write-Warn "If the built app shows a blank white window, install it from:"
    Write-Warn "https://developer.microsoft.com/en-us/microsoft-edge/webview2/"
}

# -----------------------------------------------------------------------------
# Step 6 — Pake CLI
# -----------------------------------------------------------------------------
Write-Step "Step 6: Checking / installing Pake CLI"

if (Test-CommandExists "pake") {
    $pakeVersion = pake --version
    Write-Ok "Pake CLI found: $pakeVersion"
} else {
    Write-Warn "Pake CLI not found. Installing..."
    pnpm install -g pake-cli
    Write-Ok "Pake CLI installed."
}

# -----------------------------------------------------------------------------
# Step 7 — Build
# -----------------------------------------------------------------------------
Write-Step "Step 7: Building $AppName"

$pakeArgs = @(
    "https://web.whatsapp.com",
    "--name", $AppName,
    "--width", $Width,
    "--height", $Height
)

if ($IconPath -and (Test-Path $IconPath)) {
    $pakeArgs += @("--icon", $IconPath)
    Write-Ok "Using custom icon: $IconPath"
} elseif ($IconPath) {
    Write-Warn "Icon path '$IconPath' not found — building with Pake's default icon instead."
} else {
    Write-Warn "No icon specified — building with Pake's default icon."
}

Write-Host ""
Write-Host "    Running: pake $($pakeArgs -join ' ')" -ForegroundColor DarkGray
Write-Host ""

& pake @pakeArgs

if ($LASTEXITCODE -eq 0) {
    Write-Step "Build complete"
    Write-Ok "Look for $AppName.exe in the current directory."
    Write-Ok "Double-click it to launch — no installer, no setup wizard."
} else {
    Write-Fail "Build failed (exit code $LASTEXITCODE). Common causes:"
    Write-Host "    - Long Paths not enabled / not rebooted yet (Step 0)"
    Write-Host "    - MSVC Build Tools missing (Step 4)"
    Write-Host "    - Network/firewall blocking the Tauri template download"
    Write-Host "    See the README's Troubleshooting section for details."
    exit 1
}
