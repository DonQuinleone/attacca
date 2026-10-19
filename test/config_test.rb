# frozen_string_literal: true

require_relative "test_helper"

class ConfigTest < Minitest::Test
  def test_defaults_when_nothing_is_set
    cfg = Attacca::Config.parse({})

    assert_equal :colour, cfg.icons
    assert cfg.attribution
    assert_equal Attacca::DEFAULT_STORE_ORDER, cfg.store_order
    assert_empty cfg.custom_links
    assert_equal "%Y-%m-%d", cfg.date_format
  end

  def test_rejects_an_unknown_icon_mode
    error = assert_raises(Attacca::ConfigError) { Attacca::Config.parse("icons" => "rainbow") }

    assert_match(/icons must be colour or mono/, error.message)
  end

  def test_rejects_a_colour_that_is_not_hex
    data = { "colours" => { "light" => { "accent" => "red; background: url(x)" } } }

    error = assert_raises(Attacca::ConfigError) { Attacca::Config.parse(data) }

    assert_match(/colours.light.accent/, error.message)
  end

  def test_rejects_an_unknown_colour_name
    error = assert_raises(Attacca::ConfigError) do
      Attacca::Config.parse("colours" => { "dark" => { "glow" => "#ffffff" } })
    end

    assert_match(/colours.dark.glow is not a known colour/, error.message)
  end

  def test_rejects_a_font_family_that_could_break_out_of_css
    error = assert_raises(Attacca::ConfigError) do
      Attacca::Config.parse("fonts" => { "text" => "Georgia; } body { display: none" })
    end

    assert_match(/fonts.text/, error.message)
  end

  def test_rejects_a_stylesheet_that_is_not_https
    error = assert_raises(Attacca::ConfigError) do
      Attacca::Config.parse("fonts" => { "stylesheet" => "http://fonts.example.com/css" })
    end

    assert_match(/fonts.stylesheet must be an https address/, error.message)
  end

  def test_rejects_a_home_url_that_is_not_https
    error = assert_raises(Attacca::ConfigError) { Attacca::Config.parse("home_url" => "javascript:alert(1)") }

    assert_match(/home_url must be an https address/, error.message)
  end

  def test_rejects_an_unknown_key_in_store_order
    error = assert_raises(Attacca::ConfigError) { Attacca::Config.parse("store_order" => %w[spotify myspace]) }

    assert_match(/store_order names myspace/, error.message)
  end

  def test_accepts_a_custom_link_and_lets_store_order_name_it
    cfg = Attacca::Config.parse(
      "custom_links" => { "label_shop" => { "name" => "Label shop", "verb" => "Buy the CD", "icon" => "/icons/shop.svg" } },
      "store_order" => %w[label_shop spotify]
    )

    assert_equal "Label shop", cfg.custom_links.fetch("label_shop").name
    assert_equal %w[label_shop spotify], cfg.store_order
  end

  def test_rejects_a_custom_link_that_shadows_a_built_in_store
    error = assert_raises(Attacca::ConfigError) do
      Attacca::Config.parse("custom_links" => { "spotify" => { "name" => "Mine", "icon" => "/i.svg" } })
    end

    assert_match(/custom_links.spotify clashes with a built-in store/, error.message)
  end

  def test_rejects_a_custom_link_without_a_name
    error = assert_raises(Attacca::ConfigError) do
      Attacca::Config.parse("custom_links" => { "label_shop" => { "icon" => "/i.svg" } })
    end

    assert_match(/custom_links.label_shop.name is required/, error.message)
  end

  def test_reports_sections_of_the_wrong_shape_instead_of_crashing
    error = assert_raises(Attacca::ConfigError) do
      Attacca::Config.parse("logo" => "/logo.svg", "colours" => { "light" => "#fff" }, "fonts" => { "text" => 123 }, "custom_links" => ["shop"])
    end

    assert_match(/logo must be a map/, error.message)
    assert_match(/colours.light must be a map/, error.message)
    assert_match(/fonts.text may contain only font names/, error.message)
    assert_match(/custom_links must be a map/, error.message)
  end

  def test_reports_a_whole_block_of_the_wrong_shape
    error = assert_raises(Attacca::ConfigError) { Attacca::Config.parse("x") }

    assert_match(/the attacca block must be a map/, error.message)
  end

  def test_hints_at_quoting_a_colour_that_yaml_read_as_a_comment
    error = assert_raises(Attacca::ConfigError) { Attacca::Config.parse("colours" => { "light" => { "ink" => nil } }) }

    assert_match(/quote it in YAML/, error.message)
  end

  def test_validates_the_logo
    error = assert_raises(Attacca::ConfigError) do
      Attacca::Config.parse("logo" => { "light" => "logo.svg", "width" => "wide" })
    end

    assert_match(/logo.light must be a path on this site or an https address/, error.message)
    assert_match(/logo.width must be a whole number of pixels/, error.message)
  end

  def test_reports_every_problem_at_once
    error = assert_raises(Attacca::ConfigError) do
      Attacca::Config.parse("icons" => "rainbow", "home_url" => "ftp://x")
    end

    assert_match(/icons/, error.message)
    assert_match(/home_url/, error.message)
  end
end
