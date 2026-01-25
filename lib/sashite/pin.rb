# frozen_string_literal: true

require_relative "pin/constants"
require_relative "pin/errors"
require_relative "pin/identifier"
require_relative "pin/parser"

module Sashite
  # PIN (Piece Identifier Notation) implementation for Ruby.
  #
  # PIN provides an ASCII-based format for representing pieces in abstract strategy
  # board games. It translates piece attributes from the Game Protocol into a compact,
  # portable notation system.
  #
  # == Format
  #
  #   [<state-modifier>]<letter>[<terminal-marker>]
  #
  # - *Letter* (+A-Z+, +a-z+): Piece name abbreviation and side
  # - *State modifier*: <tt>+</tt> (enhanced), <tt>-</tt> (diminished), or none (normal)
  # - *Terminal marker*: <tt>^</tt> (terminal piece) or none
  #
  # == Attributes
  #
  # A PIN token encodes exactly these attributes:
  #
  # - *Piece Name* → one ASCII letter chosen by the Game / Rule System
  # - *Piece Side* → the case of that letter (uppercase = first, lowercase = second)
  # - *Piece State* → an optional prefix (<tt>+</tt> for enhanced, <tt>-</tt> for diminished)
  # - *Terminal status* → an optional suffix (<tt>^</tt>)
  #
  # == Examples
  #
  #   pin = Sashite::Pin.parse("K")
  #   pin.abbr       # => :K
  #   pin.side       # => :first
  #   pin.state      # => :normal
  #   pin.terminal?  # => false
  #
  #   pin = Sashite::Pin.parse("+R")
  #   pin.to_s  # => "+R"
  #
  #   pin = Sashite::Pin.parse("k^")
  #   pin.terminal?  # => true
  #
  #   Sashite::Pin.valid?("K^")      # => true
  #   Sashite::Pin.valid?("invalid") # => false
  #
  # @see https://sashite.dev/specs/pin/1.0.0/
  module Pin
    # Parses a PIN string into an Identifier.
    #
    # @param string [String] The PIN string to parse
    # @return [Identifier] A new Identifier instance
    # @raise [Errors::Argument] If the string is not a valid PIN
    #
    # @example
    #   Sashite::Pin.parse("K")
    #   # => #<Sashite::Pin::Identifier K>
    #
    #   Sashite::Pin.parse("+r")
    #   # => #<Sashite::Pin::Identifier +r>
    #
    #   Sashite::Pin.parse("K^")
    #   # => #<Sashite::Pin::Identifier K^>
    #
    #   Sashite::Pin.parse("invalid")
    #   # => raises Errors::Argument
    def self.parse(string)
      components = Parser.parse(string)

      Identifier.new(
        components[:abbr],
        components[:side],
        components[:state],
        terminal: components[:terminal]
      )
    end

    # Checks if a string is a valid PIN notation.
    #
    # @param string [String] The string to validate
    # @return [Boolean] true if valid, false otherwise
    #
    # @example
    #   Sashite::Pin.valid?("K")        # => true
    #   Sashite::Pin.valid?("+R")       # => true
    #   Sashite::Pin.valid?("K^")       # => true
    #   Sashite::Pin.valid?("invalid")  # => false
    def self.valid?(string)
      Parser.valid?(string)
    end
  end
end
