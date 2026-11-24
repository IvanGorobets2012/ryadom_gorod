# AGENTS.md

Инструкции для AI-агентов и разработчиков, работающих с репозиторием «Город рядом».
**Держи этот файл в актуальном состоянии:** если меняются структура проекта, способ деплоя, ID Vercel-проекта, схема Supabase или проверки — обнови соответствующий раздел здесь в том же изменении.

## 1. Что это за проект

Одностраничный гид по Кишинёву на русском языке: подборка мест, фильтры, избранное, модальные карточки, отзывы с авторизацией и форма предложения места.

- Прод: https://gorod-ryadom-chisinau.vercel.app/
- Репозиторий: https://github.com/IvanGorobets2012/ryadom_gorod.git
- Стек: HTML5 + CSS3 + vanilla JS (ES6+), Supabase (auth, отзывы, голоса, фото), Google Maps Embed, Vercel.
- Сборки нет: сайт — это один статический `index.html` с инлайн-CSS и инлайн-JS.

## 2. Структура

```
index.html            весь сайт: разметка, стили, скрипты, данные мест, SEO-мета и JSON-LD
robots.txt            разрешает обход и указывает на sitemap.xml
sitemap.xml           карта сайта (один URL, lastmod — дата обновления контента)
supabase_schema.sql   таблицы reviews / review_votes, индексы, RLS-политики
README.md             краткое описание и стек
opencode.jsonc        локальный конфиг OpenCode с Vercel MCP (не часть сайта)
AGENTS.md             этот файл
```

## 3. Локальная работа

Node.js/npm в этом окружении не установлены, сборка и dev-сервер не нужны.

- Открыть сайт: двойной клик по `index.html` или `tools.browser.tabs.open({ path: "index.html" })`.
- Проверить синтаксис/поведение: открыть страницу во встроенном браузере OpenCode и смотреть консоль/сеть.
- Внешний `browse.exe` установлен в `%USERPROFILE%\.local\bin`, но **заблокирован Smart App Control** (неподписанный бинарник). Для работы используй встроенный браузер OpenCode, а не `browse`.

### Правила редактирования

- Сохраняй архитектуру одного файла, если пользователь явно не попросил разбить её на модули.
- Данные мест лежат прямо в HTML: `<article class="card" data-kind data-district data-rating data-name>`. Новое место = новая карточка + запись в объекте `details` (заголовок `h3` — ключ) во втором `<script>`.
- `data-name` — строка в нижнем регистре для поиска; `data-kind` — `coffee | walk | culture | hidden`; `data-district` — `center | rascani | chekany | botanica | buiucani | telecentru`.
- Динамический HTML экранируй (`escapeHtml` / `esc`), чтобы не ломать разметку и не создавать XSS.
- Внешние фото — хотлинки. Перед добавлением проверяй URL: Wikimedia-превью часто дают 404. **Не используй `https://commons.wikimedia.org/wiki/Special:FilePath/...`** — такие редиректы ломаются на именах с пробелами/скобками (уже было с `Dendrarium Chisinau (14).jpg` и `Triumphal Arch - Moldova (by David Stanley).jpg`). Правильный путь: запросить у Commons API канонический `thumburl` и вставить его напрямую:

  ```
  https://commons.wikimedia.org/w/api.php?action=query&titles=File:<имя>&prop=imageinfo&iiprop=url|mime|extmetadata&iiurlwidth=1280&format=json
  ```

  Полученный `thumb.wikimedia.org/...` или `upload.wikimedia.org/...` проверь запросом (должен быть `200` и `content-type: image/*`). Указывай источник и лицензию в `.photocredit`.
- Проверять картинки лучше пачкой в браузере (`new Image()` по всем `background-image` и `img[src]`), а не по одной: одиночные частые запросы к Wikimedia дают `429`, это не ошибка — повтори позже.
- Даты и рейтинги в карточках статические; при обновлении контента меняй и подпись «обновлено …» в секции `#places`.

## 4. Supabase

- Проект: `https://ypnjuaqrjharewvtfkrg.supabase.co`
- Publishable-ключ лежит в `index.html` — это нормально для Supabase; доступ ограничивается RLS.
- Схема: `supabase_schema.sql` (`reviews`, `review_votes`, индексы, RLS).
- Storage bucket: `review-photos`, публичный, создаётся вручную в Dashboard.
- Админ UUID `abcd0d01-0308-49f9-a475-e5d8c1a9feb7` захардкожен в `index.html` и в SQL-политике. При смене админа правь оба места.
- Отзыв: один на пользователя на место; фото JPG/PNG/WebP до 5 МБ; удаление доступно автору и админу.
- Форма «Предложить место» пока пишет только в `localStorage` (`gorod-ryadom:suggestions`) и никуда не отправляется.

## 5. Git

- Основная ветка: `main`, remote `origin` = `https://github.com/IvanGorobets2012/ryadom_gorod.git`.
- Репозиторий **публичный**, все коммиты запушены (первый push был 24.11.2026). `git ls-remote origin` должен возвращать `refs/heads/main`. Раз публичный — **никаких секретов в коде и коммитах**: ни `service_role`, ни токенов, ни паролей. Publishable-ключ Supabase и админ-UUID секретами не являются.
- Авторизация push: Git Credential Manager, токен лежит в Windows Credential Manager (`LegacyGeneric:target=git:https://github.com`). Проверить: `cmdkey /list | Select-String github`.
- Вход через браузер в GCM у этого аккаунта **не работает**: GitHub → «Continue with Google» → Google отклоняет вход. Используй fine-grained PAT (`Contents: Read and write`, только репозиторий `ryadom_gorod`) и вставляй его в окно GCM или через `git credential approve`.
- Если вставка в PowerShell не работает (старый `conhost`), забирай токен из буфера: `$p = (Get-Clipboard).Trim()` и передавай в `git credential approve`.
- Vercel-проект **не подключён к Git**: `git push` не запускает деплой. Не обещай деплой через push, пока интеграция не настроена — деплой только через Vercel MCP (раздел 6).
- `opencode.jsonc` закоммичен (секретов в нём нет — только URL MCP). Если добавляешь туда токены или env — сначала убери файл из индекса (`git rm --cached`) и внеси в `.gitignore`.

## 6. Деплой на Vercel

### Идентификаторы

| Параметр | Значение |
|---|---|
| Team ID | `team_FX1837kVIi5wa1Eya1rK9Nry` |
| Project ID | `prj_oIoRfi2fIkem2usvYOOILMfP2tor` |
| Project name | `gorod-ryadom-chisinau` |
| Production domains | `gorod-ryadom-chisinau.vercel.app`, `gorod-ryadom-chisinau-ivangorobets2012-8596.vercel.app` |
| Framework | `null` (статика) |

### Способ деплоя

Vercel CLI, Node.js и npm недоступны, Git-интеграции нет. Рабочий способ — **Vercel MCP** (`tools.vercel.*`), настроен в `opencode.jsonc`.

Ключевой нюанс: `create_deployment` с inline-файлами `{ file, data, encoding }` падает на валидации union («Expected exactly one member to match»). Поэтому файл сначала загружается через `upload_file`, а деплой ссылается на него по SHA1 и размеру.

Порядок:

1. Посчитать SHA1 и размер всех деплоящихся файлов (`index.html`, `robots.txt`, `sitemap.xml`):

   ```powershell
   foreach ($f in @('index.html','robots.txt','sitemap.xml')) {
     $i = Get-Item $f
     "$f sha1=" + (Get-FileHash $f -Algorithm SHA1).Hash.ToLower() + " size=" + $i.Length
   }
   ```

2. В Code Mode прочитать файлы. Прямого доступа к ФС в `execute` нет, поэтому поднять одноразовый loopback-сервер и забрать их через `fetch`. Готовый скрипт: `%TEMP%\opencode\serve-files.ps1` (TcpListener на `127.0.0.1:18791`, отдаёт три файла по запрошенному пути и завершается). Запуск:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\opencode\serve-files.ps1"
   ```

3. В `execute`:

   ```js
   // для каждого из трёх файлов:
   const text = await (await fetch("http://127.0.0.1:18791/index.html")).text();
   // UTF-8 → байты → base64 (TextEncoder/crypto в runtime недоступны — кодируй вручную)
   await tools.vercel.upload_file({
     teamId: "team_FX1837kVIi5wa1Eya1rK9Nry",
     contentLength: <bytes>,
     xVercelDigest: "<sha1>",
     requestBody: "<base64>"
   });
   await tools.vercel.create_deployment({
     teamId: "team_FX1837kVIi5wa1Eya1rK9Nry",
     requestBody: {
       name: "gorod-ryadom-chisinau",
       project: "prj_oIoRfi2fIkem2usvYOOILMfP2tor",
       target: "production",
       files: [
         { file: "index.html", sha: "<sha1>", size: <bytes> },
         { file: "robots.txt", sha: "<sha1>", size: <bytes> },
         { file: "sitemap.xml", sha: "<sha1>", size: <bytes> }
       ]
     }
   });
   ```

4. Дождаться `readyState: "READY"` через `get_deployment` (не чаще раза в ~4 с), затем проверить прод.

5. Проверить, что алиас обновился: `fetch("https://gorod-ryadom-chisinau.vercel.app/?v=<timestamp>")` должен содержать актуальную разметку.

### Чек-лист после деплоя

- [ ] `get_deployment` → `readyState: READY`, `alias` содержит production-домен.
- [ ] На проде 22 карточки: `(html.match(/<article class="card"/g) || []).length === 22`.
- [ ] 7 кнопок районов (включая Рышкановку), есть `#suggestBtn`.
- [ ] В браузере после `reload({ ignoreCache: true })`: 0 ошибок в консоли, 0 запросов со статусом ≥ 400, 0 битых `img`.
- [ ] Выборочно открыть модалку места, фильтры и поиск.
- [ ] `<title>` содержит «Куда сходить в Кишинёве», есть `description`, `canonical`, `og:*`.
- [ ] JSON-LD валиден: `"@type":"ListItem"` ровно 22 штуки (см. раздел 8).
- [ ] `https://gorod-ryadom-chisinau.vercel.app/robots.txt` и `/sitemap.xml` отдают `200`.

## 7. Известные особенности и подводные камни

- Прод может отставать от локального файла: деплой ручной, Git-интеграции нет. Всегда сверяй число карточек на проде с локальным `index.html`.
- Избранное и отзывы привязаны к названию места (`h3`). Переименование места ломает сохранённое избранное и старые отзывы.
- Фото — внешние URL; проверяй доступность перед деплоем (429 у Wikimedia бывает временным, 404 — реальная ошибка).
- `opencode.jsonc` и `AGENTS.md` не входят в деплой; деплоятся `index.html`, `robots.txt`, `sitemap.xml`.
- Smart App Control блокирует неподписанные exe. Не пытайся обойти политику; используй встроенный браузер.

## 8. SEO

Цель: сайт должен находиться по запросам «куда сходить в Кишинёве», «что посмотреть в Кишинёве», «кофейни Кишинёва», «парки Кишинёва».

- **`<title>`** — главный ключ впереди, бренд в конце: `Куда сходить в Кишинёве — 22 проверенных места | Город рядом`. Не возвращать «гид по Кишинёву»: такой запрос никто не вводит.
- **`description`** — 150–160 символов, с ключом и конкретикой (адреса, часы, отзывы).
- **H1** остаётся имиджевым («Кишинёв, который рядом»), ключ живёт в `lead`-абзаце и в `<h2>Куда сходить в Кишинёве</h2>` перед сеткой карточек.
- **Canonical** — всегда `https://gorod-ryadom-chisinau.vercel.app/`.
- **Open Graph / Twitter** — `og:image` берётся с Unsplash (фото из hero), ширина 1200. Это то, что показывается при пересылке ссылки в Telegram/WhatsApp.
- **JSON-LD** — `WebSite` + `CollectionPage` + `ItemList` на 22 места. При добавлении/удалении/переименовании места обязательно правь `numberOfItems` и `itemListElement`, иначе разметка разойдётся с содержимым (риск ручных санкций).
- **`robots.txt` / `sitemap.xml`** — статика в корне. При обновлении контента меняй `<lastmod>` в `sitemap.xml`.
- После деплоя: проверять `https://gorod-ryadom-chisinau.vercel.app/robots.txt` и `/sitemap.xml` (200), а также что title на проде совпадает с локальным.
- **Контентные блоки** — главный текст для поиска: `#districts-guide` (6 районов), `#faq` (7 вопросов), `#about`. Если меняется состав мест в районе — правь и текст соответствующей карточки района, иначе он начнёт врать.
- **FAQ дублируется дважды**: видимый текст в `<details>` и `FAQPage` JSON-LD должны совпадать дословно — Google сверяет разметку с содержимым страницы.
- **Кнопки районов** (`data-goto-district`) не фильтруют сами: они сбрасывают фильтры, кликают существующую кнопку `.district` и скроллят к `#places`. Логика — в маленьком скрипте перед `</body>`.
- Индексацию ускоряет Google Search Console: добавить домен, отправить `sitemap.xml`. Это разовое действие пользователя, агентом не автоматизируется.

## 9. Актуализация этого файла

Обновляй `AGENTS.md`, когда:

- меняется способ деплоя или появляется Git-интеграция / Vercel CLI;
- меняются Team ID, Project ID, домены, framework;
- меняется схема Supabase, имя bucket, админ UUID;
- добавляются/удаляются файлы, появляется сборка или тесты;
- меняются обязательные проверки после деплоя.

Если сомневаешься в факте (например, подключён ли Git), проверь (`git ls-remote`, `get_project`, `list_deployments`) и запиши результат, а не предположение.
