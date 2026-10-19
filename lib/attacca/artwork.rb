# frozen_string_literal: true

require "fileutils"
require "open3"

module Attacca
  # Raised when ImageMagick cannot produce a derived image.
  class ArtworkError < StandardError; end

  # Makes the page sizes and the social preview image from a release's cover,
  # using ImageMagick.
  module Artwork
    SIZES = [600, 1200].freeze
    OG_WIDTH = 1200
    OG_HEIGHT = 630
    QUALITY = "86"

    module_function

    # True when ImageMagick is on the PATH.
    def available?
      !command.nil?
    end

    # The ImageMagick command to run: magick (version 7) or convert (version 6).
    def command
      @command ||= %w[magick convert].find do |name|
        ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? { |dir| File.executable?(File.join(dir, name)) }
      end
    end

    # The derived file names for a slug, relative to the output folder.
    def names(slug)
      SIZES.to_h { |size| [size, "#{slug}-#{size}.jpg"] }.merge(og: "#{slug}-og.jpg")
    end

    # Writes every derived image for one cover into out_dir. The folder is kept
    # between builds, so images newer than the source are skipped.
    def render(source, out_dir, slug, ground:)
      FileUtils.mkdir_p(out_dir)
      names(slug).each do |size, name|
        target = File.join(out_dir, name)
        next if File.exist?(target) && File.mtime(target) >= File.mtime(source)

        run(size == :og ? og_args(source, target, ground) : square_args(source, target, size))
      end
    end

    def square_args(source, target, size)
      [source, "-auto-orient", "-strip", "-resize", "#{size}x#{size}^", "-gravity", "center",
       "-extent", "#{size}x#{size}", "-quality", QUALITY, target]
    end

    def og_args(source, target, ground)
      [source, "-auto-orient", "-strip", "-resize", "#{OG_HEIGHT}x#{OG_HEIGHT}^", "-gravity", "center",
       "-extent", "#{OG_HEIGHT}x#{OG_HEIGHT}", "-background", ground, "-extent", "#{OG_WIDTH}x#{OG_HEIGHT}",
       "-quality", QUALITY, target]
    end

    def run(args)
      raise ArtworkError, "ImageMagick is not installed; install it to build artwork" unless available?

      output, status = Open3.capture2e(command, *args)
      raise ArtworkError, "ImageMagick failed on #{args.first}: #{output.strip}" unless status.success?
    end

    private_class_method :square_args, :og_args, :run
  end
end
