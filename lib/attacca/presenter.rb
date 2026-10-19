# frozen_string_literal: true

module Attacca
  # Turns validated values into the plain hashes Liquid templates read.
  module Presenter
    ART_DIR = "/attacca/art"

    module_function

    # Site-wide values for every layout: name, home, logo, palette, fonts and attribution.
    def site(config, base_url)
      {
        "site_name" => config.site_name,
        "home_url" => config.home_url,
        "logo" => config.logo && { "light" => config.logo.light, "dark" => config.logo.dark,
                                   "width" => config.logo.width, "alt" => config.logo.alt || config.site_name },
        "colours" => config.colours,
        "fonts" => fonts(config.fonts),
        "attribution" => config.attribution,
        "base_url" => base_url
      }
    end

    # Font stacks plus the origins the Content Security Policy must allow for them.
    def fonts(fonts)
      stylesheet = fonts.stylesheet
      origins = stylesheet ? [origin(stylesheet)] : []
      origins << "https://fonts.gstatic.com" if origins.include?("https://fonts.googleapis.com")
      { "stylesheet" => stylesheet, "origins" => origins.join(" "),
        "display" => fonts.display, "text" => fonts.text, "label" => fonts.label }
    end

    def origin(url)
      uri = URI.parse(url)
      "#{uri.scheme}://#{uri.host}"
    end

    # Everything the release layout prints for one release.
    def release(release, config, base_url:, description_html:, derived_artwork:)
      canonical = "#{base_url}/#{release.canonical_slug}/"
      art = artwork(release, derived_artwork)
      {
        "slug" => release.slug,
        "title" => release.title,
        "eyebrow" => [release.type, release.released&.strftime(config.date_format)].compact.join(" · "),
        "composers" => release.composers,
        "composer_label" => release.composers.size == 1 ? "Composer" : "Composers",
        "performers" => release.performers.map { |p| { "name" => p.name, "role" => p.role } },
        "performer_label" => release.performers.size == 1 ? "Performer" : "Performers",
        "links" => release.links.map { |l| link(l) },
        "extras" => release.extras.map { |e| { "name" => e.name, "detail" => e.detail, "kind" => e.kind, "url" => e.url } },
        "catalogue" => release.catalogue,
        "description_html" => description_html,
        "artwork" => art,
        "canonical_url" => canonical,
        "og_image" => "#{base_url}#{art['og']}",
        "og_size" => derived_artwork ? { "width" => Artwork::OG_WIDTH, "height" => Artwork::OG_HEIGHT } : nil,
        "page_title" => [release.title, release.composers.join(", ")].reject(&:empty?).join(" · "),
        "meta_description" => meta_description(release)
      }
    end

    def link(link)
      { "key" => link.key, "name" => link.name, "verb" => link.verb, "url" => link.url,
        "icon_light" => link.icon.light, "icon_dark" => link.icon.dark,
        "icon_differs" => link.icon.light != link.icon.dark }
    end

    def artwork(release, derived)
      return { "src" => release.artwork, "srcset" => "", "og" => release.artwork } unless derived

      names = Artwork.names(release.canonical_slug)
      sizes = Artwork::SIZES
      { "src" => "#{ART_DIR}/#{names[sizes.first]}",
        "srcset" => sizes.map { |size| "#{ART_DIR}/#{names[size]} #{size}w" }.join(", "),
        "og" => "#{ART_DIR}/#{names[:og]}" }
    end

    def meta_description(release)
      by = (release.composers + release.performers.map(&:name)).first(3).join(", ")
      stores = release.links.first(4).map(&:name).join(", ")
      [release.title, by.empty? ? nil : "by #{by}"].compact.join(" ") + ". Listen on #{stores}."
    end
  end
end
