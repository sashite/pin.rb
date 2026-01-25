# frozen_string_literal: true

require_relative "constants"
require_relative "errors"

module Sashite
  module Pin
    # Represents a parsed PIN (Piece Identifier Notation) identifier.
    #
    # An Identifier encodes four attributes of a piece:
    # - Abbr: the piece name abbreviation (A-Z as uppercase symbol)
    # - Side: the piece side (:first or :second)
    # - State: the piece state (:normal, :enhanced, or :diminished)
    # - Terminal: whether the piece is terminal (true or false)
    #
    # Instances are immutable (frozen after creation).
    #
    # @example Creating identifiers
    #   pin = Identifier.new(:K, :first)
    #   pin = Identifier.new(:R, :second, :enhanced)
    #   pin = Identifier.new(:K, :first, :normal, terminal: true)
    #
    # @example String conversion
    #   Identifier.new(:K, :first).to_s                          # => "K"
    #   Identifier.new(:R, :second, :enhanced).to_s              # => "+r"
    #   Identifier.new(:K, :first, :normal, terminal: true).to_s # => "K^"
    #
    # @see https://sashite.dev/specs/pin/1.0.0/
    class Identifier
      # @return [Symbol] Piece name abbreviation (:A to :Z, always uppercase)
      attr_reader :abbr

      # @return [Symbol] Piece side (:first or :second)
      attr_reader :side

      # @return [Symbol] Piece state (:normal, :enhanced, or :diminished)
      attr_reader :state

      # Creates a new Identifier instance.
      #
      # @param abbr [Symbol] Piece name abbreviation (:A to :Z)
      # @param side [Symbol] Piece side (:first or :second)
      # @param state [Symbol] Piece state (:normal, :enhanced, or :diminished)
      # @param terminal [Boolean] Terminal status
      # @return [Identifier] A new frozen Identifier instance
      # @raise [Errors::Argument] If any attribute is invalid
      #
      # @example
      #   Identifier.new(:K, :first)
      #   Identifier.new(:R, :second, :enhanced)
      #   Identifier.new(:K, :first, :normal, terminal: true)
      def initialize(abbr, side, state = :normal, terminal: false)
        validate_abbr!(abbr)
        validate_side!(side)
        validate_state!(state)
        validate_terminal!(terminal)

        @abbr = abbr
        @side = side
        @state = state
        @terminal = terminal

        freeze
      end

      # Returns the terminal status.
      #
      # @return [Boolean] true if terminal piece, false otherwise
      #
      # @example
      #   Identifier.new(:K, :first).terminal?                          # => false
      #   Identifier.new(:K, :first, :normal, terminal: true).terminal? # => true
      def terminal?
        @terminal
      end

      # ========================================================================
      # String Conversion
      # ========================================================================

      # Returns the PIN string representation.
      #
      # @return [String] The PIN string
      #
      # @example
      #   Identifier.new(:K, :first).to_s                          # => "K"
      #   Identifier.new(:R, :second, :enhanced).to_s              # => "+r"
      #   Identifier.new(:K, :first, :normal, terminal: true).to_s # => "K^"
      def to_s
        "#{prefix}#{letter}#{suffix}"
      end

      # Returns the letter component of the PIN.
      #
      # @return [String] Uppercase for first player, lowercase for second
      #
      # @example
      #   Identifier.new(:K, :first).letter  # => "K"
      #   Identifier.new(:K, :second).letter # => "k"
      def letter
        case side
        when :first then String(abbr.upcase)
        when :second then String(abbr.downcase)
        end
      end

      # Returns the state prefix of the PIN.
      #
      # @return [String] "+" for enhanced, "-" for diminished, "" for normal
      #
      # @example
      #   Identifier.new(:K, :first, :enhanced).prefix   # => "+"
      #   Identifier.new(:K, :first, :diminished).prefix # => "-"
      #   Identifier.new(:K, :first, :normal).prefix     # => ""
      def prefix
        case state
        when :enhanced then Constants::ENHANCED_PREFIX
        when :diminished then Constants::DIMINISHED_PREFIX
        else Constants::EMPTY_STRING
        end
      end

      # Returns the terminal suffix of the PIN.
      #
      # @return [String] "^" if terminal, "" otherwise
      #
      # @example
      #   Identifier.new(:K, :first, :normal, terminal: true).suffix # => "^"
      #   Identifier.new(:K, :first).suffix                          # => ""
      def suffix
        terminal? ? Constants::TERMINAL_SUFFIX : Constants::EMPTY_STRING
      end

      # ========================================================================
      # State Transformations
      # ========================================================================

      # Returns a new Identifier with enhanced state.
      #
      # @return [Identifier] A new Identifier with :enhanced state
      #
      # @example
      #   pin = Identifier.new(:K, :first)
      #   pin.enhance.to_s # => "+K"
      def enhance
        return self if enhanced?

        self.class.new(abbr, side, :enhanced, terminal: terminal?)
      end

      # Returns a new Identifier with diminished state.
      #
      # @return [Identifier] A new Identifier with :diminished state
      #
      # @example
      #   pin = Identifier.new(:K, :first)
      #   pin.diminish.to_s # => "-K"
      def diminish
        return self if diminished?

        self.class.new(abbr, side, :diminished, terminal: terminal?)
      end

      # Returns a new Identifier with normal state.
      #
      # @return [Identifier] A new Identifier with :normal state
      #
      # @example
      #   pin = Identifier.new(:K, :first, :enhanced)
      #   pin.normalize.to_s # => "K"
      def normalize
        return self if normal?

        self.class.new(abbr, side, :normal, terminal: terminal?)
      end

      # ========================================================================
      # Side Transformations
      # ========================================================================

      # Returns a new Identifier with the opposite side.
      #
      # @return [Identifier] A new Identifier with flipped side
      #
      # @example
      #   pin = Identifier.new(:K, :first)
      #   pin.flip.to_s # => "k"
      def flip
        new_side = first_player? ? :second : :first
        self.class.new(abbr, new_side, state, terminal: terminal?)
      end

      # ========================================================================
      # Terminal Transformations
      # ========================================================================

      # Returns a new Identifier marked as terminal.
      #
      # @return [Identifier] A new Identifier with terminal: true
      #
      # @example
      #   pin = Identifier.new(:K, :first)
      #   pin.terminal.to_s # => "K^"
      def terminal
        return self if terminal?

        self.class.new(abbr, side, state, terminal: true)
      end

      # Returns a new Identifier unmarked as terminal.
      #
      # @return [Identifier] A new Identifier with terminal: false
      #
      # @example
      #   pin = Identifier.new(:K, :first, :normal, terminal: true)
      #   pin.non_terminal.to_s # => "K"
      def non_terminal
        return self unless terminal?

        self.class.new(abbr, side, state, terminal: false)
      end

      # ========================================================================
      # Attribute Transformations
      # ========================================================================

      # Returns a new Identifier with a different abbreviation.
      #
      # @param new_abbr [Symbol] The new piece name abbreviation (:A to :Z)
      # @return [Identifier] A new Identifier with the specified abbreviation
      # @raise [Errors::Argument] If the abbreviation is invalid
      #
      # @example
      #   pin = Identifier.new(:K, :first)
      #   pin.with_abbr(:Q).to_s # => "Q"
      def with_abbr(new_abbr)
        return self if abbr.equal?(new_abbr)

        self.class.new(new_abbr, side, state, terminal: terminal?)
      end

      # Returns a new Identifier with a different side.
      #
      # @param new_side [Symbol] The new side (:first or :second)
      # @return [Identifier] A new Identifier with the specified side
      # @raise [Errors::Argument] If the side is invalid
      #
      # @example
      #   pin = Identifier.new(:K, :first)
      #   pin.with_side(:second).to_s # => "k"
      def with_side(new_side)
        return self if side.equal?(new_side)

        self.class.new(abbr, new_side, state, terminal: terminal?)
      end

      # Returns a new Identifier with a different state.
      #
      # @param new_state [Symbol] The new state (:normal, :enhanced, or :diminished)
      # @return [Identifier] A new Identifier with the specified state
      # @raise [Errors::Argument] If the state is invalid
      #
      # @example
      #   pin = Identifier.new(:K, :first)
      #   pin.with_state(:enhanced).to_s # => "+K"
      def with_state(new_state)
        return self if state.equal?(new_state)

        self.class.new(abbr, side, new_state, terminal: terminal?)
      end

      # Returns a new Identifier with a different terminal status.
      #
      # @param new_terminal [Boolean] The new terminal status
      # @return [Identifier] A new Identifier with the specified terminal status
      # @raise [Errors::Argument] If the terminal is not a boolean
      #
      # @example
      #   pin = Identifier.new(:K, :first)
      #   pin.with_terminal(true).to_s # => "K^"
      def with_terminal(new_terminal)
        return self if terminal?.equal?(new_terminal)

        self.class.new(abbr, side, state, terminal: new_terminal)
      end

      # ========================================================================
      # State Queries
      # ========================================================================

      # Checks if the Identifier has normal state.
      #
      # @return [Boolean] true if normal state
      #
      # @example
      #   Identifier.new(:K, :first).normal? # => true
      def normal?
        state.equal?(:normal)
      end

      # Checks if the Identifier has enhanced state.
      #
      # @return [Boolean] true if enhanced state
      #
      # @example
      #   Identifier.new(:K, :first, :enhanced).enhanced? # => true
      def enhanced?
        state.equal?(:enhanced)
      end

      # Checks if the Identifier has diminished state.
      #
      # @return [Boolean] true if diminished state
      #
      # @example
      #   Identifier.new(:K, :first, :diminished).diminished? # => true
      def diminished?
        state.equal?(:diminished)
      end

      # ========================================================================
      # Side Queries
      # ========================================================================

      # Checks if the Identifier belongs to the first player.
      #
      # @return [Boolean] true if first player
      #
      # @example
      #   Identifier.new(:K, :first).first_player? # => true
      def first_player?
        side.equal?(:first)
      end

      # Checks if the Identifier belongs to the second player.
      #
      # @return [Boolean] true if second player
      #
      # @example
      #   Identifier.new(:K, :second).second_player? # => true
      def second_player?
        side.equal?(:second)
      end

      # ========================================================================
      # Comparison Queries
      # ========================================================================

      # Checks if two Identifiers have the same abbreviation.
      #
      # @param other [Identifier] The other Identifier to compare
      # @return [Boolean] true if same abbreviation
      #
      # @example
      #   pin1 = Identifier.new(:K, :first)
      #   pin2 = Identifier.new(:K, :second)
      #   pin1.same_abbr?(pin2) # => true
      def same_abbr?(other)
        abbr.equal?(other.abbr)
      end

      # Checks if two Identifiers have the same side.
      #
      # @param other [Identifier] The other Identifier to compare
      # @return [Boolean] true if same side
      #
      # @example
      #   pin1 = Identifier.new(:K, :first)
      #   pin2 = Identifier.new(:Q, :first)
      #   pin1.same_side?(pin2) # => true
      def same_side?(other)
        side.equal?(other.side)
      end

      # Checks if two Identifiers have the same state.
      #
      # @param other [Identifier] The other Identifier to compare
      # @return [Boolean] true if same state
      #
      # @example
      #   pin1 = Identifier.new(:K, :first, :enhanced)
      #   pin2 = Identifier.new(:Q, :second, :enhanced)
      #   pin1.same_state?(pin2) # => true
      def same_state?(other)
        state.equal?(other.state)
      end

      # Checks if two Identifiers have the same terminal status.
      #
      # @param other [Identifier] The other Identifier to compare
      # @return [Boolean] true if same terminal status
      #
      # @example
      #   pin1 = Identifier.new(:K, :first, :normal, terminal: true)
      #   pin2 = Identifier.new(:Q, :second, :normal, terminal: true)
      #   pin1.same_terminal?(pin2) # => true
      def same_terminal?(other)
        terminal?.equal?(other.terminal?)
      end

      # ========================================================================
      # Equality
      # ========================================================================

      # Checks equality with another Identifier.
      #
      # @param other [Object] The object to compare
      # @return [Boolean] true if equal
      def ==(other)
        return false unless self.class === other

        abbr.equal?(other.abbr) &&
          side.equal?(other.side) &&
          state.equal?(other.state) &&
          terminal?.equal?(other.terminal?)
      end

      alias eql? ==

      # Returns a hash code for the Identifier.
      #
      # @return [Integer] Hash code
      def hash
        [abbr, side, state, terminal?].hash
      end

      # Returns an inspect string for the Identifier.
      #
      # @return [String] Inspect representation
      def inspect
        "#<#{self.class} #{self}>"
      end

      private

      # ========================================================================
      # Private Validation
      # ========================================================================

      def validate_abbr!(abbr)
        return if Constants::VALID_ABBRS.include?(abbr)

        raise Errors::Argument, Errors::Argument::Messages::INVALID_ABBR
      end

      def validate_side!(side)
        return if Constants::VALID_SIDES.include?(side)

        raise Errors::Argument, Errors::Argument::Messages::INVALID_SIDE
      end

      def validate_state!(state)
        return if Constants::VALID_STATES.include?(state)

        raise Errors::Argument, Errors::Argument::Messages::INVALID_STATE
      end

      def validate_terminal!(terminal)
        return if ::TrueClass === terminal || ::FalseClass === terminal

        raise Errors::Argument, Errors::Argument::Messages::INVALID_TERMINAL
      end
    end
  end
end
