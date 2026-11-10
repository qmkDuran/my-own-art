"""Verifies every fragment in game/data/verses.json is an exact substring of the NIV text of its cited verses
(art/niv_source.json from tools/fetch_niv.py), and records how many distinct verses the game quotes.
Usage (from heaven/arpg/): python3 -I tools/check_verses.py"""
import json, os, sys

TOKENS = ('...', '\n')


SOURCE = 'art/niv_source.json'   # local cache from tools/fetch_niv.py (not in the repo, never shipped)


def main():
    if not os.path.exists(SOURCE):
        print(f'{SOURCE} not found: run  python3 -I tools/fetch_niv.py  first (it caches the NIV chapters locally). Nothing checked.')
        sys.exit(0)
    src = json.load(open(SOURCE))['verses']
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
