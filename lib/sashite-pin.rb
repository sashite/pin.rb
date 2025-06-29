# frozen_string_literal: true

# Sashité namespace for board game notation libraries
module Sashite
  # Piece Identifier Notation (PIN) implementation for Ruby
  #
  # PIN provides an ASCII-based format for representing pieces in abstract
  # strategy board games. PIN translates piece attributes from the Game Protocol
  # into a compact, portable notation system using ASCII letters with optional
  # state modifiers and case-based player group classification.
  #
  # Format: [<state>]<letter>
  # - State modifier: "+" (enhanced), "-" (diminished), or none (normal)
  # - Letter: A-Z (first player), a-z (second player)
  #
  # @see https://sashite.dev/specs/pin/1.0.0/ PIN Specification v1.0.0
  # @author Sashité
end

require_relative "sashite/pin"
