# frozen_string_literal: true

module Attacca
  # Chooses which icon file a row shows on a light and on a dark ground.
  module Icons
    # The icon for the light theme and the one for the dark theme.
    Pair = Data.define(:light, :dark)

    GENERIC = "#{ICON_ROOT}/generic.svg".freeze

    # Colour mode prefers the colour mark and falls back to mono; mono mode
    # prefers mono and falls back to colour, so a row is never left blank.
    def self.for_store(store, mode)
      light, dark =
        if mode == :mono
          [store.black || store.colour, store.white || store.colour]
        else
          [store.colour || store.black, store.colour || store.white]
        end
      Pair.new(light || dark || GENERIC, dark || light || GENERIC)
    end

    # A custom link names its own icon, with an optional variant for dark grounds.
    def self.for_custom(link)
      Pair.new(link.icon, link.icon_dark || link.icon)
    end
  end
end
