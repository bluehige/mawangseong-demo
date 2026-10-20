# GodotSteam 4.23.1 / Windows x64

Official Godot 4.4+ GDExtension, tested with Godot 4.6.3. Steamworks SDK 1.65.
The upstream MIT license is in `license.md`. Binary provenance, archive URL and
SHA-256 values are in `PROVENANCE.json`. No custom engine or module templates.

Reproduce: `python tools/achievements/vendor_godotsteam.py`.
DLLs and license are unchanged upstream bytes; the extension descriptor retains
only Windows x64 library/dependency entries. Other platforms skip the descriptor
through the existing export plugin. Windows export uses standard Godot templates.

The bridge uses `steamInitEx(5267750, false)` and manual callbacks. SDK 1.65 no
longer exposes `requestCurrentStats`; it requests `requestUserStats(getSteamID())`
and validates the returned app/user before using stats. No restart or Steam launch.

The root `steam_appid.txt` is for local development only, and excluded from every
export. `MAWANG_DISABLE_STEAM=1` disables API initialization for isolated tests.
Production launch through Steam supplies the App ID; the bridge also passes the
explicit application ID. No account credentials, SDK installer, upload tools,
remote changes or Steamworks definitions are included in this addon.
