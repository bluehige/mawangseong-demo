"""User-operated upload entry point. Never run during package preparation."""
import datetime
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
from VerifyContent import verify


def build_id(output):
    # Only accept SteamPipe's explicit final application-build success message.
    match = re.search(r'Successfully finished AppID\s+5267750\s+build\s*\(BuildID\s+(\d+)\)', output, re.I)
    return match.group(1) if match else None


def record(state, identity, identifier=None, exit_code=None):
    evidence = ROOT / 'Evidence'
    evidence.mkdir(exist_ok=True)
    text = ('UTC: ' + datetime.datetime.now(datetime.timezone.utc).isoformat()
        + '\nStatus: ' + state + '\nDesc: ' + identity['description']
        + '\nBuildID: ' + (identifier or 'UNCONFIRMED')
        + '\nSteamCMD exit: ' + str(exit_code)
        + '\nSetLive: EMPTY (default unchanged)\n')
    (evidence / 'upload-result.txt').write_text(text, encoding='utf-8')


def main():
    verify(ROOT)
    identity = json.loads((ROOT / 'Scripts/package_identity.json').read_text(encoding='utf-8'))
    result = ROOT / 'Evidence/upload-result.txt'
    if result.exists() and re.search(r'BuildID: [0-9]+', result.read_text(encoding='utf-8')):
        print('A completed BuildID is already recorded. Do not upload again. Open Steamworks Builds.')
        return 2
    print('App 5267750 / Depot 5267751 / ' + identity['description'])
    print('Check https://partner.steamgames.com/apps/builds/5267750 for the SAME Desc first.')
    print('If it already exists, close this window. Do not upload or Commit again.')
    if input('After checking, type UPLOAD to upload once (default remains unchanged): ').strip() != 'UPLOAD':
        return 2
    executable = Path(identity['steamcmd'])
    if not executable.is_file():
        print('SteamCMD missing. See HTTP_UPLOAD_1.3.0_KO.md. No tool was installed.')
        return 2
    vdf = ROOT / 'Scripts/app_build_5267750.vdf'
    print('Trying saved SteamCMD login once. No password input is read or recorded here.')
    command = [str(executable), '+login', 'bluehige1', '+run_app_build', str(vdf), '+quit']
    process = subprocess.Popen(command, cwd=executable.parent, stdin=subprocess.PIPE,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding='utf-8', errors='replace')
    try:
        output, _ = process.communicate(input='', timeout=3600)
    except subprocess.TimeoutExpired:
        process.kill(); process.communicate()
        record('UNCERTAIN_TIMEOUT_CHECK_BUILDS_BEFORE_RETRY', identity)
        print('Timed out. Check Builds first. No automatic retry. HTTP alternative is available.')
        return 1
    identifier = build_id(output)
    if identifier:
        record('UPLOADED', identity, identifier, process.returncode)
        print('Upload complete. BuildID: ' + identifier + '. Default unchanged.')
        return 0
    # Never log raw console output, credentials, Guard codes or cached login files.
    record('UNCONFIRMED_CHECK_BUILDS', identity, exit_code=process.returncode)
    auth_failed = bool(re.search(r'Cached credentials not found|InvalidPassword|password:|Account Logon Denied|two-factor|Steam Guard|Login Failure', output, re.I))
    build_started = bool(re.search(r'Starting AppID|Building depot|Uploading content|Successfully finished', output, re.I))
    if not auth_failed or build_started:
        print('No confirmed BuildID. Check Builds before retrying. See HTTP_UPLOAD_1.3.0_KO.md.')
        return 1
    print('\nSaved login unavailable. You may log in DIRECTLY in the official console below.')
    print('No input/output from that console will be captured by this script.')
    print('1. login bluehige1')
    print('2. Enter password and Steam Guard ONLY when SteamCMD asks.')
    print('3. After login succeeds, enter ONCE: run_app_build "' + str(vdf) + '"')
    print('4. Note the completed BuildID, then enter: quit')
    print('If login is blocked, close the console and use HTTP_UPLOAD_1.3.0_KO.md.')
    if input('Type CONSOLE to open the interactive Steam console; Enter to stop: ').strip() != 'CONSOLE':
        return 1
    code = subprocess.call([str(executable)], cwd=executable.parent)
    # Interactive console inherits real stdin/stdout; never redirect or transcript it.
    value = input('Completed BuildID shown by SteamCMD/Steamworks (Enter if unknown): ').strip()
    if not re.fullmatch(r'[1-9][0-9]*', value):
        record('INTERACTIVE_RESULT_UNCONFIRMED', identity, exit_code=code)
        print('BuildID unconfirmed. Check Steamworks before any retry.')
        return 1
    record('USER_REPORTED_BUILDID_VERIFY_IN_STEAMWORKS', identity, value, code)
    print('BuildID recorded. Verify it in Steamworks. Default unchanged.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
