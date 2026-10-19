# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "attacca/core"

module ReleaseHelpers
  def config(overrides = {})
    Attacca::Config.parse(overrides)
  end

  def release_data(overrides = {})
    {
      "title" => "Lanterns at Compline",
      "artwork" => "/artwork/lanterns.jpg",
      "composers" => ["Edith Larkspur"],
      "performers" => [{ "name" => "Julian Marchetti", "role" => "conductor" }],
      "links" => { "spotify" => "https://open.spotify.com/album/x" }
    }.merge(overrides)
  end

  def parse_release(data, cfg = config, basename: "lanterns-at-compline")
    Attacca::Release.parse(data, config: cfg, basename: basename, path: "_releases/#{basename}.md")
  end
end
