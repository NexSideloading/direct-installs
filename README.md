# Sideloading Direct Installs

Automated system for downloading iOS apps, fetching certificates from NexCerts API, and signing apps with certificates for sideloading.

## Features

- **Automated IPA Downloads**: Downloads the latest versions of popular sideloading apps
- **Certificate Management**: Fetches and tracks certificates from the NexCerts API
- **App Signing**: Signs apps with available certificates using zsign
- **Manifest Generation**: Creates install manifests for easy sideloading
- **Asset Injection**: Injects signing assets into compatible apps (Ksign, Feather, NexStore, CocoSign)
- **Cleanup**: Automatically removes signed apps for revoked/missing certificates
- **Scheduled Updates**: Runs twice daily via GitHub Actions

## Supported Apps

- [x] Ksign
- [x] Feather
- [ ] NexStore
- [x] ESign
- [x] Scarlet
- [ ] CocoSign
- [ ] SideInstaller
- [ ] iRAM Plus
- [ ] FlareStore

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── sign-apps.yml       # GitHub Actions workflow
├── scripts/
│   ├── download_ipas.py       # Downloads IPA files
│   ├── fetch_certificates.py  # Fetches certificates from API
│   ├── sign_apps.py           # Signs apps with certificates
│   ├── extract_ipa_metadata.py # Extracts IPA metadata
│   └── check_injected_signing_assets.py # Validates signing assets
├── ipas/                       # Downloaded IPA files
├── certificates/              # Downloaded certificates
├── signed_apps/               # Signed apps organized by app/certificate
├── requirements.txt           # Python dependencies
└── README.md
```

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/direct-installs.git
   cd direct-installs
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure the project**
   - Edit `config.json` to set your GitHub repository details
   - Adjust certificate filters if needed (include/exclude revoked or missing P12 certificates)

4. **Configure GitHub Actions**
   - Enable GitHub Actions in your repository settings
   - The workflow will run automatically twice daily

## Manual Usage

### Run All Scripts (Recommended)
```bash
python scripts/run_all.py
```

Or on Windows:
```powershell
python scripts/run_all.ps1
```

### Individual Scripts
```bash
# Download IPAs
python scripts/download_ipas.py

# Fetch Certificates
python scripts/fetch_certificates.py

# Sign Apps
python scripts/sign_apps.py
```

## Output Structure

Signed apps are organized as:
```
signed_apps/
├── AppName/
│   ├── Certificate Name/
│   │   ├── signed.ipa
│   │   └── manifest.plist
```

## GitHub Actions

The workflow runs automatically:
- Schedule: Twice daily at 00:00 and 12:00 UTC
- Manual trigger: Available via workflow_dispatch

## State Files

The system maintains state in JSON files:
- `ipa_state.json`: Tracks downloaded IPA versions
- `certificates_state.json`: Tracks certificate information
- `signing_state.json`: Tracks which apps are signed with which certificates

## Notes

- Missing P12 certificates are always skipped for signing (can't sign without P12)
- Revoked and signed certificates are used for signing (configurable via cert_filters)
- Apps that fail to download (404, timeout, invalid format) are skipped
- Certificate changes trigger re-signing of affected apps
- Removed certificates trigger cleanup of associated signed apps

## License

This project is for educational purposes only.
