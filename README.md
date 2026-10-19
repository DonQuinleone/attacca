<p><img src="assets/attacca/attacca-mark.svg" width="56" height="56" alt=""></p>

# attacca

Smart-link pages for classical releases, built as static files and served from GitHub Pages.

Each release gets one short address that lands on a page with the cover, the title, the composers, the performers with their roles, an optional description, and a row for every place to listen or buy. Classical credits are first-class: composers and performers are separate fields, not one artist string.

attacca is a Jekyll theme with a small plugin. You keep one Markdown file per release in your own repository, and a GitHub Actions workflow builds and publishes the site.

## What you get

- A page per release at `/<slug>/`, reachable in any casing (`/DavidsAir/` and `/davidsair/` both work).
- Official store icons in colour or mono, with light and dark themes that follow the visitor's system setting.
- Custom links (a label shop, a concert page) defined once in config and used from any release.
- Optional extras per release, such as a video or a programme booklet.
- Covers resized for the page and a 1200 x 630 image for social link previews.
- No index of releases, no sitemap and `noindex` on every page, so the site is not listed in search engines. Social previews still work.
- A build that fails with a clear message when a release file is wrong.

## Quick start

1. Create a repository for your site and add this `Gemfile`:

   ```ruby
   source "https://rubygems.org"

   gem "attacca", git: "https://github.com/DonQuinleone/attacca", tag: "v0.1.0"
   ```

2. Add `_config.yml`:

   ```yaml
   url: https://links.example.com
   theme: attacca
   plugins:
     - attacca

   attacca:
     site_name: Example Label
     home_url: https://example.com/
   ```

3. Add a release at `_releases/lanterns-at-compline.md` (see [Release files](#release-files)) and its cover under `artwork/`.

4. Copy [`templates/pages.yml`](templates/pages.yml) to `.github/workflows/pages.yml`, then in the repository's settings set Pages to deploy from GitHub Actions.

5. To use your own domain, add a `CNAME` file holding it and point the domain at GitHub Pages.

The site must be served from the root of its domain: a custom domain, or a `<user>.github.io` repository. `baseurl` is not supported, and the build stops if it is set.

The [`example`](example) folder is a complete site you can copy.

To build locally you need Ruby 3.2 or newer and ImageMagick:

```bash
bundle install
bundle exec jekyll serve
```

Without ImageMagick the build still works, but serves covers at their original size. A local preview may use an `http` address; a production build (`JEKYLL_ENV=production`) needs the site's `https` address in `url`.

## Release files

One Markdown file per release in `_releases/`. The front matter holds the data; the body is an optional description.

```yaml
---
slug: LanternsAtCompline     # optional; defaults to the file name
title: Lanterns at Compline
type: Album                  # optional; Album by default
released: 2026-11-20         # optional; YYYY-MM-DD
catalogue: LBL 001           # optional; shown in the footer
artwork: /artwork/lanterns-at-compline.jpg
composers: [Edith Larkspur]
performers:
  - name: The Larkhill Consort
  - name: Rosalind Avery
    role: soprano
links:
  apple_music_classical: https://…
  presto: https://…
  spotify: https://…
  label_shop: https://…      # a custom link from _config.yml
extras:                      # optional
  - name: Programme booklet
    detail: Texts, translations and notes · PDF, 2.4 MB
    kind: booklet            # video, booklet or other
    url: /booklets/lanterns.pdf
---
Seven settings of the evening office for unaccompanied voices.
```

Rules the build enforces:

- `title`, `artwork` and at least one link are required.
- Every link must be an `https` address; an extra may also be a path on the site.
- A slug may contain only letters, digits, hyphens and underscores, and two releases may not share a slug in any casing.
- Use a square cover of at least 1200 px. Only the resized copies are published, never the original file.

## Configuration

Everything lives under `attacca:` in `_config.yml`.

| Key | Default | What it does |
|---|---|---|
| `site_name` | empty | Shown in the header (when there is no logo) and the footer |
| `home_url` | none | Where the site's root address redirects to |
| `logo` | none | `light`, `dark`, `width` (px) and `alt` for a header logo |
| `colours` | neutral palette | `light` and `dark` maps of `ground`, `ink`, `ink2`, `caption`, `rule`, `accent` as hex colours, quoted (`"#1C1917"`) because YAML reads an unquoted `#` as a comment |
| `fonts` | Georgia and the system sans | `display`, `text` and `label` font stacks, and an optional `stylesheet` address that loads them |
| `icons` | `colour` | `colour` uses the colour mark where one exists; `mono` uses black on light and white on dark. Each falls back to the other |
| `attribution` | `true` | The "Powered by attacca" line in the footer |
| `store_order` | built-in order | The order of rows on every page; links not named here follow in the order the release file gives them |
| `custom_links` | none | Extra destinations: each has a `name`, a `verb` and an `icon`, with an optional `icon_dark` |
| `date_format` | `%Y-%m-%d` | How the release date is written |

```yaml
attacca:
  icons: colour
  attribution: true
  store_order: [apple_music_classical, presto, spotify, qobuz, label_shop]
  custom_links:
    label_shop:
      name: Label shop
      verb: Buy the CD
      icon: /icons/shop.svg
```

## Built-in stores

| Key | Store | Button |
|---|---|---|
| `apple_music_classical` | Apple Music Classical | Play |
| `apple_music` | Apple Music | Play |
| `spotify` | Spotify | Play |
| `presto` | Presto Music | Buy |
| `qobuz` | Qobuz | Buy |
| `idagio` | IDAGIO | Play |
| `itunes` | iTunes | Buy |
| `amazon_music` | Amazon Music | Play |
| `deezer` | Deezer | Play |
| `tidal` | TIDAL | Play |
| `youtube_music` | YouTube Music | Play |
| `youtube` | YouTube | Watch |
| `bandcamp` | Bandcamp | Buy |
| `soundcloud` | SoundCloud | Play |
| `boomplay` | Boomplay | Play |

Bandcamp, SoundCloud and Boomplay show a generic mark until their official icons are added.

## Store icons

The icons are the providers' own marks, taken from their brand kits or sites. Each belongs to its provider, and each provider sets rules for using its mark; some require permission. Read [ICONS.md](ICONS.md) for every source and the rules that apply, and check that your use complies before you publish.

## Privacy and discovery

Pages load nothing from third parties unless you set `fonts.stylesheet`. There are no cookies, scripts (except a few lines on the 404 page that retry an address in lowercase) or analytics. A Content Security Policy is set on every page.

The site has no listing of releases and no sitemap, and every page asks search engines not to index it. Anyone with a link can still open it, and slugs that are easy to guess can be found by guessing.

## Development

```bash
bundle install
bundle exec rake test
```

## Licence

The code is under the [MIT licence](LICENSE). The store icons are not covered by it; see [ICONS.md](ICONS.md).
