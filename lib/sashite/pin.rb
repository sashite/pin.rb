# frozen_string_literal: true

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
  # - *Letter* (+A-Z+, +a-z+): Piece type and side
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
  #   pin.type      # => :K
  #   pin.side      # => :first
  #   pin.state     # => :normal
  #   pin.terminal  # => false
  #
  #   pin = Sashite::Pin.parse!("+R")
  #   pin.to_s  # => "+R"
  #
  #   pin = Sashite::Pin.parse("k^")
  #   pin.terminal  # => true
  #
  #   Sashite::Pin.valid?("K^")      # => true
  #   Sashite::Pin.valid?("invalid") # => false
  #
  # See the PIN Specification (https://sashite.dev/specs/pin/1.0.0/) for details.
  class Pin
    # Valid piece types (uppercase symbols)
    VALID_TYPES = %i[A B C D E F G H I J K L M N O P Q R S T U V W X Y Z].freeze

    # Valid sides
    VALID_SIDES = %i[first second].freeze

    # Valid states
    VALID_STATES = %i[normal enhanced diminished].freeze

    # Pattern for validating PIN strings
    PIN_PATTERN = /\A(?<prefix>[-+])?(?<letter>[a-zA-Z])(?<terminal>\^)?\z/

    # @return [Symbol] Piece type (:A to :Z, always uppercase)
    attr_reader :type

    # @return [Symbol] Player side (:first or :second)
    attr_reader :side

    # @return [Symbol] Piece state (:normal, :enhanced, or :diminished)
    attr_reader :state

    # @return [Boolean] Terminal status
    attr_reader :terminal

    # ========================================================================
    # Creation and Parsing
    # ========================================================================

    # Creates a new PIN instance.
    #
    # @param type [Symbol] Piece type (:A to :Z)
    # @param side [Symbol] Player side (:first or :second)
    # @param state [Symbol] Piece state (:normal, :enhanced, or :diminished)
    # @param terminal [Boolean] Terminal status
    # @return [Pin] A new frozen Pin instance
    #
    # @example
    #   Sashite::Pin.new(:K, :first)
    #   # => #<Sashite::Pin K>
    #
    #   Sashite::Pin.new(:R, :second, :enhanced)
    #   # => #<Sashite::Pin +r>
    #
    #   Sashite::Pin.new(:K, :first, :normal, terminal: true)
    #   # => #<Sashite::Pin K^>
    def initialize(type, side, state = :normal, terminal: false)
      validate_type!(type)
      validate_side!(side)
      validate_state!(state)

      @type = type
      @side = side
      @state = state
      @terminal = !!terminal

      freeze
    end

    # Parses a PIN string into a Pin instance.
    #
    # @param pin_string [String] The PIN string to parse
    # @return [Pin] A new Pin instance
    # @raise [ArgumentError] If the string is not a valid PIN
    #
    # @example
    #   Sashite::Pin.parse("K")
    #   # => #<Sashite::Pin K>
    #
    #   Sashite::Pin.parse("+r")
    #   # => #<Sashite::Pin +r>
    #
    #   Sashite::Pin.parse("K^")
    #   # => #<Sashite::Pin K^>
    #
    #   Sashite::Pin.parse("invalid")
    #   # => ArgumentError: Invalid PIN string: invalid
    def self.parse(pin_string)
      raise ArgumentError, "Invalid PIN string: #{pin_string.inspect}" unless pin_string.is_a?(String)

      match = PIN_PATTERN.match(pin_string)
      raise ArgumentError, "Invalid PIN string: #{pin_string}" unless match

      letter = match[:letter]
      prefix = match[:prefix]
      terminal_marker = match[:terminal]

      type = letter.upcase.to_sym
      side = letter == letter.upcase ? :first : :second

      state = case prefix
              when "+" then :enhanced
              when "-" then :diminished
              else :normal
              end

      terminal = terminal_marker == "^"

      new(type, side, state, terminal: terminal)
    end

    # Checks if a string is a valid PIN notation.
    #
    # @param pin_string [String] The string to validate
    # @return [Boolean] true if valid, false otherwise
    #
    # @example
    #   Sashite::Pin.valid?("K")    # => true
    #   Sashite::Pin.valid?("+R")   # => true
    #   Sashite::Pin.valid?("K^")   # => true
    #   Sashite::Pin.valid?("invalid") # => false
    def self.valid?(pin_string)
      return false unless pin_string.is_a?(String)

      PIN_PATTERN.match?(pin_string)
    end

    # ========================================================================
    # Conversion
    # ========================================================================

    # Converts the Pin to its string representation.
    #
    # @return [String] The PIN string
    #
    # @example
    #   Sashite::Pin.new(:K, :first).to_s           # => "K"
    #   Sashite::Pin.new(:R, :second, :enhanced).to_s # => "+r"
    #   Sashite::Pin.new(:K, :first, :normal, terminal: true).to_s # => "K^"
    def to_s
      "#{prefix}#{letter}#{suffix}"
    end

    # Returns the letter representation of the PIN.
    #
    # @return [String] The letter (uppercase for first player, lowercase for second)
    #
    # @example
    #   Sashite::Pin.new(:K, :first).letter  # => "K"
    #   Sashite::Pin.new(:K, :second).letter # => "k"
    def letter
      case side
      when :first then type.to_s
      when :second then type.to_s.downcase
      end
    end

    # Returns the state prefix of the PIN.
    #
    # @return [String] "+" for enhanced, "-" for diminished, "" for normal
    #
    # @example
    #   Sashite::Pin.new(:K, :first, :enhanced).prefix   # => "+"
    #   Sashite::Pin.new(:K, :first, :diminished).prefix # => "-"
    #   Sashite::Pin.new(:K, :first, :normal).prefix     # => ""
    def prefix
      case state
      when :enhanced then "+"
      when :diminished then "-"
      else ""
      end
    end

    # Returns the terminal suffix of the PIN.
    #
    # @return [String] "^" if terminal, "" otherwise
    #
    # @example
    #   Sashite::Pin.new(:K, :first, :normal, terminal: true).suffix  # => "^"
    #   Sashite::Pin.new(:K, :first).suffix                           # => ""
    def suffix
      terminal ? "^" : ""
    end

    # ========================================================================
    # State Transformations
    # ========================================================================

    # Returns a new Pin with enhanced state.
    #
    # @return [Pin] A new Pin with :enhanced state
    #
    # @example
    #   pin = Sashite::Pin.new(:K, :first)
    #   pin.enhance.state # => :enhanced
    def enhance
      return self if state == :enhanced

      self.class.new(type, side, :enhanced, terminal: terminal)
    end

    # Returns a new Pin with diminished state.
    #
    # @return [Pin] A new Pin with :diminished state
    #
    # @example
    #   pin = Sashite::Pin.new(:K, :first)
    #   pin.diminish.state # => :diminished
    def diminish
      return self if state == :diminished

      self.class.new(type, side, :diminished, terminal: terminal)
    end

    # Returns a new Pin with normal state.
    #
    # @return [Pin] A new Pin with :normal state
    #
    # @example
    #   pin = Sashite::Pin.new(:K, :first, :enhanced)
    #   pin.normalize.state # => :normal
    def normalize
      return self if state == :normal

      self.class.new(type, side, :normal, terminal: terminal)
    end

    # ========================================================================
    # Side Transformations
    # ========================================================================

    # Returns a new Pin with the opposite side.
    #
    # @return [Pin] A new Pin with flipped side
    #
    # @example
    #   pin = Sashite::Pin.new(:K, :first)
    #   pin.flip.side # => :second
    def flip
      new_side = side == :first ? :second : :first
      self.class.new(type, new_side, state, terminal: terminal)
    end

    # ========================================================================
    # Terminal Transformations
    # ========================================================================

    # Returns a new Pin marked as terminal.
    #
    # @return [Pin] A new Pin with terminal: true
    #
    # @example
    #   pin = Sashite::Pin.new(:K, :first)
    #   pin.mark_terminal.terminal # => true
    def mark_terminal
      return self if terminal

      self.class.new(type, side, state, terminal: true)
    end

    # Returns a new Pin unmarked as terminal.
    #
    # @return [Pin] A new Pin with terminal: false
    #
    # @example
    #   pin = Sashite::Pin.new(:K, :first, :normal, terminal: true)
    #   pin.unmark_terminal.terminal # => false
    def unmark_terminal
      return self unless terminal

      self.class.new(type, side, state, terminal: false)
    end

    # ========================================================================
    # Attribute Transformations
    # ========================================================================

    # Returns a new Pin with a different type.
    #
    # @param new_type [Symbol] The new piece type (:A to :Z)
    # @return [Pin] A new Pin with the specified type
    #
    # @example
    #   pin = Sashite::Pin.new(:K, :first)
    #   pin.with_type(:Q).type # => :Q
    def with_type(new_type)
      return self if type == new_type

      self.class.new(new_type, side, state, terminal: terminal)
    end

    # Returns a new Pin with a different side.
    #
    # @param new_side [Symbol] The new side (:first or :second)
    # @return [Pin] A new Pin with the specified side
    #
    # @example
    #   pin = Sashite::Pin.new(:K, :first)
    #   pin.with_side(:second).side # => :second
    def with_side(new_side)
      return self if side == new_side

      self.class.new(type, new_side, state, terminal: terminal)
    end

    # Returns a new Pin with a different state.
    #
    # @param new_state [Symbol] The new state (:normal, :enhanced, or :diminished)
    # @return [Pin] A new Pin with the specified state
    #
    # @example
    #   pin = Sashite::Pin.new(:K, :first)
    #   pin.with_state(:enhanced).state # => :enhanced
    def with_state(new_state)
      return self if state == new_state

      self.class.new(type, side, new_state, terminal: terminal)
    end

    # Returns a new Pin with a different terminal status.
    #
    # @param new_terminal [Boolean] The new terminal status
    # @return [Pin] A new Pin with the specified terminal status
    #
    # @example
    #   pin = Sashite::Pin.new(:K, :first)
    #   pin.with_terminal(true).terminal # => true
    def with_terminal(new_terminal)
      return self if terminal == !!new_terminal

      self.class.new(type, side, state, terminal: !!new_terminal)
    end

    # ========================================================================
    # State Queries
    # ========================================================================

    # Checks if the Pin has normal state.
    #
    # @return [Boolean] true if normal state
    #
    # @example
    #   Sashite::Pin.new(:K, :first).normal? # => true
    def normal?
      state == :normal
    end

    # Checks if the Pin has enhanced state.
    #
    # @return [Boolean] true if enhanced state
    #
    # @example
    #   Sashite::Pin.new(:K, :first, :enhanced).enhanced? # => true
    def enhanced?
      state == :enhanced
    end

    # Checks if the Pin has diminished state.
    #
    # @return [Boolean] true if diminished state
    #
    # @example
    #   Sashite::Pin.new(:K, :first, :diminished).diminished? # => true
    def diminished?
      state == :diminished
    end

    # ========================================================================
    # Side Queries
    # ========================================================================

    # Checks if the Pin belongs to the first player.
    #
    # @return [Boolean] true if first player
    #
    # @example
    #   Sashite::Pin.new(:K, :first).first_player? # => true
    def first_player?
      side == :first
    end

    # Checks if the Pin belongs to the second player.
    #
    # @return [Boolean] true if second player
    #
    # @example
    #   Sashite::Pin.new(:K, :second).second_player? # => true
    def second_player?
      side == :second
    end

    # ========================================================================
    # Terminal Queries
    # ========================================================================

    # Checks if the Pin is a terminal piece.
    #
    # @return [Boolean] true if terminal
    #
    # @example
    #   Sashite::Pin.new(:K, :first, :normal, terminal: true).terminal? # => true
    def terminal?
      terminal
    end

    # ========================================================================
    # Comparison
    # ========================================================================

    # Checks if two Pins have the same type.
    #
    # @param other [Pin] The other Pin to compare
    # @return [Boolean] true if same type
    #
    # @example
    #   pin1 = Sashite::Pin.parse("K")
    #   pin2 = Sashite::Pin.parse("k")
    #   pin1.same_type?(pin2) # => true
    def same_type?(other)
      type == other.type
    end

    # Checks if two Pins have the same side.
    #
    # @param other [Pin] The other Pin to compare
    # @return [Boolean] true if same side
    #
    # @example
    #   pin1 = Sashite::Pin.parse("K")
    #   pin2 = Sashite::Pin.parse("Q")
    #   pin1.same_side?(pin2) # => true
    def same_side?(other)
      side == other.side
    end

    # Checks if two Pins have the same state.
    #
    # @param other [Pin] The other Pin to compare
    # @return [Boolean] true if same state
    #
    # @example
    #   pin1 = Sashite::Pin.parse("+K")
    #   pin2 = Sashite::Pin.parse("+Q")
    #   pin1.same_state?(pin2) # => true
    def same_state?(other)
      state == other.state
    end

    # Checks if two Pins have the same terminal status.
    #
    # @param other [Pin] The other Pin to compare
    # @return [Boolean] true if same terminal status
    #
    # @example
    #   pin1 = Sashite::Pin.parse("K^")
    #   pin2 = Sashite::Pin.parse("Q^")
    #   pin1.same_terminal?(pin2) # => true
    def same_terminal?(other)
      terminal == other.terminal
    end

    # Checks equality with another Pin.
    #
    # @param other [Object] The object to compare
    # @return [Boolean] true if equal
    def ==(other)
      return false unless other.is_a?(self.class)

      type == other.type &&
        side == other.side &&
        state == other.state &&
        terminal == other.terminal
    end

    alias eql? ==

    # Returns a hash code for the Pin.
    #
    # @return [Integer] Hash code
    def hash
      [type, side, state, terminal].hash
    end

    # Returns an inspect string for the Pin.
    #
    # @return [String] Inspect representation
    def inspect
      "#<#{self.class} #{self}>"
    end

    private

    # ========================================================================
    # Private Validation
    # ========================================================================

    def validate_type!(type)
      return if VALID_TYPES.include?(type)

      raise ArgumentError, "Type must be a symbol from :A to :Z, got: #{type.inspect}"
    end

    def validate_side!(side)
      return if VALID_SIDES.include?(side)

      raise ArgumentError, "Side must be :first or :second, got: #{side.inspect}"
    end

    def validate_state!(state)
      return if VALID_STATES.include?(state)

      raise ArgumentError, "State must be :normal, :enhanced, or :diminished, got: #{state.inspect}"
    end
  end
end
