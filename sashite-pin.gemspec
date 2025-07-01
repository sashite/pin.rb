# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name    = "sashite-pin"
  spec.version = ::File.read("VERSION.semver").chomp
  spec.author  = "Cyril Kato"
  spec.email   = "contact@cyril.email"
  spec.summary = "PIN (Piece Identifier Notation) implementation for Ruby with immutable piece objects"

  spec.description = <<~DESC
    PIN (Piece Identifier Notation) provides an ASCII-based format for representing pieces
    in abstract strategy board games. This gem implements the PIN Specification v1.0.0 with
    a modern Ruby interface featuring immutable piece objects and functional programming
    principles. PIN translates piece attributes from the Game Protocol into a compact,
    portable notation system using ASCII letters with optional state modifiers and
    case-based side encoding. Perfect for game engines, board game notation systems,
    and multi-game environments.
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
