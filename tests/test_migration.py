import html
import os
import re
import unittest
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
WIKI = Path(os.environ['WIKI_DIR']) if os.environ.get('WIKI_DIR') else None
PAGES = {
    'Home': ('index', 'привяо'),
    'Установка': ('installation', 'Что устанавливаем'),
    'Переменные-и-типы-данных': ('variables', 'Переменные и типы данных'),
    'Ввод-и-вывод': ('input-output', 'Ввод и вывод'),
    'Арифметические-операции': ('arithmetic', 'Арифметические операции'),
    'Условия': ('conditions', 'Условия'),
}

class MigrationTest(unittest.TestCase):
    @unittest.skipUnless(WIKI, 'Set WIKI_DIR to verify the original migration')
    def test_all_wiki_content_migrated(self):
        self.assertEqual({p.stem for p in WIKI.glob('*.md')} - {'_Sidebar'}, set(PAGES))
        for original, (slug, title) in PAGES.items():
            with self.subTest(original=original):
                source = (WIKI / (original + '.md')).read_text()
                target = (ROOT / 'src/content/docs' / (slug + '.md')).read_text()
                self.assertTrue(source.startswith('# ' + title + '\n'))
                body = target.split('---\n', 2)[2]
                expected = source.split('\n', 1)[1]
                for name, (dest, _) in PAGES.items():
                    expected = expected.replace('https://github.com/natimys/cpp-course/wiki/' + name, '/cpp-course/' + ('' if dest == 'index' else dest + '/'))
                self.assertEqual(body.rstrip(), expected.rstrip())

    def test_built_pages_and_internal_links(self):
        dist = ROOT / 'dist'
        for slug, title in PAGES.values():
            page = dist / ('index.html' if slug == 'index' else slug + '/index.html')
            with self.subTest(slug=slug):
                text = page.read_text()
                self.assertIn(title, html.unescape(text))
                for url in re.findall(r'href=["\']([^"\']+)', text):
                    if url.startswith('/cpp-course/') and not url.startswith('/cpp-course/_astro/') and not url.startswith('/cpp-course/pagefind/') and not url.endswith('.xml'):
                        path = unquote(url.split('#', 1)[0].split('?', 1)[0]).removeprefix('/cpp-course/').strip('/')
                        self.assertTrue((dist / path / 'index.html').is_file() or (dist / path).is_file(), f'{page}: {url}')

if __name__ == '__main__':
    unittest.main()
