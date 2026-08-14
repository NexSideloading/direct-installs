#!/usr/bin/env python3
"""
Main script to run the entire signing workflow.
This orchestrates downloading IPAs, fetching certificates, and signing apps.
"""
import sys
import subprocess
from pathlib import Path

def run_script(script_name: str) -> bool:
    """Run a Python script and return success status."""
    script_path = Path(__file__).parent / script_name
    
    if not script_path.exists():
        print(f"Error: Script not found: {script_path}")
        return False
    
    print(f"\n{'='*60}")
    print(f"Running: {script_name}")
    print('='*60)
    
    result = subprocess.run([sys.executable, str(script_path)], cwd=Path(__file__).parent.parent)
    
    if result.returncode != 0:
        print(f"Error: {script_name} failed with exit code {result.returncode}")
        return False
    
    print(f"✅ {script_name} completed successfully")
    return True

def main():
    """Main function to run all scripts in sequence."""
    print("Starting automated app signing workflow...")
    print("This will download IPAs, fetch certificates, and sign apps.")
    
    scripts = [
        "download_ipas.py",
        "fetch_certificates.py", 
        "sign_apps.py"
    ]
    
    failed_scripts = []
    
    for script in scripts:
        if not run_script(script):
            failed_scripts.append(script)
    
    print("\n" + "="*60)
    print("Workflow Summary")
    print("="*60)
    
    if failed_scripts:
        print(f"❌ Workflow completed with {len(failed_scripts)} failed script(s):")
        for script in failed_scripts:
            print(f"  - {script}")
        return 1
    else:
        print("✅ All scripts completed successfully!")
        print("\nNext steps:")
        print("1. Check the signed_apps/ directory for signed IPAs")
        print("2. Upload signed_apps/ to your hosting service")
        print("3. Update manifest.plist URLs if needed")
        return 0

if __name__ == "__main__":
    sys.exit(main())