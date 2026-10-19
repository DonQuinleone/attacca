# frozen_string_literal: true

require "uri"

module Attacca
  # Small predicates shared by the config and release parsers.
  module Checks
    module_function

    # True for an absolute https address with a host.
    def https?(value)
      web?(value, %w[https])
    end

    # True for an absolute http or https address with a host.
    def web?(value, schemes = %w[http https])
      return false unless value.is_a?(String)

      uri = URI.parse(value)
      schemes.include?(uri.scheme) && !uri.host.to_s.empty?
    rescue URI::InvalidURIError
      false
    end

    # True for a path on the site itself: rooted, never protocol-relative, never climbing out.
    def site_path?(value)
      value.is_a?(String) && value.start_with?("/") && !value.start_with?("//") && !value.include?("..")
    end

    # True when the value has visible text.
    def present?(value)
      !value.nil? && !value.to_s.strip.empty?
    end

    # The value as stripped text, or nil when it is blank.
    def text(value)
      present?(value) ? value.to_s.strip : nil
    end
  end
end
