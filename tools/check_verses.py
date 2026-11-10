"""Verifies every fragment in game/data/verses.json is an exact substring of the NIV text of its cited verses
(art/niv_source.json from tools/fetch_niv.py), and records how many distinct verses the game quotes.
Usage (from heaven/): python3 -I tools/check_verses.py"""
import json, sys

TOKENS = ('...', '\n')


def main():
    src = json.load(open('art/niv_source.json'))['verses']
    data = json.load(open('game/data/verses.json'))
    bad, used = [], set()
    for key, e in data['verses'].items():
        for vid in e['verses']:
            if vid not in src: bad.append(f'{key}: unknown verse {vid}')
            used.add(vid)
        whole = ' '.join(src.get(v, '') for v in e['verses'])
        for p in e['parts']:
            if p in TOKENS: continue
            if p not in whole: bad.append(f'{key}: NOT EXACT: {p!r}')
    data['verse_count'] = len(used)
    json.dump(data, open('game/data/verses.json', 'w'), indent=1, ensure_ascii=False)
    for b in bad: print(b)
    print(f'{len(data["verses"])} entries, {len(used)} distinct verses, {len(bad)} problems')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
