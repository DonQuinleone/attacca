# frozen_string_literal: true

require "jekyll"
require_relative "attacca/core"
require_relative "attacca/presenter"
require_relative "attacca/generator"

module Attacca
  # Registers the releases collection and gives its documents the release
  # layout, so a site needs only `theme: attacca` and `plugins: [attacca]`.
  def self.configure(site)
    collections = site.config["collections"] ||= {}
    collections["releases"] = (collections["releases"] || {}).merge("output" => true)
    site.keep_files = (site.keep_files | [Presenter::ART_DIR.delete_prefix("/")])
    defaults = site.config["defaults"] ||= []
    return if defaults.any? { |d| d.dig("scope", "type") == "releases" }

    defaults << { "scope" => { "path" => "", "type" => "releases" }, "values" => { "layout" => "attacca-release" } }
  end
end

Jekyll::Hooks.register :site, :after_reset do |site|
  Attacca.configure(site)
end

Jekyll::Hooks.register :site, :post_write do |site|
  Attacca::Generator.write_artwork(site)
end
