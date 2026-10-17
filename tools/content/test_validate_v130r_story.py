"""Negative contract tests using temporary story copies only; no engine or saves."""
import json
import shutil
import tempfile
import unittest
from pathlib import Path

from validate_v130r_story import ROOT, load, validate


class StoryContractTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='v130r_story_contract_')
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        for path in (ROOT / 'data/v130r/story').glob('*.json'):
            shutil.copyfile(path, self.folder / path.name)

    def mutate(self, name, change):
        path = self.folder / name
        doc = load(path)
        change(doc)
        path.write_text(json.dumps(doc, ensure_ascii=False), encoding='utf-8')

    def rejected(self, expected):
        result = validate(ROOT, self.folder)
        self.assertEqual(result['result'], 'FAIL')
        self.assertTrue(any(expected in e for e in result['errors']), result['errors'][:10])

    def test_unknown_speaker_rejected(self):
        self.mutate('barks.json', lambda d: d['scenes'][0]['cues'][0].update(speaker_id='CHR_NOT_REAL'))
        self.rejected('unknown speaker')

    def test_unmapped_emotion_rejected(self):
        self.mutate('barks.json', lambda d: d['scenes'][0]['cues'][0].update(emotion_direction='unmapped'))
        self.rejected('emotion mapping mismatch')

    def test_day29_battle_rejected(self):
        self.mutate('day_overlays.json', lambda d: d['scenes'][28].update(trigger='precombat_confirmed'))
        self.rejected('DAY 29 must have no battle')

    def test_before_join_day_rejected(self):
        self.mutate('day_overlays.json', lambda d: d['scenes'][5].update(day=5))
        self.rejected('river_frog appears before fallback join day')

    def test_missing_memory_stage_rejected(self):
        def change(d):
            d['scenes'] = [s for s in d['scenes'] if not
                           (s['monster_id'] == 'hollow_armor' and s['memory_stage'] == 3)]
        self.mutate('bond_scenes.json', change)
        self.rejected('hollow_armor: incomplete memory stages')

    def test_changed_memory_quote_rejected(self):
        self.mutate('bond_scenes.json', lambda d: d['scenes'][0]['cues'][1].update(text='Changed memory'))
        self.rejected('memory quote drift')

    def test_missing_translation_rejected(self):
        def change(d):
            d['documents']['join_scenes.json']['scenes'][0]['cues'][0]['text'] = ''
        self.mutate('localization_story_en.json', change)
        self.rejected('missing translation')

    def test_localized_name_drift_rejected(self):
        def change(d):
            d['documents']['barks.json']['scenes'][0]['cues'][0]['speaker_label'] = 'Wrong Name'
        self.mutate('localization_story_zh_cn.json', change)
        self.rejected('localized name drift')

    def test_changed_duo_unlock_rejected(self):
        def change(d):
            d['scenes'][0]['conditions']['original_unlock_condition']['bond_each'] = 1
        self.mutate('duo_scenes.json', change)
        self.rejected('original unlock drift')

    def test_changed_new_duo_unlock_rejected(self):
        def change(d):
            d['scenes'][6]['conditions']['original_unlock_condition']['bond_each'] = 44
        self.mutate('duo_scenes.json', change)
        self.rejected('new unlock drift')

    def test_missing_roster_gate_rejected(self):
        def change(d):
            d['scenes'][0]['segments'][0]['conditions']['requires_owned_species_ids'] = []
        self.mutate('day_overlays.json', change)
        self.rejected('monster speaker lacks ownership gate')

    def test_duplicate_json_key_rejected(self):
        path = self.folder / 'duplicate.json'
        path.write_text('{"scene":1,"scene":2}', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'duplicate JSON key'):
            load(path)

    def test_protected_hash_drift_rejected_without_touching_source(self):
        def change(d):
            path = next(iter(d['protected_sha256']))
            d['protected_sha256'][path] = '0' * 64
        self.mutate('manifest.json', change)
        self.rejected('protected/source file drift')


if __name__ == '__main__':
    unittest.main()
