# frozen_string_literal: true

module Attacca
  # Raised when the attacca block in _config.yml is invalid; the message lists
  # every problem so the site owner can fix them in one pass.
  class ConfigError < StandardError; end

  # A destination the site owner defines once in config and links from any release.
  CustomLink = Data.define(:key, :name, :verb, :icon, :icon_dark)

  # The header logo: an image for each theme, its width in pixels and its alt text.
  Logo = Data.define(:light, :dark, :width, :alt)

  # A stylesheet that loads the fonts, and the stacks for display, text and labels.
  Fonts = Data.define(:stylesheet, :display, :text, :label)

  DEFAULT_LOGO_WIDTH = 136
  DEFAULT_DATE_FORMAT = "%Y-%m-%d"
  DEFAULT_VERB = "Open"

  # The validated attacca block of _config.yml. Every value that reaches CSS or
  # an attribute is checked here, so templates can print it without escaping
  # tricks.
  Config = Data.define(:site_name, :home_url, :logo, :colours, :fonts, :icons,
                       :attribution, :store_order, :custom_links, :date_format) do
    def self.parse(data)
      ConfigParser.new(data || {}).parse
    end
  end

  COLOUR_NAMES = %w[ground ink ink2 caption rule accent].freeze

  DEFAULT_COLOURS = {
    "light" => { "ground" => "#FFFFFF", "ink" => "#1C1917", "ink2" => "#44403C",
                 "caption" => "#57534E", "rule" => "#E7E5E4", "accent" => "#1D4ED8" },
    "dark" => { "ground" => "#0C0A09", "ink" => "#FAFAF9", "ink2" => "#D6D3D1",
                "caption" => "#A8A29E", "rule" => "#292524", "accent" => "#93C5FD" }
  }.freeze

  DEFAULT_FONTS = {
    "display" => "Georgia, 'Times New Roman', serif",
    "text" => "Georgia, 'Times New Roman', serif",
    "label" => "system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif"
  }.freeze

  # Parses and validates the config block; kept apart from Config so the data
  # type stays a plain value.
  class ConfigParser
    HEX = /\A#(?:\h{3}|\h{6}|\h{8})\z/
    FONT_FAMILY = /\A[\p{L}\p{N} ,'"._-]+\z/
    KEY = /\A[a-z0-9_]+\z/

    def initialize(data)
      @errors = []
      @data = section(data, "the attacca block")
    end

    def parse
      custom = custom_links
      config = Config.new(
        site_name: Checks.text(@data["site_name"]) || "",
        home_url: home_url,
        logo: logo,
        colours: colours,
        fonts: fonts,
        icons: icons,
        attribution: attribution,
        store_order: store_order(custom),
        custom_links: custom,
        date_format: Checks.text(@data["date_format"]) || DEFAULT_DATE_FORMAT
      )
      raise ConfigError, (["attacca config:"] + @errors.map { |e| "  - #{e}" }).join("\n") if @errors.any?

      config
    end

    private

    def section(value, where)
      return value if value.is_a?(Hash)

      @errors << "#{where} must be a map" unless value.nil?
      {}
    end

    def home_url
      value = @data["home_url"]
      return nil if value.nil?

      @errors << "home_url must be an https address" unless Checks.https?(value)
      value
    end

    def logo
      return nil if @data["logo"].nil?

      data = section(@data["logo"], "logo")
      %w[light dark].each do |side|
        next if data[side].nil? || Checks.site_path?(data[side]) || Checks.https?(data[side])

        @errors << "logo.#{side} must be a path on this site or an https address"
      end
      width = data.fetch("width", DEFAULT_LOGO_WIDTH)
      @errors << "logo.width must be a whole number of pixels" unless width.is_a?(Integer) && width.positive?
      Logo.new(data["light"], data["dark"] || data["light"], width, Checks.text(data["alt"]))
    end

    def colours
      user = section(@data["colours"], "colours")
      DEFAULT_COLOURS.to_h do |theme, defaults|
        given = section(user[theme], "colours.#{theme}")
        given.each_key do |name|
          @errors << "colours.#{theme}.#{name} is not a known colour (use #{COLOUR_NAMES.join(', ')})" unless COLOUR_NAMES.include?(name)
        end
        merged = defaults.merge(given.slice(*COLOUR_NAMES))
        merged.each do |name, value|
          @errors << "colours.#{theme}.#{name} must be a hex colour such as \"#1C1917\" (quote it in YAML)" unless HEX.match?(value.to_s)
        end
        [theme, merged]
      end
    end

    def fonts
      user = section(@data["fonts"], "fonts")
      families = DEFAULT_FONTS.to_h do |role, fallback|
        value = user[role] || fallback
        unless value.is_a?(String) && FONT_FAMILY.match?(value)
          @errors << "fonts.#{role} may contain only font names, quotes, commas and spaces"
        end
        [role, value]
      end
      stylesheet = user["stylesheet"]
      @errors << "fonts.stylesheet must be an https address" unless stylesheet.nil? || Checks.https?(stylesheet)
      Fonts.new(stylesheet, families["display"], families["text"], families["label"])
    end

    def icons
      value = (@data["icons"] || "colour").to_s
      return value.to_sym if %w[colour mono].include?(value)

      @errors << "icons must be colour or mono"
      :colour
    end

    def attribution
      value = @data.fetch("attribution", true)
      return value if [true, false].include?(value)

      @errors << "attribution must be true or false"
      true
    end

    def custom_links
      section(@data["custom_links"], "custom_links").to_h do |key, link|
        [key, custom_link(key.to_s, section(link, "custom_links.#{key}"))]
      end
    end

    def custom_link(key, link)
      where = "custom_links.#{key}"
      @errors << "#{where} must be lowercase letters, digits and underscores" unless KEY.match?(key)
      @errors << "#{where} clashes with a built-in store" if STORES.key?(key)
      @errors << "#{where}.name is required" unless Checks.present?(link["name"])
      %w[icon icon_dark].each do |field|
        value = link[field]
        next if value.nil? && field == "icon_dark"

        unless Checks.site_path?(value) || Checks.https?(value)
          @errors << "#{where}.#{field} #{value.nil? ? 'is required' : 'must be a path on this site or an https address'}"
        end
      end
      CustomLink.new(key, Checks.text(link["name"]), Checks.text(link["verb"]) || DEFAULT_VERB, link["icon"], link["icon_dark"])
    end

    def store_order(custom)
      order = @data["store_order"]
      return DEFAULT_STORE_ORDER if order.nil?

      order = Array(order).map(&:to_s)
      order.each do |key|
        @errors << "store_order names #{key}, which is not a built-in store or a custom link" unless STORES.key?(key) || custom.key?(key)
      end
      order.uniq.freeze
    end
  end
end
