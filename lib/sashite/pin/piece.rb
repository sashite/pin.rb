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

      # Error messages
      ERROR_INVALID_PIN = "Invalid PIN string: %s"
      ERROR_INVALID_LETTER = "Letter must be a single ASCII letter (a-z or A-Z): %s"

      # @return [String] the base letter identifier (type + side)
      attr_reader :letter

      # Create a new piece instance
      #
      # @param letter [String] single ASCII letter (a-z or A-Z)
      # @param enhanced [Boolean] whether the piece has enhanced state
      # @param diminished [Boolean] whether the piece has diminished state
      # @raise [ArgumentError] if parameters are invalid
      def initialize(letter, enhanced: false, diminished: false)
        self.class.validate_letter(letter)
        self.class.validate_state_combination(enhanced, diminished)

        @letter = letter.freeze
        @enhanced = enhanced
        @diminished = diminished

        freeze
      end

      # Parse a PIN string into a Piece object
      #
      # @param pin_string [String] PIN notation string
      # @return [Piece] new piece instance
      # @raise [ArgumentError] if the PIN string is invalid
      # @example
      #   Pin::Piece.parse("k")     # => #<Pin::Piece letter="k">
      #   Pin::Piece.parse("+R")    # => #<Pin::Piece letter="R" enhanced=true>
      #   Pin::Piece.parse("-p")    # => #<Pin::Piece letter="p" diminished=true>
      def self.parse(pin_string)
        string_value = String(pin_string)
        matches = match_pattern(string_value)

        letter = matches[:letter]
        enhanced = matches[:prefix] == ENHANCED_PREFIX
        diminished = matches[:prefix] == DIMINISHED_PREFIX

        new(
          letter,
          enhanced:   enhanced,
          diminished: diminished
        )
      end

      # Convert the piece to its PIN string representation
      #
      # @return [String] PIN notation string
      # @example
      #   piece.to_s  # => "+R"
      #   piece.to_s  # => "-p"
      #   piece.to_s  # => "K"
      def to_s
        prefix = if @enhanced
                   ENHANCED_PREFIX
                 else
                   (@diminished ? DIMINISHED_PREFIX : "")
                 end
        "#{prefix}#{letter}"
      end

      # Create a new piece with enhanced state
      #
      # @return [Piece] new piece instance with enhanced state
      # @example
      #   piece.enhance  # k => +k
      def enhance
        return self if enhanced?

        self.class.new(
          letter,
          enhanced:   true,
          diminished: false
        )
      end

      # Create a new piece without enhanced state
      #
      # @return [Piece] new piece instance without enhanced state
      # @example
      #   piece.unenhance  # +k => k
      def unenhance
        return self unless enhanced?

        self.class.new(
          letter,
          enhanced:   false,
          diminished: @diminished
        )
      end

      # Create a new piece with diminished state
      #
      # @return [Piece] new piece instance with diminished state
      # @example
      #   piece.diminish  # k => -k
      def diminish
        return self if diminished?

        self.class.new(
          letter,
          enhanced:   false,
          diminished: true
        )
      end

      # Create a new piece without diminished state
      #
      # @return [Piece] new piece instance without diminished state
      # @example
      #   piece.undiminish  # -k => k
      def undiminish
        return self unless diminished?

        self.class.new(
          letter,
          enhanced:   @enhanced,
          diminished: false
        )
      end

      # Create a new piece with normal state (no modifiers)
      #
      # @return [Piece] new piece instance with normal state
      # @example
      #   piece.normalize  # +k => k, -k => k
      def normalize
        return self if normal?

        self.class.new(letter)
      end

      # Create a new piece with opposite ownership (case)
      #
      # @return [Piece] new piece instance with flipped case
      # @example
      #   piece.flip  # K => k, k => K
      def flip
        flipped_letter = letter.swapcase

        self.class.new(
          flipped_letter,
          enhanced:   @enhanced,
          diminished: @diminished
        )
      end

      # Check if the piece has enhanced state
      #
      # @return [Boolean] true if enhanced
      def enhanced?
        @enhanced
      end

      # Check if the piece has diminished state
      #
      # @return [Boolean] true if diminished
      def diminished?
        @diminished
      end

      # Check if the piece has normal state (no modifiers)
      #
      # @return [Boolean] true if no modifiers are present
      def normal?
        !enhanced? && !diminished?
      end

      # Check if the piece belongs to the first player (uppercase)
      #
      # @return [Boolean] true if uppercase letter
      def first_player?
        letter == letter.upcase
      end

      # Check if the piece belongs to the second player (lowercase)
      #
      # @return [Boolean] true if lowercase letter
      def second_player?
        letter == letter.downcase
      end

      # Get the piece type (uppercase letter regardless of player)
      #
      # @return [String] uppercase letter representing the piece type
      # @example
      #   piece.type  # "k" => "K", "R" => "R", "+p" => "P"
      def type
        letter.upcase
      end

      # Get the player side based on letter case
      #
      # @return [Symbol] :first or :second
      def side
        first_player? ? :first : :second
      end

      # Get the state as a symbol
      #
      # @return [Symbol] :enhanced, :diminished, or :normal
      def state
        return :enhanced if enhanced?
        return :diminished if diminished?
        :normal
      end

      # Check if this piece is the same type as another (ignoring player and state)
      #
      # @param other [Piece] piece to compare with
      # @return [Boolean] true if same type
      # @example
      #   king1.same_type?(king2)  # K and k => true, K and Q => false
      def same_type?(other)
        return false unless other.is_a?(self.class)
        type == other.type
      end

      # Check if this piece belongs to the same player as another
      #
      # @param other [Piece] piece to compare with
      # @return [Boolean] true if same player
      def same_player?(other)
        return false unless other.is_a?(self.class)
        side == other.side
      end

      # Custom equality comparison
      #
      # @param other [Object] object to compare with
      # @return [Boolean] true if pieces are equal
      def ==(other)
        return false unless other.is_a?(self.class)

        letter == other.letter &&
          enhanced? == other.enhanced? &&
          diminished? == other.diminished?
      end

      # Alias for == to ensure Set functionality works correctly
      alias eql? ==

      # Custom hash implementation for use in collections
      #
      # @return [Integer] hash value
      def hash
        [self.class, @letter, @enhanced, @diminished].hash
      end

      # Validate that the letter is a single ASCII letter
      #
      # @param letter [String] the letter to validate
      # @raise [ArgumentError] if invalid
      def self.validate_letter(letter)
        letter_str = String(letter)
        return if letter_str.match?(/\A[a-zA-Z]\z/)

        raise ::ArgumentError, format(ERROR_INVALID_LETTER, letter_str)
      end

      # Validate that enhanced and diminished states are not both true
      #
      # @param enhanced [Boolean] enhanced state
      # @param diminished [Boolean] diminished state
      # @raise [ArgumentError] if both are true
      def self.validate_state_combination(enhanced, diminished)
        return unless enhanced && diminished

        raise ::ArgumentError, "A piece cannot be both enhanced and diminished"
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
    end
  end
end
