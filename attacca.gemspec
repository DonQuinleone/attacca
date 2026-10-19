# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "attacca"
  spec.version = File.read(File.join(__dir__, "VERSION")).strip
  spec.authors = ["DonQuinleone"]
  spec.email = ["don@donquinleone.com"]
  spec.summary = "Static smart-link pages for classical releases, built with Jekyll."
  spec.homepage = "https://github.com/DonQuinleone/attacca"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir["{_layouts,_includes,assets,lib}/**/*", "LICENSE", "README.md", "VERSION"]
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", "~> 4.4"
end
