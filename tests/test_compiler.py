import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class BrowserCompilerTest(unittest.TestCase):
    def test_compiler_is_available_from_course_landing_page(self):
        page = ROOT / 'src/content/docs/compiler.mdx'
        self.assertTrue(page.is_file())
        self.assertIn('title: "Компилятор C++"', page.read_text())

    def test_course_layout_includes_interactive_compiler(self):
        config = (ROOT / 'astro.config.mjs').read_text()
        self.assertIn("'./src/components/CompilerLayout.astro'", config)
        layout = ROOT / 'src/components/CompilerLayout.astro'
        self.assertTrue(layout.is_file())
        self.assertIn('Compiler.astro', layout.read_text())

    def test_worker_and_wasi_host_are_served_from_site_base_path(self):
        worker = ROOT / 'public/cpp-compiler/clang-worker.mjs'
        wasi = ROOT / 'public/cpp-compiler/wasi-host.mjs'
        self.assertTrue(worker.is_file())
        self.assertTrue(wasi.is_file())
        self.assertIn("./wasi-host.mjs", worker.read_text())

    def test_compiler_is_in_the_course_sidebar(self):
        config = (ROOT / 'astro.config.mjs').read_text()
        self.assertIn("{ label: 'Компилятор C++', slug: 'compiler' }", config)

    def test_built_compiler_page_and_static_worker_exist(self):
        page = ROOT / 'dist/compiler/index.html'
        worker = ROOT / 'dist/cpp-compiler/clang-worker.mjs'
        self.assertTrue(page.is_file())
        self.assertTrue(worker.is_file())
        text = page.read_text()
        self.assertIn('Код программы', text)
        self.assertIn('Скомпилировать и запустить', text)
        self.assertIn('new Worker(`/cpp-course/cpp-compiler/clang-worker.mjs`', text)

    def test_landing_page_contains_the_interactive_compiler(self):
        page = ROOT / 'dist/index.html'
        self.assertTrue(page.is_file())
        text = page.read_text()
        self.assertIn('Попробуй сам: компилятор в браузере', text)
        self.assertIn('cpp-compiler/clang-worker.mjs', text)


if __name__ == '__main__':
    unittest.main()
