# frozen_string_literal: true

require "date"
require_relative "test_helper"

class ReleaseTest < Minitest::Test
  include ReleaseHelpers

  def test_parses_a_minimal_release_and_takes_the_slug_from_the_file_name
    release = parse_release(release_data)

    assert_equal "Lanterns at Compline", release.title
    assert_equal "lanterns-at-compline", release.slug
    assert_equal "Album", release.type
    assert_equal ["Edith Larkspur"], release.composers
    assert_equal "conductor", release.performers.first.role
  end

  def test_keeps_the_casing_of_an_explicit_slug
    release = parse_release(release_data("slug" => "DavidsAir"))

    assert_equal "DavidsAir", release.slug
    assert_equal "davidsair", release.canonical_slug
  end

  def test_accepts_a_single_composer_as_a_string
    release = parse_release(release_data("composers" => "Edith Larkspur"))

    assert_equal ["Edith Larkspur"], release.composers
  end

  def test_accepts_a_date_or_an_iso_string_for_released
    assert_equal Date.new(2026, 11, 20), parse_release(release_data("released" => Date.new(2026, 11, 20))).released
    assert_equal Date.new(2026, 11, 20), parse_release(release_data("released" => "2026-11-20")).released
  end

  def test_rejects_a_date_that_does_not_exist
    error = assert_raises(Attacca::ReleaseError) { parse_release(release_data("released" => "2026-13-45")) }

    assert_match(/released must be a date written YYYY-MM-DD/, error.message)
  end

  def test_reports_every_problem_in_one_error
    data = release_data(
      "title" => "",
      "released" => "2026/11/20",
      "links" => { "spotify" => "http://open.spotify.com/album/x", "myspace" => "https://myspace.com/x" }
    )

    error = assert_raises(Attacca::ReleaseError) { parse_release(data) }

    assert_match(%r{_releases/lanterns-at-compline.md}, error.message)
    assert_match(/title is required/, error.message)
    assert_match(/released must be a date written YYYY-MM-DD/, error.message)
    assert_match(/links.spotify must be an https address/, error.message)
    assert_match(/links.myspace is not a built-in store or a custom link/, error.message)
  end

  def test_requires_at_least_one_link_and_artwork
    error = assert_raises(Attacca::ReleaseError) { parse_release(release_data("links" => {}, "artwork" => nil)) }

    assert_match(/links must name at least one store/, error.message)
    assert_match(/artwork is required/, error.message)
  end

  def test_rejects_a_slug_that_is_not_a_plain_name
    error = assert_raises(Attacca::ReleaseError) { parse_release(release_data("slug" => "../escape")) }

    assert_match(/slug may contain only letters, digits, hyphens and underscores/, error.message)
  end

  def test_orders_links_by_store_order_then_the_rest_in_file_order
    cfg = config("store_order" => %w[presto spotify])
    links = {
      "deezer" => "https://deezer.com/a",
      "spotify" => "https://open.spotify.com/a",
      "qobuz" => "https://qobuz.com/a",
      "presto" => "https://prestomusic.com/a"
    }

    release = parse_release(release_data("links" => links), cfg)

    assert_equal %w[presto spotify deezer qobuz], release.links.map(&:key)
  end

  def test_builds_a_custom_link_from_the_config
    cfg = config("custom_links" => { "label_shop" => { "name" => "Label shop", "verb" => "Buy the CD", "icon" => "/icons/shop.svg" } })

    release = parse_release(release_data("links" => { "label_shop" => "https://example.com/shop" }), cfg)
    link = release.links.first

    assert_equal "Label shop", link.name
    assert_equal "Buy the CD", link.verb
    assert_equal "/icons/shop.svg", link.icon.light
  end

  def test_gives_a_built_in_store_its_name_and_verb
    link = parse_release(release_data).links.first

    assert_equal "Spotify", link.name
    assert_equal "Play", link.verb
  end

  def test_validates_extras
    extras = [
      { "name" => "Programme booklet", "url" => "/booklets/lanterns.pdf", "kind" => "booklet", "detail" => "PDF, 2.4 MB" },
      { "name" => "", "url" => "http://example.com", "kind" => "hologram" }
    ]

    error = assert_raises(Attacca::ReleaseError) { parse_release(release_data("extras" => extras)) }

    assert_match(/extras.2.name is required/, error.message)
    assert_match(/extras.2.url must be an https address or a path on this site/, error.message)
    assert_match(/extras.2.kind must be one of video, booklet, other/, error.message)
    refute_match(/extras.1/, error.message)
  end

  def test_extras_are_empty_by_default
    assert_empty parse_release(release_data).extras
  end
end
