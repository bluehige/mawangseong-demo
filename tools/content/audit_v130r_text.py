"""Read-only mechanical proofreading inventory; candidates require human review.

Run with Python UTF-8 mode. Writes evidence only to tmp/text_proof.
Never starts Godot, reads saves, or treats valid runtime tokens as prose errors.
"""
import collections
import csv
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'tmp/text_proof'
LANGS = {'en': 'en', 'zh_cn': 'zh_CN', 'zh_CN': 'zh_CN', 'ko': 'ko'}
TOKEN = re.compile(r'\{\{[A-Za-z_]+\}\}|%(?:[-+0#]*\d*(?:\.\d+)?[sdf]|%)')
META = {'schema_version', 'locale', 'status', 'scope', 'source_version',
        'name_table_ref', 'kind', 'trigger', 'repeat_policy', 'speaker_id',
        'id', 'portrait_emotion', 'emotion', 'emotion_direction',
        'missing_participant_policy'}


def load(path):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f'{path}: duplicate key {key}')
            result[key] = value
        return result
    return json.loads(path.read_text(encoding='utf-8-sig'), object_pairs_hook=unique)


def main():
    rows, candidates, errors = [], [], []
    missing, token_checks, unused_peer_keys = [], 0, []

    def check_tokens(source, target, location):
        nonlocal token_checks
        token_checks += 1
        if collections.Counter(TOKEN.findall(source)) != collections.Counter(TOKEN.findall(target)):
            errors.append(f'{location}: token mismatch')

    def add(file, key, language, text):
        if language in ('en', 'zh_CN') and text.strip():
            rows.append(dict(file=file, key=key, locale=language, text=text))

    def walk(value, file, pointer='', language=''):
        if isinstance(value, dict):
            for key, child in value.items():
                lang = LANGS.get(key, language)
                for suffix in ('_en', '_zh_cn', '_ko'):
                    if key.endswith(suffix):
                        lang = LANGS[suffix[1:]]
                location = pointer + '/' + key.replace('~', '~0').replace('/', '~1')
                if isinstance(child, str):
                    if key not in META and not key.endswith(('_id', '_path', '_ref')):
                        add(file, location, lang, child)
                elif key not in ('conditions', 'side_effects') and not key.endswith(('_ids', '_paths')):
                    walk(child, file, location, lang)
        elif isinstance(value, list):
            for index, child in enumerate(value):
                walk(child, file, pointer + '/' + str(index), language)
        elif isinstance(value, str):
            add(file, pointer, language, value)

    for path in sorted((ROOT / 'data').rglob('*.json')):
        value = load(path)
        file = path.relative_to(ROOT).as_posix()
        language = 'zh_CN' if path.stem.endswith('_zh_cn') else 'en' if path.stem.endswith('_en') else ''
        walk(value, file, language=language)
        if isinstance(value, dict) and isinstance(value.get('locales'), dict) and 'ko' in value['locales']:
            locales = value['locales']
            for lang in ('en', 'zh_CN'):
                for key, source in locales['ko'].items():
                    target = locales.get(lang, {}).get(key, '')
                    if not target.strip():
                        missing.append(f'{file}:{lang}:{key}')
                    else:
                        check_tokens(source, target, f'{file}:{lang}:{key}')
        if language and isinstance(value, dict):
            for group in ('messages', 'supplemental_messages'):
                for source, target in value.get(group, {}).items():
                    check_tokens(source, target, f'{file}:{group}:{source}')

    # The shipped EN/ZH paired catalogs must cover the same key sets.
    for path in sorted((ROOT / 'data').rglob('*_en.json')):
        peer = path.with_name(path.name.replace('_en.json', '_zh_cn.json'))
        if not peer.exists():
            continue
        en, zh = load(path), load(peer)
        for group in ('messages', 'cues', 'scene_titles', 'speaker_labels'):
            a, b = en.get(group, {}), zh.get(group, {})
            if group == 'messages':
                a = dict(a, **en.get('supplemental_messages', {}))
                b = dict(b, **zh.get('supplemental_messages', {}))
                # English-only presentation literals use the engine's identity
                # fallback; they need no English translation entry.
                b = {k: v for k, v in b.items() if k in a or re.search('[가-힣]', k)}
            missing.extend(f'{peer}:{group}:{key}' for key in set(a) - set(b))
            extras = set(b) - set(a)
            # A removed inter-floor skill description remains in the historical
            # ZH catalog. Only current source references require translations.
            for key in extras:
                referenced = any(key in p.read_text(encoding='utf-8-sig')
                                 for folder in ('scripts', 'scenes', 'data/regular_version', 'data/v130r')
                                 for p in (ROOT / folder).rglob('*')
                                 if p.suffix in ('.gd', '.tscn', '.json') and 'localization' not in p.name)
                (missing if referenced else unused_peer_keys).append(f'{path}:{group}:{key}')

    # Validate all main-story IDs against Korean source, including player tokens.
    story_sources = {}
    def cues(value):
        if isinstance(value, dict):
            if 'id' in value and 'text_ko' in value:
                story_sources[value['id']] = value['text_ko']
            for child in value.values():
                cues(child)
        elif isinstance(value, list):
            for child in value:
                cues(child)
    for path in (ROOT / 'data/story/v122_main').glob('*.json'):
        cues(load(path))
    for lang, suffix in (('en', 'en'), ('zh_CN', 'zh_cn')):
        translated = load(ROOT / f'data/localization/story_{suffix}.json')['cues']
        for key, source in story_sources.items():
            if not translated.get(key, '').strip():
                missing.append(f'{lang}:story:{key}')
            else:
                check_tokens(source, translated[key], f'{lang}:story:{key}')

    literal = r'"(?:[^"\\]|\\.)*"'
    inline = re.compile(r'\b(?:localized|loc)\(\s*(' + literal + r')\s*,\s*(' + literal + r')\s*,\s*(' + literal + r')\s*\)', re.S)
    for folder in ('scripts', 'scenes'):
        for path in (ROOT / folder).rglob('*.gd'):
            source = path.read_text(encoding='utf-8-sig')
            for match in inline.finditer(source):
                strings = [json.loads(s) for s in match.groups()]
                key = 'line:' + str(source.count('\n', 0, match.start()) + 1)
                for lang, text in zip(('en', 'zh_CN'), strings[1:]):
                    add(path.relative_to(ROOT).as_posix(), key, lang, text)
                    check_tokens(strings[0], text, f'{path}:{key}:{lang}')

    path = ROOT / 'data/v130r/achievements/5267750-achievements-localization.csv'
    with path.open(encoding='utf-8-sig', newline='') as stream:
        for entry in csv.DictReader(stream):
            for lang, column in (('en', 'english'), ('zh_CN', 'schinese')):
                add(path.relative_to(ROOT).as_posix(), entry['api_name'] + ':' + entry['field'], lang, entry[column])
                if not entry[column].strip():
                    missing.append(f'achievement:{lang}:{entry["api_name"]}:{entry["field"]}')
                check_tokens(entry['koreana'], entry[column], f'achievement:{lang}:{entry["api_name"]}')

    for row in rows:
        text = row['text']
        reasons = []
        if re.search('[가-힣ㄱ-ㅎㅏ-ㅣ]', text):
            errors.append(f'{row["file"]}:{row["key"]}: residual Korean')
        if '\ufffd' in text or re.search(r'\{\{|\}\}', TOKEN.sub('', text)):
            errors.append(f'{row["file"]}:{row["key"]}: broken token')
        if re.search(r'\b(\w+)\s+\1\b', text, re.I):
            reasons.append('repeated_word')
        if '  ' in text:
            reasons.append('spacing_review')
        prose = re.sub(r'^\[[^\]]+\]:\s*', '', text)
        if row['locale'] == 'en':
            if re.search(r'\ban\s+[b-df-hj-np-tv-z]\w*|\ba\s+[aeiou]\w*', prose, re.I):
                reasons.append('article_review')
            if re.match('[a-z]', prose):
                reasons.append('capitalization_review')
            if len(prose) > 45 and re.search('[a-zA-Z]$', prose):
                reasons.append('sentence_end_review')
            if re.search(r'\b(?:1 (?:tiles|seconds|monsters)|(?:they|we|you) (?:is|has))\b', prose, re.I):
                reasons.append('agreement_review')
        else:
            if re.search('[A-Za-z]{2,}', TOKEN.sub('', prose)):
                reasons.append('latin_review')
            if re.search('[,!?;:]', prose):
                reasons.append('punctuation_review')
        if reasons:
            candidates.append(dict(row, reasons=reasons))

    registry = load(ROOT / 'data/v130r/story/speaker_registry.json')
    names = [dict(category='monster', id=key, **labels)
             for key, labels in registry['species_names'].items()]
    tables = {}
    for suffix in ('en', 'zh_cn'):
        base = load(ROOT / f'data/localization/ui_{suffix}.json')
        table = dict(base['messages'], **base.get('supplemental_messages', {}))
        table.update(load(ROOT / f'data/localization/story_{suffix}.json')['speaker_labels'])
        table.update(load(ROOT / f'data/v130r/localization_{suffix}.json')['messages'])
        tables[suffix] = table
    known = {row['ko'] for row in names}
    for category, sources in (
        ('character', ('data/characters.json', 'data/regular_version/update4/characters.json')),
        ('building', ('data/rooms.json', 'data/regular_version/update4/expansion_modules.json')),
    ):
        for source in sources:
            for key, value in load(ROOT / source).items():
                ko = value['display_name']
                if ko in known or ko.startswith('레거시'):
                    continue
                known.add(ko)
                names.append(dict(category=category, id=key, ko=ko,
                                  **{lang: table.get(ko, '(no exact standalone entry)')
                                     for lang, table in tables.items()}))
    for row in names:
        if row['category'] == 'monster':
            for lang, table in tables.items():
                if table.get(row['ko']) != row[lang]:
                    errors.append(f'{lang}:{row["id"]}: canonical name drift')
    report = dict(result='FAIL' if errors or missing else 'PASS',
                  fields=len(rows), files=len({r['file'] for r in rows}),
                  main_story_cues=len(story_sources), token_checks=token_checks,
                  missing_keys=len(missing), errors=errors, missing=missing,
                  unused_peer_keys=unused_peer_keys,
                  name_rows=len(names), canonical_monster_names=24,
                  candidate_counts=dict(collections.Counter(reason for r in candidates for reason in r['reasons'])))
    OUT.mkdir(parents=True, exist_ok=True)
    for name, value in (('inventory', rows), ('candidates', candidates), ('names', names), ('report', report)):
        (OUT / f'{name}.json').write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return bool(errors or missing)


if __name__ == '__main__':
    raise SystemExit(main())
