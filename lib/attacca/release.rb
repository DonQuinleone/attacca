# frozen_string_literal: true

require "date"

module Attacca
  # Raised when a release file is invalid; the message names the file and lists
  # every problem in it.
  class ReleaseError < StandardError; end

  # A performer and, where given, their role (conductor, soprano, organ).
  Person = Data.define(:name, :role)

  DEFAULT_TYPE = "Album"

  # One row on the page: where it goes, what it is called and which icons it shows.
  Link = Data.define(:key, :name, :verb, :url, :icon)

  # An optional extra such as a video or a booklet.
  Extra = Data.define(:name, :detail, :kind, :url)

  EXTRA_KINDS = %w[video booklet other].freeze

  # A validated release, built from a file's front matter.
  Release = Data.define(:path, :slug, :title, :type, :released, :catalogue, :artwork,
                        :composers, :performers, :links, :extras) do
    def self.parse(data, config:, basename:, path:)
      ReleaseParser.new(data || {}, config, basename, path).parse
    end

    # The address the release is canonically served at; any casing of the slug
    # resolves to it.
    def canonical_slug
      slug.downcase
    end
  end

  # Parses one release's front matter against the site config.
  class ReleaseParser
    SLUG = /\A[A-Za-z0-9_-]+\z/
    ISO_DATE = /\A\d{4}-\d{2}-\d{2}\z/

    def initialize(data, config, basename, path)
      @data = data
      @config = config
      @basename = basename
      @path = path
      @errors = []
    end

    def parse
      release = Release.new(
        path: @path, slug: slug, title: title, type: Checks.text(@data["type"]) || DEFAULT_TYPE,
        released: released, catalogue: Checks.text(@data["catalogue"]), artwork: artwork,
        composers: composers, performers: performers, links: links, extras: extras
      )
      raise ReleaseError, ([@path + ":"] + @errors.map { |e| "  - #{e}" }).join("\n") if @errors.any?

      release
    end

    private

    def title
      Checks.text(@data["title"]).tap { |t| @errors << "title is required" if t.nil? }
    end

    def slug
      value = (@data["slug"] || @basename).to_s
      @errors << "slug may contain only letters, digits, hyphens and underscores" unless SLUG.match?(value)
      value
    end

    def released
      value = @data["released"]
      return nil if value.nil?
      return value.to_date if value.respond_to?(:to_date) && !value.is_a?(String)
      return Date.iso8601(value) if value.is_a?(String) && ISO_DATE.match?(value)

      @errors << "released must be a date written YYYY-MM-DD"
      nil
    rescue Date::Error
      @errors << "released must be a date written YYYY-MM-DD"
      nil
    end

    def artwork
      value = @data["artwork"]
      if value.nil?
        @errors << "artwork is required"
      elsif !Checks.site_path?(value)
        @errors << "artwork must be a path on this site, starting with /"
      end
      value
    end

    def composers
      Array(@data["composers"]).filter_map { |name| Checks.text(name) }
    end

    def performers
      Array(@data["performers"]).each_with_index.filter_map do |entry, index|
        entry = { "name" => entry } if entry.is_a?(String)
        name = Checks.text(entry.is_a?(Hash) ? entry["name"] : nil)
        @errors << "performers.#{index + 1}.name is required" if name.nil?
        name && Person.new(name, Checks.text(entry["role"]))
      end
    end

    def links
      given = @data["links"]
      unless given.is_a?(Hash) && given.any?
        @errors << "links must name at least one store"
        return []
      end
      ordered_keys(given.keys.map(&:to_s)).filter_map { |key| link(key, given[key]) }
    end

    def ordered_keys(keys)
      first = @config.store_order.select { |key| keys.include?(key) }
      first + (keys - first)
    end

    def link(key, url)
      @errors << "links.#{key} must be an https address" unless Checks.https?(url)
      if (store = STORES[key])
        Link.new(key, store.name, store.verb, url, Icons.for_store(store, @config.icons))
      elsif (custom = @config.custom_links[key])
        Link.new(key, custom.name, custom.verb, url, Icons.for_custom(custom))
      else
        @errors << "links.#{key} is not a built-in store or a custom link"
        nil
      end
    end

    def extras
      Array(@data["extras"]).each_with_index.map do |entry, index|
        entry = {} unless entry.is_a?(Hash)
        extra(entry, "extras.#{index + 1}")
      end
    end

    def extra(entry, where)
      name = Checks.text(entry["name"])
      url = entry["url"]
      kind = (entry["kind"] || "other").to_s
      @errors << "#{where}.name is required" if name.nil?
      @errors << "#{where}.url must be an https address or a path on this site" unless Checks.https?(url) || Checks.site_path?(url)
      @errors << "#{where}.kind must be one of #{EXTRA_KINDS.join(', ')}" unless EXTRA_KINDS.include?(kind)
      Extra.new(name, Checks.text(entry["detail"]), kind, url)
    end
  end
end
