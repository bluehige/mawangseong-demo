"""Install only the official 4.23.1 Windows x64 GDExtension, with pinned hashes."""
import hashlib
import json
import tarfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
URL = 'https://codeberg.org/godotsteam/godotsteam/releases/download/v4.23.1/godotsteam-4.23.1-gdextension-plugin-4.4.zip.tar.xz'
SHA256 = '37d53ede5eda11d2247d70c1af91f95a4777ad2a419fc8a24de1cc816d21cc0a'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    archive = ROOT / 'tmp/v130r_step13/godotsteam-4.23.1.tar.xz'
    archive.parent.mkdir(parents=True, exist_ok=True)
    if not archive.exists():
        urllib.request.urlretrieve(URL, archive)
    assert digest(archive.read_bytes()) == SHA256, 'Official archive hash differs; refuse replacement'
    installed = {}
    with tarfile.open(archive) as source:
        names = ['addons/godotsteam/license.md', 'addons/godotsteam/godotsteam.gdextension']
        names += [m.name for m in source.getmembers() if m.isfile() and m.name.startswith('addons/godotsteam/win64/')]
        for name in names:
            data = source.extractfile(name).read()
            original_hash = digest(data)
            if name.endswith('.gdextension'):
                # The project currently exports Windows x64 only for Steam.
                excluded = ('android.', 'linux.', 'macos.', 'windows.debug.x86_32',
                            'windows.release.x86_32', 'windows.x86_32')
                data = ('\n'.join(line for line in data.decode().splitlines()
                                  if not line.startswith(excluded)) + '\n').encode()
            destination = ROOT / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(data)
            installed[name] = dict(sha256=digest(data), official_sha256=original_hash, bytes=len(data))
    manifest = dict(version='4.23.1', steamworks_sdk='1.65', godot_minimum='4.4',
                    tested_godot='4.6.3.stable.official.7d41c59c4', acquired_date='2026-10-18',
                    official_catalog='https://godotengine.org/asset-library/asset/2445',
                    archive_url=URL, archive_sha256=SHA256,
                    modifications='Only Windows x64 entries retained in .gdextension. DLLs/license byte-identical.',
                    files=installed)
    (ROOT / 'addons/godotsteam/PROVENANCE.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf8')
    print('Official GodotSteam 4.23.1 Windows x64 installed; archive and DLL hashes verified')


if __name__ == '__main__':
    main()
