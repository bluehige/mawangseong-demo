"""Verify the exact offline Steam payload. Does not launch Steam or the game."""
import ctypes
import hashlib
import json
import re
import sys
from pathlib import Path


def pe_version(path):
    class FixedInfo(ctypes.Structure):
        _fields_ = [(name, ctypes.c_uint32) for name in (
            'signature', 'structure', 'file_ms', 'file_ls', 'product_ms',
            'product_ls', 'mask', 'flags', 'os', 'type', 'subtype', 'date_ms', 'date_ls')]
    api = ctypes.windll.version
    size = api.GetFileVersionInfoSizeW(str(path), None)
    if not size:
        raise ValueError('Missing Windows version resource: ' + str(path))
    data = ctypes.create_string_buffer(size)
    if not api.GetFileVersionInfoW(str(path), 0, size, data):
        raise ValueError('Unreadable Windows version resource')
    pointer, length = ctypes.c_void_p(), ctypes.c_uint()
    if not api.VerQueryValueW(data, '\\', ctypes.byref(pointer), ctypes.byref(length)):
        raise ValueError('Missing fixed version info')
    value = ctypes.cast(pointer, ctypes.POINTER(FixedInfo)).contents
    def version(ms, ls):
        return '.'.join(map(str, (ms >> 16, ms & 65535, ls >> 16, ls & 65535)))
    return version(value.file_ms, value.file_ls), version(value.product_ms, value.product_ls)


def verify(root=None):
    root = Path(root) if root else Path(__file__).resolve().parent
    content = root / 'Content'
    manifest = json.loads((content / 'steam-build-manifest.json').read_text(encoding='utf-8'))
    expected = json.loads((root / 'Scripts/package_identity.json').read_text(encoding='utf-8'))
    if manifest['version'] != '1.3.0' or manifest['source_commit'] != expected['source_commit']:
        raise ValueError('Wrong version/source commit')
    if not re.fullmatch('[0-9a-f]{40}', manifest['source_commit']):
        raise ValueError('Invalid source SHA')
    listed = set()
    for row in manifest['artifacts']:
        relative = Path(row['path'])
        if relative.is_absolute() or '..' in relative.parts or row['path'] in listed:
            raise ValueError('Unsafe or duplicate manifest path')
        file = content / relative
        if not file.is_file() or file.is_symlink() or file.stat().st_size != row['bytes']:
            raise ValueError('Missing/changed file: ' + row['path'])
        with file.open('rb') as stream:
            if hashlib.file_digest(stream, 'sha256').hexdigest() != row['sha256']:
                raise ValueError('Hash mismatch: ' + row['path'])
        listed.add(row['path'])
    actual = {p.relative_to(content).as_posix() for p in content.rglob('*') if p.is_file()}
    if actual != listed | {'steam-build-manifest.json'}:
        raise ValueError('Unexpected/missing Content files: ' + str(actual ^ (listed | {'steam-build-manifest.json'})))
    required = {'MawangCastle.exe', 'MawangCastle.pck', 'steam_api64.dll',
        'libgodotsteam.windows.template_release.x86_64.dll', 'THIRD_PARTY_NOTICES.txt',
        'licenses/Godot-COPYRIGHT.txt', 'licenses/GodotSteam_LICENSE.txt',
        'licenses/NotoSansCJK_LICENSE.txt', 'licenses/NEXON_Maplestory_LICENSE.txt'}
    if not required <= listed:
        raise ValueError('Required runtime/license files missing: ' + str(required - listed))
    if any(p.lower().endswith(('steam_appid.txt', '.pdb', '.log', '.save')) for p in listed):
        raise ValueError('Non-depot file found')
    versions = pe_version(content / 'MawangCastle.exe')
    if versions != ('1.3.0.0', '1.3.0.0'):
        raise ValueError('Wrong PE version: ' + str(versions))
    for name, digest in manifest['vendor_dll_sha256'].items():
        if next(r['sha256'] for r in manifest['artifacts'] if r['path'] == name) != digest:
            raise ValueError('Vendor DLL differs: ' + name)
    print('CONTENT_INTEGRITY: PASS v1.3.0 / ' + manifest['source_commit'][:12])
    print('Files: %d; PE file/product: %s; official Steam DLLs present.' % (len(actual), versions[0]))
    return manifest


if __name__ == '__main__':
    try:
        verify()
    except Exception as error:
        print('CONTENT_INTEGRITY: FAIL - ' + str(error), file=sys.stderr)
        sys.exit(1)
