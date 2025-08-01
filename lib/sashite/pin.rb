# frozen_string_literal: true

require_relative "pin/identifier"

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
  # @see https://sashite.dev/specs/pin/1.0.0/
  module Pin
    # Check if a string is a valid PIN notation
    #
    # @param pin_string [String] The string to validate
    # @return [Boolean] true if valid PIN, false otherwise
    #
    # @example
    #   Sashite::Pin.valid?("K")    # => true
    #   Sashite::Pin.valid?("+R")   # => true
    #   Sashite::Pin.valid?("-p")   # => true
    #   Sashite::Pin.valid?("KK")   # => false
    #   Sashite::Pin.valid?("++K")  # => false
    def self.valid?(pin_string)
      Identifier.valid?(pin_string)
    end

    # Parse a PIN string into an Identifier object
    #
    # @param pin_string [String] PIN notation string
    # @return [Pin::Identifier] new identifier instance
    # @raise [ArgumentError] if the PIN string is invalid
    # @example
    #   Sashite::Pin.parse("K")     # => #<Pin::Identifier type=:K side=:first state=:normal>
    #   Sashite::Pin.parse("+R")    # => #<Pin::Identifier type=:R side=:first state=:enhanced>
    #   Sashite::Pin.parse("-p")    # => #<Pin::Identifier type=:P side=:second state=:diminished>
    def self.parse(pin_string)
      Identifier.parse(pin_string)
    end

    # Create a new identifier instance
    #
    # @param type [Symbol] piece type (:A to :Z)
    # @param side [Symbol] player side (:first or :second)
    # @param state [Symbol] piece state (:normal, :enhanced, or :diminished)
    # @return [Pin::Identifier] new identifier instance
    # @raise [ArgumentError] if parameters are invalid
    # @example
    #   Sashite::Pin.identifier(:K, :first, :normal)     # => #<Pin::Identifier type=:K side=:first state=:normal>
    #   Sashite::Pin.identifier(:R, :first, :enhanced)   # => #<Pin::Identifier type=:R side=:first state=:enhanced>
    #   Sashite::Pin.identifier(:P, :second, :diminished) # => #<Pin::Identifier type=:P side=:second state=:diminished>
    def self.identifier(type, side, state)
      Identifier.new(type, side, state)
    end
  end
end
