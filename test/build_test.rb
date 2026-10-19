# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "test_helper"
require "attacca"

class BuildTest < Minitest::Test
  FIXTURE = File.expand_path("fixtures/site", __dir__)

  def build(overrides = {})
    @dir = Dir.mktmpdir("attacca-build")
    source = File.join(@dir, "src")
    FileUtils.cp_r(FIXTURE, source)
    config = Jekyll.configuration(
      "source" => source,
      "destination" => File.join(@dir, "_site"),
      "quiet" => true
    ).merge(overrides)
    Jekyll::Site.new(config).process
    File.join(@dir, "_site")
  end

  def teardown
    FileUtils.remove_entry(@dir) if @dir
  end

  def read(site, path)
    File.read(File.join(site, path))
  end

  def test_writes_the_release_at_its_lowercase_address
    page = read(build, "mixedcase/index.html")

    assert_includes page, "<h1"
    assert_includes page, "Mixed Case"
    assert_includes page, %(<link rel="canonical" href="https://links.example.com/mixedcase/">)
  end

  def test_also_serves_the_release_at_the_casing_in_the_file
    site = build

    assert File.file?(File.join(site, "MixedCase/index.html")) || case_insensitive?(site)
    assert_includes read(site, "MixedCase/index.html"), "Mixed Case"
  end

  def test_keeps_every_page_out_of_search_engines
    site = build

    %w[mixedcase/index.html index.html 404.html].each do |path|
      assert_includes read(site, path), %(<meta name="robots" content="noindex">), path
    end
    refute File.exist?(File.join(site, "sitemap.xml"))
  end

  def test_root_redirects_to_the_home_url_and_lists_nothing
    page = read(build, "index.html")

    assert_includes page, %(content="0; url=https://example.com/")
    refute_includes page, "mixedcase"
  end

  def test_not_found_page_retries_the_address_in_lowercase
    page = read(build, "404.html")

    assert_includes page, "toLowerCase()"
    refute_includes page, "mixedcase"
  end

  def test_lists_stores_in_the_configured_order_with_the_custom_link
    page = read(build, "mixedcase/index.html")
    order = %w[Presto\ Music Label\ shop Spotify].map { |name| page.index(">#{name}<") }

    assert order.all?, "every store row is present"
    assert_equal order.sort, order
  end

  def test_shows_the_attribution_unless_turned_off
    assert_includes read(build, "mixedcase/index.html"), "Powered by"

    off = build("attacca" => YAML.safe_load_file(File.join(FIXTURE, "_config.yml"))["attacca"].merge("attribution" => false))
    refute_includes read(off, "mixedcase/index.html"), "Powered by"
  end

  def test_social_preview_points_at_a_generated_image
    site = build
    page = read(site, "mixedcase/index.html")

    assert_includes page, %(<meta property="og:image" content="https://links.example.com/attacca/art/mixedcase-og.jpg">)
    skip "ImageMagick is not installed" unless Attacca::Artwork.available?
    assert File.file?(File.join(site, "attacca/art/mixedcase-og.jpg"))
    assert File.file?(File.join(site, "attacca/art/mixedcase-600.jpg"))
    refute File.exist?(File.join(site, "artwork/cover.png")), "the source cover is not published"
  end

  def test_fails_the_build_on_an_invalid_release
    @dir = Dir.mktmpdir("attacca-build")
    source = File.join(@dir, "src")
    FileUtils.cp_r(FIXTURE, source)
    File.write(File.join(source, "_releases", "broken.md"), "---\ntitle: Broken\nlinks:\n  myspace: https://myspace.com/x\n---\n")
    config = Jekyll.configuration("source" => source, "destination" => File.join(@dir, "_site"), "quiet" => true)

    error = assert_raises(Attacca::ReleaseError) { Jekyll::Site.new(config).process }

    assert_match(/broken.md/, error.message)
  end

  def test_fails_the_build_on_two_releases_whose_slugs_differ_only_in_case
    @dir = Dir.mktmpdir("attacca-build")
    source = File.join(@dir, "src")
    FileUtils.cp_r(FIXTURE, source)
    original = File.read(File.join(source, "_releases", "MixedCase.md"))
    File.write(File.join(source, "_releases", "other.md"), original.sub("slug: MixedCase", "slug: mixedcase"))
    config = Jekyll.configuration("source" => source, "destination" => File.join(@dir, "_site"), "quiet" => true)

    error = assert_raises(Attacca::ReleaseError) { Jekyll::Site.new(config).process }

    assert_match(/slug mixedcase is also used by/, error.message)
  end

  def test_builds_for_local_preview_with_an_http_address
    page = read(build("url" => "http://localhost:4000"), "mixedcase/index.html")

    assert_includes page, %(<link rel="canonical" href="http://localhost:4000/mixedcase/">)
  end

  def test_refuses_a_baseurl
    error = assert_raises(Attacca::ConfigError) { build("baseurl" => "/repo") }

    assert_match(/baseurl is not supported/, error.message)
  end

  def test_fails_the_build_when_a_cover_is_missing
    @dir = Dir.mktmpdir("attacca-build")
    source = File.join(@dir, "src")
    FileUtils.cp_r(FIXTURE, source)
    File.delete(File.join(source, "artwork", "cover.png"))
    config = Jekyll.configuration("source" => source, "destination" => File.join(@dir, "_site"), "quiet" => true)

    error = assert_raises(Attacca::ReleaseError) { Jekyll::Site.new(config).process }

    assert_match(%r{artwork /artwork/cover.png does not exist}, error.message)
  end

  def test_keeps_resized_artwork_between_builds
    skip "ImageMagick is not installed" unless Attacca::Artwork.available?
    @dir = Dir.mktmpdir("attacca-build")
    source = File.join(@dir, "src")
    FileUtils.cp_r(FIXTURE, source)
    config = Jekyll.configuration("source" => source, "destination" => File.join(@dir, "_site"), "quiet" => true)
    og = File.join(@dir, "_site", "attacca/art/mixedcase-og.jpg")

    Jekyll::Site.new(config).process
    first = File.mtime(og)
    sleep 1.1
    Jekyll::Site.new(config).process

    assert_equal first, File.mtime(og)
  end

  private

  def case_insensitive?(dir)
    File.exist?(File.join(dir, "MIXEDCASE"))
  end
end
