# Курс C++

[Открыть курс](https://natimys.github.io/cpp-course/) · [Исходная Wiki](https://github.com/natimys/cpp-course/wiki)

Сайт собран на Astro и Starlight. Материалы курса находятся в `src/content/docs/`, порядок разделов — в `astro.config.mjs`. Исходные скрипты установки находятся в `scripts/`.

## Локальная разработка

Требуется Node.js 24 и npm:

```sh
npm ci
npm run dev
```

Проверить сборку и ссылки:

```sh
npm run build
python3 -m unittest discover -s tests -v
```

После изменений в ветке `main` GitHub Actions автоматически собирает и публикует сайт на GitHub Pages. Wiki остаётся отдельным архивом: дальнейшие изменения нужно вносить в `src/content/docs/`.
