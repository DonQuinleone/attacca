# frozen_string_literal: true

require_relative "test_helper"

class IconsTest < Minitest::Test
  def store(key)
    Attacca::STORES.fetch(key)
  end

  def test_colour_mode_uses_the_colour_icon_in_both_themes
    pair = Attacca::Icons.for_store(store("spotify"), :colour)

    assert_equal "/assets/attacca/icons/colour/spotify.svg", pair.light
    assert_equal "/assets/attacca/icons/colour/spotify.svg", pair.dark
  end

  def test_colour_mode_falls_back_to_mono_where_there_is_no_colour_icon
    pair = Attacca::Icons.for_store(store("idagio"), :colour)

    assert_equal "/assets/attacca/icons/mono-black/idagio.svg", pair.light
    assert_equal "/assets/attacca/icons/mono-white/idagio.svg", pair.dark
  end

  def test_itunes_has_its_colour_star
    pair = Attacca::Icons.for_store(store("itunes"), :colour)

    assert_equal "/assets/attacca/icons/colour/itunes.png", pair.light
  end

  def test_mono_mode_uses_black_on_light_and_white_on_dark
    pair = Attacca::Icons.for_store(store("apple_music"), :mono)

    assert_equal "/assets/attacca/icons/mono-black/apple_music.svg", pair.light
    assert_equal "/assets/attacca/icons/mono-white/apple_music.svg", pair.dark
  end

  def test_mono_mode_falls_back_to_colour_where_there_is_no_mono_icon
    pair = Attacca::Icons.for_store(store("deezer"), :mono)

    assert_equal "/assets/attacca/icons/colour/deezer.png", pair.light
    assert_equal "/assets/attacca/icons/colour/deezer.png", pair.dark
  end

  def test_a_store_without_any_icon_gets_the_generic_mark
    pair = Attacca::Icons.for_store(store("boomplay"), :colour)

    assert_equal Attacca::Icons::GENERIC, pair.light
    assert_equal Attacca::Icons::GENERIC, pair.dark
  end

  def test_every_icon_the_registry_names_exists_in_the_theme
    root = File.expand_path("..", __dir__)
    paths = Attacca::STORES.values.flat_map { |s| [s.colour, s.black, s.white] }.compact

    paths.each { |path| assert File.file?(File.join(root, path)), "missing #{path}" }
  end
end
