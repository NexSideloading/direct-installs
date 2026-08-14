# PowerShell script to run the entire signing workflow
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

Write-Host "Starting automated app signing workflow..." -ForegroundColor Green
Write-Host "This will download IPAs, fetch certificates, and sign apps." -ForegroundColor Green

$scripts = @(
    "download_ipas.py",
    "fetch_certificates.py",
    "sign_apps.py"
)

$failedScripts = @()

foreach ($script in $scripts) {
    $scriptPath = Join-Path $scriptDir $script
    
    if (-not (Test-Path $scriptPath)) {
        Write-Host "Error: Script not found: $scriptPath" -ForegroundColor Red
        $failedScripts += $script
        continue
    }
    
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "Running: $script" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    $process = Start-Process -FilePath "python" -ArgumentList $scriptPath -WorkingDirectory $repoRoot -Wait -PassThru
    
    if ($process.ExitCode -ne 0) {
        Write-Host "Error: $script failed with exit code $($process.ExitCode)" -ForegroundColor Red
        $failedScripts += $script
    } else {
        Write-Host "✅ $script completed successfully" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "Workflow Summary" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

if ($failedScripts.Count -gt 0) {
    Write-Host "❌ Workflow completed with $($failedScripts.Count) failed script(s):" -ForegroundColor Red
    foreach ($script in $failedScripts) {
        Write-Host "  - $script" -ForegroundColor Red
    }
    exit 1
} else {
    Write-Host "✅ All scripts completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Check the signed_apps/ directory for signed IPAs" -ForegroundColor White
    Write-Host "2. Upload signed_apps/ to your hosting service" -ForegroundColor White
    Write-Host "3. Update manifest.plist URLs if needed" -ForegroundColor White
    exit 0
}