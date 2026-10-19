# frozen_string_literal: true

module Attacca
  # Validates every release, gives each its lowercase address, adds a page at
  # the casing written in the file, and adds the root redirect and the 404
  # page that retries an address in lowercase.
  class Generator < Jekyll::Generator
    safe true
    priority :highest

    def generate(site)
      config = Config.parse(site.config["attacca"])
      base_url = base_url(site)
      check_files(site, config.custom_links.values.flat_map { |l| [l.icon, l.icon_dark] }, "custom link icon")
      check_files(site, [config.logo&.light, config.logo&.dark], "logo")
      site.data["attacca"] = Presenter.site(config, base_url)
      releases = releases(site, config, base_url)
      drop_source_artwork(site, releases) if Artwork.available?
      add_pages(site, releases)
    end

    # Renders the sized covers and preview images after Jekyll has written the site.
    def self.write_artwork(site)
      return unless Artwork.available? && site.collections["releases"]

      ground = site.data.dig("attacca", "colours", "light", "ground") || DEFAULT_COLOURS.dig("light", "ground")
      out = File.join(site.dest, Presenter::ART_DIR)
      site.collections["releases"].docs.each do |doc|
        release = doc.data["attacca_release"] or next
        source = File.join(site.source, doc.data["artwork"])
        Artwork.render(source, out, release["slug"].downcase, ground: ground)
      end
    end

    private

    # Production builds need the public https address; a local preview may use http.
    def base_url(site)
      unless site.config["baseurl"].to_s.delete("/").empty?
        raise ConfigError, "attacca config:\n  - baseurl is not supported; serve the site from the root of its own domain"
      end

      url = site.config["url"].to_s.chomp("/")
      return url if Checks.https?(url) || (Jekyll.env != "production" && Checks.web?(url))

      raise ConfigError, "attacca config:\n  - url must be set in _config.yml to the site's https address"
    end

    def releases(site, config, base_url)
      collection = site.collections["releases"]
      return [] unless collection

      derived = Artwork.available?
      Jekyll.logger.warn("attacca:", "ImageMagick not found; serving artwork unresized") unless derived
      seen = {}
      collection.docs.map do |doc|
        release = Release.parse(doc.data, config: config, basename: doc.basename_without_ext, path: doc.relative_path)
        check_unique(seen, release)
        check_files(site, [release.artwork], "artwork", release.path)
        doc.data["permalink"] = "/#{release.canonical_slug}/"
        doc.data["attacca_release"] = Presenter.release(
          release, config, base_url: base_url, derived_artwork: derived,
                           description_html: markdown(site, doc.content)
        )
        [doc, release]
      end
    end

    # The sized copies replace the source cover, so a full-resolution master is
    # never published.
    def drop_source_artwork(site, releases)
      sources = releases.map { |_, release| release.artwork }
      site.static_files.reject! { |file| sources.include?(file.relative_path) }
    end

    def check_unique(seen, release)
      other = seen[release.canonical_slug]
      raise ReleaseError, "#{release.path}:\n  - slug #{release.canonical_slug} is also used by #{other}" if other

      seen[release.canonical_slug] = release.path
    end

    def check_files(site, paths, what, where = "attacca config")
      paths.compact.reject { |p| Checks.https?(p) }.each do |path|
        next if File.file?(File.join(site.source, path))

        raise ReleaseError, "#{where}:\n  - #{what} #{path} does not exist"
      end
    end

    def markdown(site, text)
      converter = site.find_converter_instance(Jekyll::Converters::Markdown)
      text.to_s.strip.empty? ? "" : converter.convert(text)
    end

    def add_pages(site, releases)
      releases.each do |doc, release|
        next if release.slug == release.canonical_slug

        site.pages << page(site, "/#{release.slug}/", "attacca-release", "attacca_release" => doc.data["attacca_release"])
      end
      site.pages << page(site, "/", "attacca-home") unless site.pages.any? { |p| p.url == "/" }
      site.pages << page(site, "/", "attacca-404", {}, "404.html") unless site.pages.any? { |p| p.name == "404.html" }
    end

    def page(site, dir, layout, data = {}, name = "index.html")
      Jekyll::PageWithoutAFile.new(site, site.source, dir, name).tap do |p|
        p.content = ""
        p.data.merge!(data, "layout" => layout)
      end
    end
  end
end
