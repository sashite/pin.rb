# frozen_string_literal: true

module Sashite
  module Pin
    # Represents an identifier in PIN (Piece Identifier Notation) format.
    #
    # An identifier consists of a single ASCII letter with optional state modifiers:
    # - Enhanced state: prefix '+'
    # - Diminished state: prefix '-'
    # - Normal state: no modifier
    #
    # The case of the letter determines ownership:
    # - Uppercase (A-Z): first player
    # - Lowercase (a-z): second player
    #
    # All instances are immutable - state manipulation methods return new instances.
    # This follows the Game Protocol's piece model with Type, Side, and State attributes.
    class Identifier
      # PIN validation pattern matching the specification
      PIN_PATTERN = /\A(?<prefix>[-+])?(?<letter>[a-zA-Z])(?<terminal>\^)?\z/

      # Valid state modifiers
      ENHANCED_PREFIX = "+"
      DIMINISHED_PREFIX = "-"
      NORMAL_PREFIX = ""

      # Terminal marker
      TERMINAL_MARKER = "^"

      # State constants
      ENHANCED_STATE = :enhanced
      DIMINISHED_STATE = :diminished
      NORMAL_STATE = :normal

      # Player side constants
      FIRST_PLAYER = :first
      SECOND_PLAYER = :second

      # Valid types (A-Z)
      VALID_TYPES = (:A..:Z).to_a.freeze

      # Valid sides
      VALID_SIDES = [FIRST_PLAYER, SECOND_PLAYER].freeze

      # Valid states
      VALID_STATES = [NORMAL_STATE, ENHANCED_STATE, DIMINISHED_STATE].freeze

      # Error messages
      ERROR_INVALID_PIN = "Invalid PIN string: %s"
      ERROR_INVALID_TYPE = "Type must be a symbol from :A to :Z, got: %s"
      ERROR_INVALID_SIDE = "Side must be :first or :second, got: %s"
      ERROR_INVALID_STATE = "State must be :normal, :enhanced, or :diminished, got: %s"

      # @return [Symbol] the piece type (:A to :Z)
      attr_reader :type

      # @return [Symbol] the player side (:first or :second)
      attr_reader :side

      # @return [Symbol] the piece state (:normal, :enhanced, or :diminished)
      attr_reader :state

      # @return [Boolean] whether the piece is a terminal piece
      attr_reader :terminal

      # Create a new identifier instance
      #
      # @param type [Symbol] piece type (:A to :Z)
      # @param side [Symbol] player side (:first or :second)
      # @param state [Symbol] piece state (:normal, :enhanced, or :diminished)
      # @param terminal [Boolean] whether the piece is a terminal piece
      # @raise [ArgumentError] if parameters are invalid
      def initialize(type, side, state = NORMAL_STATE, terminal: false)
        self.class.validate_type(type)
        self.class.validate_side(side)
        self.class.validate_state(state)

        @type = type
        @side = side
        @state = state
        @terminal = !!terminal

        freeze
      end

      # Parse a PIN string into an Identifier object
      #
      # @param pin_string [String] PIN notation string
      # @return [Identifier] new identifier instance
      # @raise [ArgumentError] if the PIN string is invalid
      # @example
      #   Pin::Identifier.parse("k")     # => #<Pin::Identifier type=:K side=:second state=:normal terminal=false>
      #   Pin::Identifier.parse("+R")    # => #<Pin::Identifier type=:R side=:first state=:enhanced terminal=false>
      #   Pin::Identifier.parse("-p")    # => #<Pin::Identifier type=:P side=:second state=:diminished terminal=false>
      #   Pin::Identifier.parse("K^")    # => #<Pin::Identifier type=:K side=:first state=:normal terminal=true>
      #   Pin::Identifier.parse("+K^")   # => #<Pin::Identifier type=:K side=:first state=:enhanced terminal=true>
      def self.parse(pin_string)
        string_value = String(pin_string)
        matches = match_pattern(string_value)

        letter = matches[:letter]
        enhanced = matches[:prefix] == ENHANCED_PREFIX
        diminished = matches[:prefix] == DIMINISHED_PREFIX
        is_terminal = matches[:terminal] == TERMINAL_MARKER

        type = letter.upcase.to_sym
        side = letter == letter.upcase ? FIRST_PLAYER : SECOND_PLAYER
        state = if enhanced
                  ENHANCED_STATE
                elsif diminished
                  DIMINISHED_STATE
                else
                  NORMAL_STATE
                end

        new(type, side, state, terminal: is_terminal)
      end

      # Check if a string is a valid PIN notation
      #
      # @param pin_string [String] The string to validate
      # @return [Boolean] true if valid PIN, false otherwise
      #
      # @example
      #   Sashite::Pin::Identifier.valid?("K")    # => true
      #   Sashite::Pin::Identifier.valid?("+R")   # => true
      #   Sashite::Pin::Identifier.valid?("-p")   # => true
      #   Sashite::Pin::Identifier.valid?("KK")   # => false
      #   Sashite::Pin::Identifier.valid?("++K")  # => false
      def self.valid?(pin_string)
        return false unless pin_string.is_a?(::String)

        pin_string.match?(PIN_PATTERN)
      end

      # Convert the identifier to its PIN string representation
      #
      # @return [String] PIN notation string
      # @example
      #   identifier.to_s  # => "+R"
      #   terminal_king.to_s  # => "K^"
      #   enhanced_terminal.to_s  # => "+K^"
      def to_s
        "#{prefix}#{letter}#{suffix}"
      end

      # Get the letter representation
      #
      # @return [String] letter representation combining type and side
      def letter
        first_player? ? type.to_s.upcase : type.to_s.downcase
      end

      # Get the prefix representation
      #
      # @return [String] prefix representing the state
      def prefix
        case state
        when ENHANCED_STATE then ENHANCED_PREFIX
        when DIMINISHED_STATE then DIMINISHED_PREFIX
        else NORMAL_PREFIX
        end
      end

      # Get the suffix representation
      #
      # @return [String] suffix representing terminal status
      def suffix
        terminal? ? TERMINAL_MARKER : ""
      end

      # Create a new identifier with enhanced state
      #
      # @return [Identifier] new identifier instance with enhanced state
      def enhance
        return self if enhanced?

        self.class.new(type, side, ENHANCED_STATE, terminal: terminal)
      end

      # Create a new identifier without enhanced state
      #
      # @return [Identifier] new identifier instance with normal state
      def unenhance
        return self unless enhanced?

        self.class.new(type, side, NORMAL_STATE, terminal: terminal)
      end

      # Create a new identifier with diminished state
      #
      # @return [Identifier] new identifier instance with diminished state
      def diminish
        return self if diminished?

        self.class.new(type, side, DIMINISHED_STATE, terminal: terminal)
      end

      # Create a new identifier without diminished state
      #
      # @return [Identifier] new identifier instance with normal state
      def undiminish
        return self unless diminished?

        self.class.new(type, side, NORMAL_STATE, terminal: terminal)
      end

      # Create a new identifier with normal state (no modifiers)
      #
      # @return [Identifier] new identifier instance with normal state
      def normalize
        return self if normal?

        self.class.new(type, side, NORMAL_STATE, terminal: terminal)
      end

      # Create a new identifier marked as terminal
      #
      # @return [Identifier] new identifier instance marked as terminal
      def mark_terminal
        return self if terminal?

        self.class.new(type, side, state, terminal: true)
      end

      # Create a new identifier unmarked as terminal
      #
      # @return [Identifier] new identifier instance unmarked as terminal
      def unmark_terminal
        return self unless terminal?

        self.class.new(type, side, state, terminal: false)
      end

      # Create a new identifier with opposite side
      #
      # @return [Identifier] new identifier instance with opposite side
      def flip
        self.class.new(type, opposite_side, state, terminal: terminal)
      end

      # Create a new identifier with a different type
      #
      # @param new_type [Symbol] new type (:A to :Z)
      # @return [Identifier] new identifier instance with new type
      def with_type(new_type)
        self.class.validate_type(new_type)
        return self if type == new_type

        self.class.new(new_type, side, state, terminal: terminal)
      end

      # Create a new identifier with a different side
      #
      # @param new_side [Symbol] new side (:first or :second)
      # @return [Identifier] new identifier instance with new side
      def with_side(new_side)
        self.class.validate_side(new_side)
        return self if side == new_side

        self.class.new(type, new_side, state, terminal: terminal)
      end

      # Create a new identifier with a different state
      #
      # @param new_state [Symbol] new state (:normal, :enhanced, or :diminished)
      # @return [Identifier] new identifier instance with new state
      def with_state(new_state)
        self.class.validate_state(new_state)
        return self if state == new_state

        self.class.new(type, side, new_state, terminal: terminal)
      end

      # Create a new identifier with a different terminal status
      #
      # @param new_terminal [Boolean] new terminal status
      # @return [Identifier] new identifier instance with new terminal status
      def with_terminal(new_terminal)
        new_terminal_bool = !!new_terminal
        return self if terminal? == new_terminal_bool

        self.class.new(type, side, state, terminal: new_terminal_bool)
      end

      # Check if the identifier has enhanced state
      #
      # @return [Boolean] true if enhanced
      def enhanced?
        state == ENHANCED_STATE
      end

      # Check if the identifier has diminished state
      #
      # @return [Boolean] true if diminished
      def diminished?
        state == DIMINISHED_STATE
      end

      # Check if the identifier has normal state
      #
      # @return [Boolean] true if normal
      def normal?
        state == NORMAL_STATE
      end

      # Check if the identifier belongs to the first player
      #
      # @return [Boolean] true if first player
      def first_player?
        side == FIRST_PLAYER
      end

      # Check if the identifier belongs to the second player
      #
      # @return [Boolean] true if second player
      def second_player?
        side == SECOND_PLAYER
      end

      # Check if the identifier is a terminal piece
      #
      # @return [Boolean] true if terminal
      def terminal?
        terminal
      end

      # Check if this identifier is the same type as another
      #
      # @param other [Identifier] identifier to compare with
      # @return [Boolean] true if same type
      def same_type?(other)
        return false unless other.is_a?(self.class)

        type == other.type
      end

      # Check if this identifier has the same side as another
      #
      # @param other [Identifier] identifier to compare with
      # @return [Boolean] true if same side
      def same_side?(other)
        return false unless other.is_a?(self.class)

        side == other.side
      end

      # Check if this identifier has the same state as another
      #
      # @param other [Identifier] identifier to compare with
      # @return [Boolean] true if same state
      def same_state?(other)
        return false unless other.is_a?(self.class)

        state == other.state
      end

      # Check if this identifier has the same terminal status as another
      #
      # @param other [Identifier] identifier to compare with
      # @return [Boolean] true if same terminal status
      def same_terminal?(other)
        return false unless other.is_a?(self.class)

        terminal? == other.terminal?
      end

      # Custom equality comparison
      #
      # @param other [Object] object to compare with
      # @return [Boolean] true if identifiers are equal
      def ==(other)
        return false unless other.is_a?(self.class)

        type == other.type && side == other.side && state == other.state && terminal? == other.terminal?
      end

      # Alias for == to ensure Set functionality works correctly
      alias eql? ==

      # Custom hash implementation for use in collections
      #
      # @return [Integer] hash value
      def hash
        [self.class, type, side, state, terminal?].hash
      end

      # Validate that the type is a valid symbol
      #
      # @param type [Symbol] the type to validate
      # @raise [ArgumentError] if invalid
      def self.validate_type(type)
        return if VALID_TYPES.include?(type)

        raise ::ArgumentError, format(ERROR_INVALID_TYPE, type.inspect)
      end

      # Validate that the side is a valid symbol
      #
      # @param side [Symbol] the side to validate
      # @raise [ArgumentError] if invalid
      def self.validate_side(side)
        return if VALID_SIDES.include?(side)

        raise ::ArgumentError, format(ERROR_INVALID_SIDE, side.inspect)
      end

      # Validate that the state is a valid symbol
      #
      # @param state [Symbol] the state to validate
      # @raise [ArgumentError] if invalid
      def self.validate_state(state)
        return if VALID_STATES.include?(state)

        raise ::ArgumentError, format(ERROR_INVALID_STATE, state.inspect)
      end

      # Match PIN pattern against string
      #
      # @param string [String] string to match
      # @return [MatchData] match data
      # @raise [ArgumentError] if string doesn't match
      def self.match_pattern(string)
        matches = PIN_PATTERN.match(string)
        return matches if matches

        raise ::ArgumentError, format(ERROR_INVALID_PIN, string)
      end

      private_class_method :match_pattern

      private

      # Get the opposite side of the current identifier
      #
      # @return [Symbol] :first if current side is :second, :second if current side is :first
      def opposite_side
        first_player? ? SECOND_PLAYER : FIRST_PLAYER
      end
    end
  end
end
