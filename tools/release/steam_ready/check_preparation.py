"""Targeted local checks using synthetic set IDs and mocked SteamCMD (never execute Steam)."""
import importlib.util
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0,str(HERE))
import assemble
import Upload


def checks():
    assemble.catalog_check(ROOT)
    with tempfile.TemporaryDirectory(prefix='mawang-ready-check-') as tmp:
        out = Path(tmp)
        groups = json.loads((ROOT/'data/v130r/achievements/achievements.json').read_text(encoding='utf-8'))['sets'][1:]
        ids = {r['id']:9000001+i for i,r in enumerate(groups)}
        spec = importlib.util.spec_from_file_location('prepare',ROOT/'tools/achievements/prepare_steam_import.py')
        prepare = importlib.util.module_from_spec(spec);spec.loader.exec_module(prepare)
        assert prepare.prepare(ids,out/'5267750-achievements-definitions.csv') == 100
        assert len(assemble.read_csv(out/'5267750-achievement-sets-localization.csv')) == 7
        assert len(assemble.read_csv(out/'5267750-achievements-localization.csv')) == 200
        assert not any('REPLACE_WITH' in f.read_text(encoding='utf-8-sig') for f in out.glob('*.csv'))
        for invalid in ({},dict.fromkeys(ids,5),{**ids,groups[0]['id']:True},{**ids,groups[0]['id']:'REPLACE_WITH_ID'}):
            try: prepare.prepare(invalid,out/'invalid.csv')
            except ValueError: pass
            else: raise AssertionError('Invalid Steam set IDs accepted')
        assert not (out/'invalid.csv').exists()
        # SteamCMD, login, uploads and network are mocked in every branch below.
        (out/'Scripts').mkdir();(out/'Evidence').mkdir()
        executable = out/'mock-steamcmd-never-run.exe';executable.touch()
        identity = dict(description='v1.3.0 - SYNTHETIC',steamcmd=str(executable))
        (out/'Scripts/package_identity.json').write_text(json.dumps(identity),encoding='utf-8')
        success = 'Successfully finished AppID 5267750 build (BuildID 12345678).'
        assert Upload.build_id(success) == '12345678'
        assert Upload.build_id('old BuildID 12345678; failed') is None
        cases = [
            (success,['UPLOAD'],0,'UPLOADED',False),
            ('Cached credentials not found. Password:',['UPLOAD',''],1,'UNCONFIRMED',False),
            ('Cached credentials not found. Password:',['UPLOAD','CONSOLE','23456789'],0,'USER_REPORTED',True),
            ('Building depot; transfer failed',['UPLOAD'],1,'UNCONFIRMED',False),
            ('Cached credentials not found. Building depot',['UPLOAD'],1,'UNCONFIRMED',False),
        ]
        for output,inputs,expected,state,interactive in cases:
            result = out/'Evidence/upload-result.txt'
            if result.exists():result.unlink()
            process = MagicMock();process.communicate.return_value=(output,None);process.returncode=0
            with patch.object(Upload,'ROOT',out),patch.object(Upload,'verify'),patch('builtins.input',side_effect=inputs),\
                    patch.object(subprocess,'Popen',return_value=process) as popen,patch.object(subprocess,'call',return_value=0) as call:
                assert Upload.main() == expected
                assert call.called == interactive
                assert popen.call_count == 1
                assert popen.call_args.kwargs['stdin'] == subprocess.PIPE
            receipt = result.read_text(encoding='utf-8')
            assert state in receipt and 'Password:' not in receipt
        with patch.object(Upload,'ROOT',out),patch.object(Upload,'verify'),patch.object(subprocess,'Popen') as popen:
            result.write_text('BuildID: 12345678',encoding='utf-8')
            assert Upload.main() == 2 and not popen.called
        result.unlink()
        process = MagicMock();process.communicate.side_effect=[subprocess.TimeoutExpired('mock',1),('',None)]
        with patch.object(Upload,'ROOT',out),patch.object(Upload,'verify'),patch('builtins.input',return_value='UPLOAD'),\
                patch.object(subprocess,'Popen',return_value=process),patch.object(subprocess,'call') as call:
            assert Upload.main() == 1 and process.kill.called and not call.called
    print('PREPARATION_CHECKS: PASS (100 APIs / 20 stats / 100 icons / 7 sets; valid+invalid CSV; mocked uploader paths)')


if __name__ == '__main__':checks()
