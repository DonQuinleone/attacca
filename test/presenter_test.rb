# frozen_string_literal: true

require_relative "test_helper"
require "attacca/presenter"

class PresenterTest < Minitest::Test
  include ReleaseHelpers

  def test_allows_google_fonts_and_its_font_host_in_the_policy
    fonts = Attacca::Presenter.fonts(Attacca::Fonts.new("https://fonts.googleapis.com/css2?family=X", "a", "b", "c"))

    assert_equal "https://fonts.googleapis.com https://fonts.gstatic.com", fonts["origins"]
  end

  def test_allows_no_font_origin_without_a_stylesheet
    fonts = Attacca::Presenter.fonts(Attacca::Fonts.new(nil, "a", "b", "c"))

    assert_equal "", fonts["origins"]
  end

  def test_describes_the_release_for_link_previews
    data = Attacca::Presenter.release(parse_release(release_data), config, base_url: "https://links.example.com",
                                                                           description_html: "", derived_artwork: true)

    assert_equal "Lanterns at Compline by Edith Larkspur, Julian Marchetti. Listen on Spotify.", data["meta_description"]
    assert_equal "https://links.example.com/attacca/art/lanterns-at-compline-og.jpg", data["og_image"]
    assert_equal({ "width" => 1200, "height" => 630 }, data["og_size"])
  end

  def test_presents_composers_with_their_roles_and_titles_the_page_by_name
    data = Attacca::Presenter.release(
      parse_release(release_data("composers" => [{ "name" => "Howard Goodall", "role" => "arranger" }])),
      config, base_url: "https://links.example.com", description_html: "", derived_artwork: true
    )

    assert_equal [{ "name" => "Howard Goodall", "role" => "arranger" }], data["composers"]
    assert_equal "Lanterns at Compline · Howard Goodall", data["page_title"]
  end

  def test_uses_the_source_cover_when_artwork_cannot_be_resized
    data = Attacca::Presenter.release(parse_release(release_data), config, base_url: "https://links.example.com",
                                                                           description_html: "", derived_artwork: false)

    assert_equal "https://links.example.com/artwork/lanterns.jpg", data["og_image"]
    assert_nil data["og_size"]
    assert_empty data["artwork"]["srcset"]
  end
end
