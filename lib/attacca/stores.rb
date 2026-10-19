# frozen_string_literal: true

module Attacca
  # A built-in destination: the label on its row, the verb on its button and
  # the official icon files the theme ships for it. A nil icon means the
  # provider publishes no file in that variant.
  Store = Data.define(:key, :name, :verb, :colour, :black, :white)

  ICON_ROOT = "/assets/attacca/icons"

  # Rows of key, name, verb, then the file extension of each icon variant
  # (colour, mono black, mono white), nil where the variant does not exist.
  STORE_TABLE = [
    ["apple_music_classical", "Apple Music Classical", "Play", "svg", "svg", "svg"],
    ["apple_music", "Apple Music", "Play", "svg", "svg", "svg"],
    ["spotify", "Spotify", "Play", "svg", "svg", "svg"],
    ["presto", "Presto Music", "Buy", "svg", nil, "svg"],
    ["qobuz", "Qobuz", "Buy", "svg", nil, nil],
    ["idagio", "IDAGIO", "Play", nil, "svg", "svg"],
    ["itunes", "iTunes", "Buy", nil, "svg", "svg"],
    ["amazon_music", "Amazon Music", "Play", "svg", "svg", "svg"],
    ["deezer", "Deezer", "Play", "png", nil, nil],
    ["tidal", "TIDAL", "Play", nil, "png", "png"],
    ["youtube_music", "YouTube Music", "Play", "png", nil, nil],
    ["youtube", "YouTube", "Watch", "png", nil, "png"],
    ["bandcamp", "Bandcamp", "Buy", nil, nil, nil],
    ["soundcloud", "SoundCloud", "Play", nil, nil, nil],
    ["boomplay", "Boomplay", "Play", nil, nil, nil]
  ].freeze

  icon = ->(variant, key, ext) { ext && "#{ICON_ROOT}/#{variant}/#{key}.#{ext}" }

  # Every built-in store by key, in the default display order.
  STORES = STORE_TABLE.to_h do |key, name, verb, colour, black, white|
    [key, Store.new(key, name, verb,
                    icon.call("colour", key, colour),
                    icon.call("mono-black", key, black),
                    icon.call("mono-white", key, white))]
  end.freeze

  DEFAULT_STORE_ORDER = STORES.keys.freeze
end
