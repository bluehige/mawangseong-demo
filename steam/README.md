# Steam release workspace

`release_config.json` is the machine-readable source of truth for Steam release
readiness. App IDs are public metadata and should replace the zero placeholders
after Steamworks creates them. Passwords, Steam Guard codes, SDK files, tax
records, bank data, certificates, and private keys must never be committed.

Local Windows builds require Godot 4.5.2 and its matching Windows export
templates. The tagged GitHub Actions build installs official templates itself,
so release artifacts do not depend on one developer PC.

## Commands

```powershell
# Repository structure and known pending items
python tools/release/validate_steam_release.py

# Launch-day gate; intentionally fails until every external item is complete
python tools/release/validate_steam_release.py --strict

# Create a tagged Windows depot build (project version must match)
./tools/release/PrepareSteamBuild.ps1 -Version 2.0.1

# Generate SteamPipe VDF only; does not contact Steam
./tools/release/UploadSteamBuild.ps1 `
  -BuildDir builds/steam/windows/v2.0.1 `
  -SteamUser YOUR_DEDICATED_BUILD_ACCOUNT `
  -GenerateOnly

# Upload after one interactive Steam Guard login has been completed
./tools/release/UploadSteamBuild.ps1 `
  -BuildDir builds/steam/windows/v2.0.1 `
  -SteamUser YOUR_DEDICATED_BUILD_ACCOUNT `
  -SteamworksSdkPath C:/SteamworksSDK
```

The upload script never passes a password on the command line and never sets
the default branch live. Test the uploaded build through Steam first, then set
it live from Steamworks with the appropriately authorized account.

Detailed portal values and user-owned onboarding steps live under
`steam/store/` and `docs/release/`.
