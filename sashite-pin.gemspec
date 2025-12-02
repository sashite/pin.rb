# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name    = "sashite-pin"
  spec.version = ::File.read("VERSION.semver").chomp
  spec.author  = "Cyril Kato"
  spec.email   = "contact@cyril.email"
  spec.summary = "PIN (Piece Identifier Notation) implementation for Ruby with immutable identifier objects"

  spec.description = <<~DESC
    PIN (Piece Identifier Notation) provides a rule-agnostic format for identifying pieces
    in abstract strategy board games. This gem implements the PIN Specification v1.0.0 with
    a modern Ruby interface featuring immutable identifier objects and functional programming
    principles. PIN uses single ASCII letters with optional state modifiers, terminal markers,
    and case-based side encoding (A-Z for first player, a-z for second player), enabling
    precise and portable identification of pieces across multiple games. Perfect for game
    engines, board game notation systems, and hybrid gaming platforms requiring compact,
    stateful piece representation.
  DESC

  spec.homepage               = "https://github.com/sashite/pin.rb"
  spec.license                = "MIT"
  spec.files                  = ::Dir["LICENSE.md", "README.md", "lib/**/*"]
  spec.required_ruby_version  = ">= 3.2.0"

  spec.metadata = {
    "bug_tracker_uri"       => "https://github.com/sashite/pin.rb/issues",
    "documentation_uri"     => "https://rubydoc.info/github/sashite/pin.rb/main",
    "homepage_uri"          => "https://github.com/sashite/pin.rb",
    "source_code_uri"       => "https://github.com/sashite/pin.rb",
    "specification_uri"     => "https://sashite.dev/specs/pin/1.0.0/",
    "rubygems_mfa_required" => "true"
  }
end
