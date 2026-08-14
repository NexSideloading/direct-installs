# PowerShell script to download IPA files
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$ipaDir = Join-Path $repoRoot "ipas"
$stateFile = Join-Path $repoRoot "ipa_state.json"

# Create IPAs directory if it doesn't exist
if (-not (Test-Path $ipaDir)) {
    New-Item -ItemType Directory -Path $ipaDir -Force | Out-Null
}

# IPA sources
$ipaSources = @{
    "Ksign" = "https://github.com/Nyasami/Ksign/releases/latest/download/Ksign.ipa"
    "Feather" = "https://github.com/claration/Feather/releases/latest/download/Feather.ipa"
    "NexStore" = "https://github.com/NovaDev404/NexStore/releases/latest/download/NexStore.ipa"
    "ESign" = "https://github.com/Neoncat-OG/TrollStore-IPAs/releases/download/ESign/ESign-5.0.2.ipa"
    "ScarletAlpha" = "https://resources.usescarlet.com/repo/IPAs/ScarletAlpha.ipa"
    "CocoSign" = "https://api.cococloud-signing.vip/v1/app-version/16/download"
    "SideInstaller" = "https://github.com/FrizzleM/SideInstaller/releases/latest/download/SideInstaller.ipa"
    "iRAM-Plus" = "https://github.com/NovaDev404/iRAM-Plus/releases/latest/download/iRAM-Plus.ipa"
    "FlareStore" = "https://flarestore.vip/api/app/download-public/ios"
}

# Load existing state
$state = @{}
if (Test-Path $stateFile) {
    $state = Get-Content $stateFile -Raw | ConvertFrom-Json -AsHashtable
}

function Get-FileHash {
    param([string]$Path)
    $hash = Get-FileHash -Path $Path -Algorithm SHA256
    return $hash.Hash
}

function Download-IPA {
    param(
        [string]$Name,
        [string]$Url,
        [string]$OutputDir
    )
    
    $outputPath = Join-Path $OutputDir "$Name.ipa"
    $tempPath = Join-Path $OutputDir "$Name.ipa.tmp"
    
    Write-Host "Checking $Name..."
    
    try {
        # Try to download with timeout
        $ProgressPreference = 'SilentlyContinue'
        $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 30 -UseBasicParsing
        
        if ($response.StatusCode -eq 404) {
            Write-Host "  ❌ $Name returned 404, skipping"
            return $null
        }
        
        # Download the file
        Invoke-WebRequest -Uri $Url -OutFile $tempPath -TimeoutSec 30 -UseBasicParsing
        
        # Verify it's a valid zip file
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::OpenRead($tempPath) | Close-Read
            
            # Check for Payload directory (IPA structure)
            $zip = [System.IO.Compression.ZipFile]::OpenRead($tempPath)
            $hasPayload = $zip.Entries | Where-Object { $_.FullName -like "Payload/*" }
            $zip.Dispose()
            
            if (-not $hasPayload) {
                Write-Host "  ❌ $Name downloaded but doesn't appear to be a valid IPA, skipping"
                Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
                return $null
            }
        }
        catch {
            Write-Host "  ❌ $Name downloaded but is not a valid zip file, skipping"
            Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
            return $null
        }
        
        # Replace existing file
        if (Test-Path $outputPath) {
            Remove-Item $outputPath -Force
        }
        Move-Item $tempPath $outputPath
        
        Write-Host "  ✅ $Name downloaded successfully"
        return $outputPath
    }
    catch {
        Write-Host "  ❌ $Name failed to download: $($_.Exception.Message), skipping"
        if (Test-Path $tempPath) {
            Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        }
        return $null
    }
}

Write-Host "Downloading IPA files..."
Write-Host "=" * 50

foreach ($name in $ipaSources.Keys) {
    $url = $ipaSources[$name]
    $outputPath = Join-Path $ipaDir "$name.ipa"
    
    $resultPath = Download-IPA -Name $name -Url $url -OutputDir $ipaDir
    
    if ($resultPath) {
        # Calculate hash
        $fileHash = Get-FileHash -Path $resultPath
        $state[$name] = @{
            hash = $fileHash
            last_updated = (Get-Item $resultPath).LastWriteTime.ToString("o")
        }
    }
    else {
        # If download failed but file exists, keep existing state
        if (Test-Path $outputPath) {
            Write-Host "  ℹ️  $name keeping existing file due to download failure"
        }
        else {
            # Remove from state if file doesn't exist and download failed
            if ($state.ContainsKey($name)) {
                $state.Remove($name)
            }
        }
    }
}

# Save state
$state | ConvertTo-Json -Depth 10 | Set-Content $stateFile

Write-Host "=" * 50
Write-Host "IPA download process completed"