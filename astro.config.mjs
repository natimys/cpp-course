import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://natimys.github.io',
  base: '/cpp-course',
  integrations: [starlight({
    title: 'Курс C++',
    defaultLocale: 'ru',
    locales: { root: { label: 'Русский', lang: 'ru' } },
    sidebar: [
      { label: 'Начало', items: [
        { label: 'Начало', slug: 'index' },
        { label: 'Установка', slug: 'installation' },
      ] },
      { label: 'Основы. Часть 1', items: [
        { label: 'Переменные и типы данных', slug: 'variables' },
        { label: 'Ввод и вывод', slug: 'input-output' },
        { label: 'Арифметические операции', slug: 'arithmetic' },
        { label: 'Условия', slug: 'conditions' },
      ] },
    ],
  })],
});
