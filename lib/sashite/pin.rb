# frozen_string_literal: true

require_relative "pin/piece"

module Sashite
  # PIN (Piece Identifier Notation) implementation for Ruby
  #
  # Provides ASCII-based format for representing pieces in abstract strategy board games.
  # PIN translates piece attributes from the Game Protocol into a compact, portable notation system.
  #
  # Format: [<state>]<letter>
  # - State modifier: "+" (enhanced), "-" (diminished), or none (normal)
  # - Letter: A-Z (first player), a-z (second player)
  #
  # Examples:
  #   "K"  - First player king (normal state)
  #   "k"  - Second player king (normal state)
  #   "+R" - First player rook (enhanced state)
  #   "-p" - Second player pawn (diminished state)
  #
  # See: https://sashite.dev/specs/pin/1.0.0/
  module Pin
    # Regular expression for PIN validation
    # Matches: optional state modifier followed by a single letter
    PIN_REGEX = /\A[-+]?[A-Za-z]\z/

    # Check if a string is a valid PIN notation
    #
    # @param pin [String] The string to validate
    # @return [Boolean] true if valid PIN, false otherwise
    #
    # @example
    #   Sashite::Pin.valid?("K")    # => true
    #   Sashite::Pin.valid?("+R")   # => true
    #   Sashite::Pin.valid?("-p")   # => true
    #   Sashite::Pin.valid?("KK")   # => false
    #   Sashite::Pin.valid?("++K")  # => false
    def self.valid?(pin)
      return false unless pin.is_a?(::String)

      pin.match?(PIN_REGEX)
    end

    # Parse a PIN string into a Piece object
    #
    # @param pin_string [String] PIN notation string
    # @return [Pin::Piece] new piece instance
    # @raise [ArgumentError] if the PIN string is invalid
    # @example
    #   Sashite::Pin.parse("K")     # => #<Pin::Piece letter="K">
    #   Sashite::Pin.parse("+R")    # => #<Pin::Piece letter="R" enhanced=true>
    def self.parse(pin_string)
      Piece.parse(pin_string)
    end
  end
end
