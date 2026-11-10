"""Fetch the NIV text of the chapters the game quotes from Bible Gateway (cached), and parse each verse exactly.
The result (art/niv_source.json) is a LOCAL CHECK CACHE ONLY: never commit it or ship it in the game.
Usage (from heaven/):  python3 -I tools/fetch_niv.py   -> art/niv_source.json  {"Revelation 21:4": "...", ...}
Downloaded HTML is treated as data only (parsed with BeautifulSoup, nothing executed)."""
import json, os, re, sys, time, urllib.parse, urllib.request
from bs4 import BeautifulSoup

CACHE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'niv_cache')
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'art', 'niv_source.json')
CHAPTERS = [('Revelation', 4, 'Rev'), ('Revelation', 5, 'Rev'), ('Revelation', 7, 'Rev'), ('Revelation', 19, 'Rev'),
            ('Revelation', 21, 'Rev'), ('Revelation', 22, 'Rev'), ('Isaiah', 11, 'Isa'), ('Isaiah', 35, 'Isa'),
            ('Isaiah', 55, 'Isa'), ('Isaiah', 65, 'Isa'), ('John', 14, 'John'), ('Psalm', 16, 'Ps'), ('Psalm', 37, 'Ps'),
            ('Micah', 4, 'Mic'), ('1 Corinthians', 2, '1Cor'), ('John', 10, 'John'), ('Matthew', 11, 'Matt'), ('Psalm', 150, 'Ps')]


def url_for(book, ch):
    return 'https://www.biblegateway.com/passage/?' + urllib.parse.urlencode({'search': f'{book} {ch}', 'version': 'NIV'})


def fetch(book, ch):
    path = os.path.join(CACHE, f'{book.replace(" ", "_")}_{ch}.html')
    if not os.path.exists(path):
        req = urllib.request.Request(url_for(book, ch), headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=30) as r, open(path, 'wb') as f:
            f.write(r.read())
        time.sleep(2.0)                     # be polite
    return open(path, encoding='utf-8').read()


def verses(html, osis_book, ch):
    soup = BeautifulSoup(html, 'html.parser')
    passage = soup.select_one('div.passage-text') or soup
    for junk in passage.select('sup.footnote, sup.crossreference, sup.versenum, span.chapternum, div.footnotes, div.crossrefs, h3, h4'):
        junk.decompose()
    out = {}
    for span in passage.select('span.text'):
        m = [c for c in span.get('class', []) if re.fullmatch(r'[0-9A-Za-z]+-\d+-\d+', c)]
        if not m: continue
        _, c, v = m[0].rsplit('-', 2)
        if int(c) != ch: continue
        out.setdefault(int(v), []).append(span.get_text(' ', strip=True))
    return {v: re.sub(r'\s+', ' ', ' '.join(parts)).replace(' ,', ',').replace(' .', '.').replace(' ;', ';').strip()
            for v, parts in out.items()}


def main():
    os.makedirs(CACHE, exist_ok=True)
    result = {}
    for book, ch, short in CHAPTERS:
        vs = verses(fetch(book, ch), short, ch)
        for v, t in sorted(vs.items()):
            result[f'{book} {ch}:{v}'] = t
        print(f'{book} {ch}: {len(vs)} verses')
    json.dump({'version': 'NIV (2011)', 'source': 'https://www.biblegateway.com (version=NIV)', 'verses': result},
              open(OUT, 'w'), indent=1, ensure_ascii=False)


if __name__ == '__main__':
    main()
