# frozen_string_literal: true

module Sashite
  module Pin
    # Represents a piece in PIN (Piece Identifier Notation) format.
    #
    # A piece consists of a single ASCII letter with optional state modifiers:
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
    class Piece
      # PIN validation pattern matching the specification
      PIN_PATTERN = /\A(?<prefix>[-+])?(?<letter>[a-zA-Z])\z/

      # Valid state modifiers
      ENHANCED_PREFIX = "+"
      DIMINISHED_PREFIX = "-"
      NORMAL_PREFIX = ""

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

      # Create a new piece instance
      #
      # @param type [Symbol] piece type (:A to :Z)
      # @param side [Symbol] player side (:first or :second)
      # @param state [Symbol] piece state (:normal, :enhanced, or :diminished)
      # @raise [ArgumentError] if parameters are invalid
      def initialize(type, side, state = NORMAL_STATE)
        self.class.validate_type(type)
        self.class.validate_side(side)
        self.class.validate_state(state)

        @type = type
        @side = side
        @state = state

        freeze
      end

      # Parse a PIN string into a Piece object
      #
      # @param pin_string [String] PIN notation string
      # @return [Piece] new piece instance
      # @raise [ArgumentError] if the PIN string is invalid
      # @example
      #   Pin::Piece.parse("k")     # => #<Pin::Piece type=:K side=:second state=:normal>
      #   Pin::Piece.parse("+R")    # => #<Pin::Piece type=:R side=:first state=:enhanced>
      #   Pin::Piece.parse("-p")    # => #<Pin::Piece type=:P side=:second state=:diminished>
      def self.parse(pin_string)
        string_value = String(pin_string)
        matches = match_pattern(string_value)

        letter = matches[:letter]
        enhanced = matches[:prefix] == ENHANCED_PREFIX
        diminished = matches[:prefix] == DIMINISHED_PREFIX

        # Extract type and side from letter
        piece_type = letter.upcase.to_sym
        piece_side = letter == letter.upcase ? FIRST_PLAYER : SECOND_PLAYER
        piece_state = if enhanced
                        ENHANCED_STATE
                      elsif diminished
                        DIMINISHED_STATE
                      else
                        NORMAL_STATE
                      end

        new(piece_type, piece_side, piece_state)
      end

      # Convert the piece to its PIN string representation
      #
      # @return [String] PIN notation string
      # @example
      #   piece.to_s  # => "+R"
      #   piece.to_s  # => "-p"
      #   piece.to_s  # => "K"
      def to_s
        "#{prefix}#{letter}"
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

      # Create a new piece with enhanced state
      #
      # @return [Piece] new piece instance with enhanced state
      # @example
      #   piece.enhance  # (:K, :first, :normal) => (:K, :first, :enhanced)
      def enhance
        return self if enhanced?

        self.class.new(type, side, ENHANCED_STATE)
      end

      # Create a new piece without enhanced state
      #
      # @return [Piece] new piece instance without enhanced state
      # @example
      #   piece.unenhance  # (:K, :first, :enhanced) => (:K, :first, :normal)
      def unenhance
        return self unless enhanced?

        self.class.new(type, side, NORMAL_STATE)
      end

      # Create a new piece with diminished state
      #
      # @return [Piece] new piece instance with diminished state
      # @example
      #   piece.diminish  # (:K, :first, :normal) => (:K, :first, :diminished)
      def diminish
        return self if diminished?

        self.class.new(type, side, DIMINISHED_STATE)
      end

      # Create a new piece without diminished state
      #
      # @return [Piece] new piece instance without diminished state
      # @example
      #   piece.undiminish  # (:K, :first, :diminished) => (:K, :first, :normal)
      def undiminish
        return self unless diminished?

        self.class.new(type, side, NORMAL_STATE)
      end

      # Create a new piece with normal state (no modifiers)
      #
      # @return [Piece] new piece instance with normal state
      # @example
      #   piece.normalize  # (:K, :first, :enhanced) => (:K, :first, :normal)
      def normalize
        return self if normal?

        self.class.new(type, side, NORMAL_STATE)
      end

      # Create a new piece with opposite ownership (case)
      #
      # @return [Piece] new piece instance with flipped case
      # @example
      #   piece.flip  # (:K, :first, :normal) => (:K, :second, :normal)
      def flip
        self.class.new(type, opposite_side, state)
      end

      # Create a new piece with a different type (keeping same side and state)
      #
      # @param new_type [Symbol] new type (:A to :Z)
      # @return [Piece] new piece instance with different type
      # @example
      #   piece.with_type(:Q)  # (:K, :first, :normal) => (:Q, :first, :normal)
      def with_type(new_type)
        self.class.validate_type(new_type)
        return self if type == new_type

        self.class.new(new_type, side, state)
      end

      # Create a new piece with a different side (keeping same type and state)
      #
      # @param new_side [Symbol] :first or :second
      # @return [Piece] new piece instance with different side
      # @example
      #   piece.with_side(:second)  # (:K, :first, :normal) => (:K, :second, :normal)
      def with_side(new_side)
        self.class.validate_side(new_side)
        return self if side == new_side

        self.class.new(type, new_side, state)
      end

      # Create a new piece with a different state (keeping same type and side)
      #
      # @param new_state [Symbol] :normal, :enhanced, or :diminished
      # @return [Piece] new piece instance with different state
      # @example
      #   piece.with_state(:enhanced)  # (:K, :first, :normal) => (:K, :first, :enhanced)
      def with_state(new_state)
        self.class.validate_state(new_state)
        return self if state == new_state

        self.class.new(type, side, new_state)
      end

      # Check if the piece has enhanced state
      #
      # @return [Boolean] true if enhanced
      def enhanced?
        state == ENHANCED_STATE
      end

      # Check if the piece has diminished state
      #
      # @return [Boolean] true if diminished
      def diminished?
        state == DIMINISHED_STATE
      end

      # Check if the piece has normal state (no modifiers)
      #
      # @return [Boolean] true if no modifiers are present
      def normal?
        state == NORMAL_STATE
      end

      # Check if the piece belongs to the first player
      #
      # @return [Boolean] true if first player
      def first_player?
        side == FIRST_PLAYER
      end

      # Check if the piece belongs to the second player
      #
      # @return [Boolean] true if second player
      def second_player?
        side == SECOND_PLAYER
      end

      # Check if this piece is the same type as another (ignoring side and state)
      #
      # @param other [Piece] piece to compare with
      # @return [Boolean] true if same type
      # @example
      #   king1.same_type?(king2)  # (:K, :first, :normal) and (:K, :second, :enhanced) => true
      def same_type?(other)
        return false unless other.is_a?(self.class)

        type == other.type
      end

      # Check if this piece belongs to the same side as another
      #
      # @param other [Piece] piece to compare with
      # @return [Boolean] true if same side
      def same_side?(other)
        return false unless other.is_a?(self.class)

        side == other.side
      end

      # Check if this piece has the same state as another
      #
      # @param other [Piece] piece to compare with
      # @return [Boolean] true if same state
      def same_state?(other)
        return false unless other.is_a?(self.class)

        state == other.state
      end

      # Custom equality comparison
      #
      # @param other [Object] object to compare with
      # @return [Boolean] true if pieces are equal
      def ==(other)
        return false unless other.is_a?(self.class)

        type == other.type && side == other.side && state == other.state
      end

      # Alias for == to ensure Set functionality works correctly
      alias eql? ==

      # Custom hash implementation for use in collections
      #
      # @return [Integer] hash value
      def hash
        [self.class, type, side, state].hash
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

      # Get the opposite side of the current piece
      #
      # @return [Symbol] :first if current side is :second, :second if current side is :first
      def opposite_side
        first_player? ? SECOND_PLAYER : FIRST_PLAYER
      end
    end
  end
end
