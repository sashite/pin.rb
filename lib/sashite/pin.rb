# frozen_string_literal: true

require_relative "pin/constants"
require_relative "pin/errors"
require_relative "pin/identifier"
require_relative "pin/parser"

module Sashite
  # PIN (Piece Identifier Notation) — fast, flyweight implementation for Ruby.
  #
  # PIN has a closed domain of exactly 312 valid tokens
  # (26 letters × 2 sides × 3 states × 2 terminal).
  # All instances are pre-built and frozen at load time.
  # Every public method returns a cached object — zero allocation on the hot path.
  #
  # == Entry points
  #
  #   Pin.parse(string)       → Identifier (raises on error)
  #   Pin.safe_parse(string)  → Identifier | nil
  #   Pin.fetch(abbr, side, …) → Identifier (raises on error)
  #   Pin.valid?(string)      → Boolean
  #
  # @see https://sashite.dev/specs/pin/1.0.0/
  module Pin
    # Parses a PIN string into a cached Identifier.
    # Raises ArgumentError if the string is not valid.
    #
    # @param string [String] PIN string (1-3 ASCII characters)
    # @return [Identifier] A pre-instantiated, frozen Identifier
    # @raise [Errors::Argument] If the string is not a valid PIN
    #
    # @example
    #   Sashite::Pin.parse("K")   # => #<Sashite::Pin::Identifier K>
    #   Sashite::Pin.parse("+r")  # => #<Sashite::Pin::Identifier +r>
    #   Sashite::Pin.parse("K^")  # => #<Sashite::Pin::Identifier K^>
    def self.parse(string)
      result = Parser.safe_parse(string)

      if result
        Identifier.fetch(result[:abbr], result[:side], result[:state], terminal: result[:terminal])
      else
        # Slow path: re-parse with diagnostics to raise specific error
        Parser.parse(string)
      end
    end

    # Parses a PIN string without raising.
    # Returns a cached Identifier on success, nil on failure.
    # Never allocates exception objects or captures backtraces.
    #
    # @param string [String] PIN string
    # @return [Identifier, nil]
    #
    # @example
    #   Sashite::Pin.safe_parse("K")       # => #<Sashite::Pin::Identifier K>
    #   Sashite::Pin.safe_parse("+R^")     # => #<Sashite::Pin::Identifier +R^>
    #   Sashite::Pin.safe_parse("")         # => nil
    #   Sashite::Pin.safe_parse("invalid") # => nil
    #   Sashite::Pin.safe_parse(nil)       # => nil
    def self.safe_parse(string)
      result = Parser.safe_parse(string)
      return unless result

      Identifier.fetch(result[:abbr], result[:side], result[:state], terminal: result[:terminal])
    end

    # Retrieves a cached Identifier by components.
    # Bypasses string parsing entirely — direct pool lookup.
    # Raises ArgumentError if components are invalid.
    #
    # @param abbr [Symbol] Piece abbreviation (:A through :Z)
    # @param side [Symbol] Piece side (:first or :second)
    # @param state [Symbol] Piece state (:normal, :enhanced, or :diminished)
    # @param terminal [Boolean] Terminal status
    # @return [Identifier]
    # @raise [Errors::Argument] If any component is invalid
    #
    # @example
    #   Sashite::Pin.fetch(:K, :first)                              # => #<Sashite::Pin::Identifier K>
    #   Sashite::Pin.fetch(:R, :second, :enhanced)                  # => #<Sashite::Pin::Identifier +r>
    #   Sashite::Pin.fetch(:K, :first, :normal, terminal: true)     # => #<Sashite::Pin::Identifier K^>
    def self.fetch(abbr, side, state = :normal, terminal: false)
      Identifier.fetch(abbr, side, state, terminal: terminal)
    end

    # Reports whether a string is a valid PIN token.
    # Never raises; returns false for any invalid input.
    # Uses the exception-free code path internally.
    #
    # @param string [String] PIN string
    # @return [Boolean]
    #
    # @example
    #   Sashite::Pin.valid?("K")        # => true
    #   Sashite::Pin.valid?("+R")       # => true
    #   Sashite::Pin.valid?("K^")       # => true
    #   Sashite::Pin.valid?("invalid")  # => false
    #   Sashite::Pin.valid?(nil)        # => false
    def self.valid?(string)
      Parser.valid?(string)
    end
  end
end
