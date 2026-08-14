#!/usr/bin/env python3
import os
import sys
import requests
import hashlib
import json
from pathlib import Path
from typing import Dict, Optional

# IPA sources with their URLs
IPA_SOURCES = {
    "Ksign": "https://github.com/Nyasami/Ksign/releases/latest/download/Ksign.ipa",
    "Feather": "https://github.com/claration/Feather/releases/latest/download/Feather.ipa",
    "NexStore": "https://github.com/NovaDev404/NexStore/releases/latest/download/NexStore.ipa",
    "ESign": "https://github.com/Neoncat-OG/TrollStore-IPAs/releases/download/ESign/ESign-5.0.2.ipa",
    "Scarlet": "https://github.com/NovaDev404/apps/raw/refs/heads/main/ScarletAlpha.ipa",
    "SideInstaller": "https://github.com/FrizzleM/SideInstaller/releases/latest/download/SideInstaller.ipa",
}

# State file to track downloaded IPAs
STATE_FILE = Path(__file__).parent.parent / "ipa_state.json"

def load_state() -> Dict:
    """Load the current state of downloaded IPAs."""
    if STATE_FILE.exists():
        with open(STATE_FILE, 'r') as f:
            return json.load(f)
    return {}

def save_state(state: Dict):
    """Save the current state of downloaded IPAs."""
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f, indent=2)

def get_file_hash(filepath: Path) -> str:
    """Calculate SHA256 hash of a file."""
    sha256_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def download_ipa(name: str, url: str, output_dir: Path, timeout: int = 30) -> Optional[Path]:
    """Download an IPA file from URL, returns path if successful."""
    output_path = output_dir / f"{name}.ipa"
    
    print(f"Checking {name}...")
    
    try:
        response = requests.head(url, timeout=timeout, allow_redirects=True)
        if response.status_code == 404:
            print(f"  ❌ {name} returned 404, skipping")
            return None
        
        response = requests.get(url, timeout=timeout, stream=True)
        response.raise_for_status()
        
        # Check if content type is IPA
        content_type = response.headers.get('content-type', '')
        if 'html' in content_type.lower() or 'text' in content_type.lower():
            print(f"  ❌ {name} returned non-IPA content (content-type: {content_type}), skipping")
            return None
        
        # Download to temp file first
        temp_path = output_dir / f"{name}.ipa.tmp"
        with open(temp_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        # Verify it's a valid zip file (IPAs are zip files)
        try:
            import zipfile
            with zipfile.ZipFile(temp_path, 'r') as zip_ref:
                # Check if it has Payload directory (IPA structure)
                if 'Payload/' not in zip_ref.namelist():
                    print(f"  ❌ {name} downloaded but doesn't appear to be a valid IPA, skipping")
                    temp_path.unlink()
                    return None
        except zipfile.BadZipFile:
            print(f"  ❌ {name} downloaded but is not a valid zip file, skipping")
            temp_path.unlink()
            return None
        
        # Move temp file to final location
        if output_path.exists():
            output_path.unlink()
        temp_path.rename(output_path)
        
        print(f"  ✅ {name} downloaded successfully")
        return output_path
        
    except requests.exceptions.Timeout:
        print(f"  ❌ {name} timed out, skipping")
        return None
    except requests.exceptions.RequestException as e:
        print(f"  ❌ {name} failed to download: {e}, skipping")
        return None
    except Exception as e:
        print(f"  ❌ {name} unexpected error: {e}, skipping")
        return None

def main():
    """Main function to download all IPAs."""
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent
    ipa_dir = repo_root / "ipas"
    
    # Create IPAs directory
    ipa_dir.mkdir(parents=True, exist_ok=True)
    
    # Load current state
    state = load_state()
    
    print("Downloading IPA files...")
    print("=" * 50)
    
    for name, url in IPA_SOURCES.items():
        output_path = ipa_dir / f"{name}.ipa"
        
        # Download the IPA
        result_path = download_ipa(name, url, ipa_dir)
        
        if result_path:
            # Calculate hash of downloaded file
            file_hash = get_file_hash(result_path)
            state[name] = {
                'hash': file_hash,
                'last_updated': str(Path(result_path).stat().st_mtime)
            }
        else:
            # If download failed but file exists, keep existing state
            if output_path.exists():
                print(f"  ℹ️  {name} keeping existing file due to download failure")
            else:
                # Remove from state if file doesn't exist and download failed
                if name in state:
                    del state[name]
    
    # Save updated state
    save_state(state)
    
    print("=" * 50)
    print("IPA download process completed")

if __name__ == "__main__":
    main()