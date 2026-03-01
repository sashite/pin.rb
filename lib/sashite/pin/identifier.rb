# frozen_string_literal: true

require_relative "constants"
require_relative "errors"

module Sashite
  module Pin
    # Flyweight Identifier for PIN (Piece Identifier Notation).
    #
    # PIN has a closed domain of exactly 312 valid tokens
    # (26 abbreviations × 2 sides × 3 states × 2 terminal).
    # All 312 Identifier instances are pre-instantiated and frozen at load time.
    #
    # Every public entry point ({.fetch}, transformations, Pin.parse, Pin.safe_parse)
    # returns a cached instance from the pool via integer-keyed Array lookup.
    # No Identifier is ever allocated after the module loads.
    #
    # @example Retrieve from pool
    #   Identifier.fetch(:K, :first)                         # => #<Sashite::Pin::Identifier K>
    #   Identifier.fetch(:R, :second, :enhanced)             # => #<Sashite::Pin::Identifier +r>
    #   Identifier.fetch(:K, :first, :normal, terminal: true) # => #<Sashite::Pin::Identifier K^>
    #
    # @example Identity guarantee
    #   Identifier.fetch(:K, :first).equal?(Identifier.fetch(:K, :first))  # => true
    #
    # @see https://sashite.dev/specs/pin/1.0.0/
    class Identifier
      # ==================================================================
      # Pool key computation
      # ==================================================================
      # Layout: abbr(0-25) * 12 + side(0-1) * 6 + state(0-2) * 2 + terminal(0-1)
      # Range:  0..311 (312 total)

      # @!visibility private
      ABBR_ORDINAL = Constants::VALID_ABBRS.each_with_index.to_h.freeze

      # @!visibility private
      SIDE_ORDINAL = { first: 0, second: 1 }.freeze

      # @!visibility private
      STATE_ORDINAL = { normal: 0, enhanced: 1, diminished: 2 }.freeze

      # @!visibility private
      OPPOSITE_SIDE = { first: :second, second: :first }.freeze

      # Pre-computed string fragments for to_s construction (init-time only).
      # @!visibility private
      PREFIX_STR = {
        normal:     Constants::EMPTY_STRING,
        enhanced:   Constants::ENHANCED_PREFIX,
        diminished: Constants::DIMINISHED_PREFIX
      }.freeze

      # @!visibility private
      SUFFIX_STR = { false => Constants::EMPTY_STRING, true => Constants::TERMINAL_SUFFIX }.freeze

      private_constant :ABBR_ORDINAL, :SIDE_ORDINAL, :STATE_ORDINAL,
                       :OPPOSITE_SIDE, :PREFIX_STR, :SUFFIX_STR

      # ==================================================================
      # Attributes
      # ==================================================================

      # @return [Symbol] Piece name abbreviation (:A to :Z, always uppercase)
      attr_reader :abbr

      # @return [Symbol] Piece side (:first or :second)
      attr_reader :side

      # @return [Symbol] Piece state (:normal, :enhanced, or :diminished)
      attr_reader :state

      # Creates a new Identifier. Intended for internal pool construction;
      # prefer {.fetch} or the module-level {Pin.parse} / {Pin.safe_parse}.
      #
      # @param abbr [Symbol] Piece name abbreviation (:A to :Z)
      # @param side [Symbol] Piece side (:first or :second)
      # @param state [Symbol] Piece state (:normal, :enhanced, or :diminished)
      # @param terminal [Boolean] Terminal status
      # @raise [Errors::Argument] If any attribute is invalid
      def initialize(abbr, side, state = :normal, terminal: false)
        raise Errors::Argument, Errors::Argument::Messages::INVALID_ABBR     unless Constants::ABBR_SET[abbr]
        raise Errors::Argument, Errors::Argument::Messages::INVALID_SIDE     unless Constants::SIDE_SET[side]
        raise Errors::Argument, Errors::Argument::Messages::INVALID_STATE    unless Constants::STATE_SET[state]
        raise Errors::Argument, Errors::Argument::Messages::INVALID_TERMINAL unless terminal.equal?(true) || terminal.equal?(false)

        @abbr     = abbr
        @side     = side
        @state    = state
        @terminal = terminal

        # Pre-compute derived values (once per instance, at load time).
        letter = side.equal?(:first) ? abbr.to_s : (abbr.to_s.getbyte(0) + Constants::CASE_OFFSET).chr
        @string  = "#{PREFIX_STR[state]}#{letter}#{SUFFIX_STR[terminal]}".freeze
        @hash    = (ABBR_ORDINAL[abbr] * 12 + SIDE_ORDINAL[side] * 6 + STATE_ORDINAL[state] * 2 + (terminal ? 1 : 0)).hash
        @inspect = "#<#{self.class} #{@string}>".freeze

        freeze
      end

      # @return [Boolean] true if terminal piece, false otherwise
      def terminal?
        @terminal
      end

      # ==================================================================
      # String conversion (pre-computed — zero allocation)
      # ==================================================================

      # @return [String] The PIN string representation
      def to_s
        @string
      end

      # @return [String] Inspect representation
      def inspect
        @inspect
      end

      # ==================================================================
      # State transformations (unchecked pool lookup — zero allocation)
      # ==================================================================

      # @return [Identifier] Cached Identifier with :enhanced state
      def enhance
        return self if enhanced?

        _pool_lookup(@abbr, @side, :enhanced, @terminal)
      end

      # @return [Identifier] Cached Identifier with :diminished state
      def diminish
        return self if diminished?

        _pool_lookup(@abbr, @side, :diminished, @terminal)
      end

      # @return [Identifier] Cached Identifier with :normal state
      def normalize
        return self if normal?

        _pool_lookup(@abbr, @side, :normal, @terminal)
      end

      # ==================================================================
      # Side transformation (unchecked pool lookup — zero allocation)
      # ==================================================================

      # @return [Identifier] Cached Identifier with the opposite side
      def flip
        _pool_lookup(@abbr, OPPOSITE_SIDE[@side], @state, @terminal)
      end

      # ==================================================================
      # Terminal transformations (unchecked pool lookup — zero allocation)
      # ==================================================================

      # @return [Identifier] Cached Identifier with terminal: true
      def terminal
        return self if @terminal

        _pool_lookup(@abbr, @side, @state, true)
      end

      # @return [Identifier] Cached Identifier with terminal: false
      def non_terminal
        return self unless @terminal

        _pool_lookup(@abbr, @side, @state, false)
      end

      # ==================================================================
      # Attribute transformations (validated — user input may be invalid)
      # ==================================================================

      # @param new_abbr [Symbol] The new piece name abbreviation (:A to :Z)
      # @return [Identifier] Cached Identifier with the specified abbreviation
      # @raise [Errors::Argument] If the abbreviation is invalid
      def with_abbr(new_abbr)
        return self if @abbr.equal?(new_abbr)

        self.class.fetch(new_abbr, @side, @state, terminal: @terminal)
      end

      # @param new_side [Symbol] The new side (:first or :second)
      # @return [Identifier] Cached Identifier with the specified side
      # @raise [Errors::Argument] If the side is invalid
      def with_side(new_side)
        return self if @side.equal?(new_side)

        self.class.fetch(@abbr, new_side, @state, terminal: @terminal)
      end

      # @param new_state [Symbol] The new state (:normal, :enhanced, or :diminished)
      # @return [Identifier] Cached Identifier with the specified state
      # @raise [Errors::Argument] If the state is invalid
      def with_state(new_state)
        return self if @state.equal?(new_state)

        self.class.fetch(@abbr, @side, new_state, terminal: @terminal)
      end

      # @param new_terminal [Boolean] The new terminal status
      # @return [Identifier] Cached Identifier with the specified terminal status
      # @raise [Errors::Argument] If the terminal is not a boolean
      def with_terminal(new_terminal)
        return self if @terminal.equal?(new_terminal)

        self.class.fetch(@abbr, @side, @state, terminal: new_terminal)
      end

      # ==================================================================
      # State queries
      # ==================================================================

      # @return [Boolean] true if normal state
      def normal?
        @state.equal?(:normal)
      end

      # @return [Boolean] true if enhanced state
      def enhanced?
        @state.equal?(:enhanced)
      end

      # @return [Boolean] true if diminished state
      def diminished?
        @state.equal?(:diminished)
      end

      # ==================================================================
      # Side queries
      # ==================================================================

      # @return [Boolean] true if first player
      def first_player?
        @side.equal?(:first)
      end

      # @return [Boolean] true if second player
      def second_player?
        @side.equal?(:second)
      end

      # ==================================================================
      # Comparison queries
      # ==================================================================

      # @param other [Identifier]
      # @return [Boolean] true if same abbreviation
      def same_abbr?(other)
        @abbr.equal?(other.abbr)
      end

      # @param other [Identifier]
      # @return [Boolean] true if same side
      def same_side?(other)
        @side.equal?(other.side)
      end

      # @param other [Identifier]
      # @return [Boolean] true if same state
      def same_state?(other)
        @state.equal?(other.state)
      end

      # @param other [Identifier]
      # @return [Boolean] true if same terminal status
      def same_terminal?(other)
        @terminal.equal?(other.terminal?)
      end

      # ==================================================================
      # Equality
      # ==================================================================

      # With the flyweight pool, pool instances satisfy a == b ⟺ a.equal?(b).
      # The value-based fallback handles any out-of-pool instance correctly.
      #
      # @param other [Object]
      # @return [Boolean]
      def ==(other)
        equal?(other) || (
          self.class === other &&
          @abbr.equal?(other.abbr) &&
          @side.equal?(other.side) &&
          @state.equal?(other.state) &&
          @terminal.equal?(other.terminal?)
        )
      end

      alias eql? ==

      # @return [Integer] Pre-computed hash code
      def hash
        @hash
      end

      # ==================================================================
      # Class-level pool access
      # ==================================================================

      class << self
        # Retrieves a cached Identifier by components. Validates inputs
        # and raises with a specific diagnostic on failure.
        #
        # @param abbr [Symbol] Piece abbreviation (:A through :Z)
        # @param side [Symbol] Piece side (:first or :second)
        # @param state [Symbol] Piece state (:normal, :enhanced, or :diminished)
        # @param terminal [Boolean] Terminal status
        # @return [Identifier]
        # @raise [Errors::Argument] If any component is invalid
        def fetch(abbr, side, state = :normal, terminal: false)
          ai  = ABBR_ORDINAL[abbr]
          si  = SIDE_ORDINAL[side]
          sti = STATE_ORDINAL[state]

          if ai && si && sti && (terminal.equal?(true) || terminal.equal?(false))
            return POOL[ai * 12 + si * 6 + sti * 2 + (terminal ? 1 : 0)]
          end

          # Slow path: determine which component is invalid
          raise_fetch_error!(abbr, side, state, terminal)
        end

        private

        # @raise [Errors::Argument] Always raises with the most specific message
        def raise_fetch_error!(abbr, side, state, terminal)
          msg = Errors::Argument::Messages
          raise Errors::Argument, msg::INVALID_ABBR     unless Constants::ABBR_SET[abbr]
          raise Errors::Argument, msg::INVALID_SIDE     unless Constants::SIDE_SET[side]
          raise Errors::Argument, msg::INVALID_STATE    unless Constants::STATE_SET[state]
          raise Errors::Argument, msg::INVALID_TERMINAL
        end
      end

      private

      # Unchecked pool lookup for internal transformations.
      # All components are known valid (self is a valid pool instance and
      # the transformation substitutes a hardcoded valid value).
      # Single array index — zero allocation.
      #
      # @return [Identifier]
      def _pool_lookup(abbr, side, state, terminal)
        POOL[ABBR_ORDINAL[abbr] * 12 + SIDE_ORDINAL[side] * 6 + STATE_ORDINAL[state] * 2 + (terminal ? 1 : 0)]
      end

      # ==================================================================
      # Flyweight pool construction (runs once at load time)
      # ==================================================================

      POOL = ::Array.new(312)

      Constants::VALID_ABBRS.each_with_index do |a, ai|
        Constants::VALID_SIDES.each_with_index do |s, si|
          Constants::VALID_STATES.each_with_index do |st, sti|
            [false, true].each_with_index do |t, ti|
              POOL[ai * 12 + si * 6 + sti * 2 + ti] = new(a, s, st, terminal: t)
            end
          end
        end
      end

      POOL.freeze
      private_constant :POOL, :ABBR_ORDINAL, :SIDE_ORDINAL, :STATE_ORDINAL,
                       :OPPOSITE_SIDE, :PREFIX_STR, :SUFFIX_STR
    end
  end
end
