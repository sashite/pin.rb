# frozen_string_literal: true

require_relative "constants"
require_relative "errors"

module Sashite
  module Pin
    # Dual-path parser for PIN (Piece Identifier Notation) strings.
    #
    # Architecture:
    # - {safe_parse}: exception-free fast path → Hash or nil
    # - {parse}: calls safe_parse, raises with specific message on failure
    # - {valid?}: calls safe_parse, returns boolean
    #
    # The fast path (safe_parse) never allocates exception objects, never
    # captures backtraces, and performs zero string allocations — all
    # character inspection is done at byte level with pre-computed lookups.
    #
    # @example
    #   Parser.safe_parse("K")   # => { abbr: :K, side: :first, state: :normal, terminal: false }
    #   Parser.safe_parse("??")  # => nil
    #   Parser.parse("+r^")      # => { abbr: :R, side: :second, state: :enhanced, terminal: true }
    #   Parser.parse("invalid")  # => raises Errors::Argument
    #   Parser.valid?("K^")      # => true
    #
    # @see https://sashite.dev/specs/pin/1.0.0/
    module Parser
      # ====================================================================
      # Pre-computed lookup tables (built once at load time)
      # ====================================================================

      # Byte → uppercase Symbol. nil for non-letter bytes.
      # Indexed by byte value (0..127); covers ASCII range only.
      BYTE_TO_ABBR = ::Array.new(128).tap { |a|
        (Constants::BYTE_UPPER_A..Constants::BYTE_UPPER_Z).each { |b| a[b] = b.chr.to_sym }
        (Constants::BYTE_LOWER_A..Constants::BYTE_LOWER_Z).each { |b| a[b] = (b - Constants::CASE_OFFSET).chr.to_sym }
      }.freeze

      # Byte → side Symbol. nil for non-letter bytes.
      BYTE_TO_SIDE = ::Array.new(128).tap { |a|
        (Constants::BYTE_UPPER_A..Constants::BYTE_UPPER_Z).each { |b| a[b] = :first }
        (Constants::BYTE_LOWER_A..Constants::BYTE_LOWER_Z).each { |b| a[b] = :second }
      }.freeze

      private_constant :BYTE_TO_ABBR, :BYTE_TO_SIDE

      # ====================================================================
      # Public API
      # ====================================================================

      # Exception-free fast path. Returns a component Hash on success,
      # nil on any invalid input. Never raises, never allocates exceptions.
      #
      # @param input [String] The PIN string to parse
      # @return [Hash, nil] { abbr:, side:, state:, terminal: } or nil
      def self.safe_parse(input)
        return unless ::String === input

        len = input.bytesize
        return if len == 0 || len > Constants::MAX_BYTE_LENGTH

        pos = 0
        byte = input.getbyte(0)

        # Optional state modifier
        if byte == Constants::BYTE_PLUS
          state = :enhanced
          pos = 1
        elsif byte == Constants::BYTE_MINUS
          state = :diminished
          pos = 1
        else
          state = :normal
        end

        # Must have a letter at current position
        return if pos >= len

        byte = input.getbyte(pos)

        # Lookup tables return nil for non-letter bytes (including bytes >= 128)
        abbr = byte < 128 && BYTE_TO_ABBR[byte]
        return unless abbr

        side = BYTE_TO_SIDE[byte]
        pos += 1

        # Optional terminal marker
        terminal = false
        if pos < len
          return unless input.getbyte(pos) == Constants::BYTE_CARET

          terminal = true
          pos += 1
        end

        # Must be at end — no trailing characters
        return unless pos == len

        { abbr: abbr, side: side, state: state, terminal: terminal }
      end

      # Raising path. Returns a component Hash on success, raises
      # Errors::Argument with a specific diagnostic message on failure.
      #
      # Happy path is a single call to safe_parse (fast). The slow
      # diagnostic pass only runs when input is already known to be invalid.
      #
      # @param input [String] The PIN string to parse
      # @return [Hash] { abbr:, side:, state:, terminal: }
      # @raise [Errors::Argument] If the input is not a valid PIN string
      def self.parse(input)
        result = safe_parse(input)
        return result if result

        # Slow path: determine the specific error for a helpful message.
        raise_parse_error!(input)
      end

      # Boolean validation. Calls safe_parse, returns true/false.
      # Never raises, never allocates exceptions.
      #
      # @param input [String] The string to validate
      # @return [Boolean] true if valid PIN, false otherwise
      def self.valid?(input)
        !safe_parse(input).nil?
      end

      # ====================================================================
      # Private: diagnostic error reporting (slow path only)
      # ====================================================================

      class << self
        private

        # Analyzes an already-known-invalid input and raises with the most
        # specific error message. Called only from {parse} on the error path.
        #
        # @param input [Object] The invalid input
        # @raise [Errors::Argument] Always raises
        def raise_parse_error!(input)
          msg = Errors::Argument::Messages

          unless ::String === input
            raise Errors::Argument, msg::MUST_CONTAIN_ONE_LETTER
          end

          raise Errors::Argument, msg::EMPTY_INPUT if input.empty?
          raise Errors::Argument, msg::INPUT_TOO_LONG if input.bytesize > Constants::MAX_BYTE_LENGTH

          # Walk bytes to find the specific structural problem
          diagnose_structure!(input)
        end

        # Byte-level structural diagnosis for 1–3 byte strings.
        #
        # @param input [String] A 1-3 byte invalid PIN string
        # @raise [Errors::Argument] Always raises with specific message
        def diagnose_structure!(input)
          msg = Errors::Argument::Messages
          pos = 0
          byte = input.getbyte(0)

          # Skip valid state modifier
          if byte == Constants::BYTE_PLUS || byte == Constants::BYTE_MINUS
            pos = 1

            if pos >= input.bytesize
              raise Errors::Argument, msg::MUST_CONTAIN_ONE_LETTER
            end

            byte = input.getbyte(pos)
          end

          # Check letter position
          unless ascii_letter?(byte)
            raise Errors::Argument, msg::MUST_CONTAIN_ONE_LETTER
          end

          pos += 1

          # Check what follows the letter
          if pos < input.bytesize
            byte = input.getbyte(pos)

            unless byte == Constants::BYTE_CARET
              raise Errors::Argument, msg::INVALID_TERMINAL_MARKER
            end

            pos += 1
          end

          # Trailing characters after terminal marker
          if pos < input.bytesize
            raise Errors::Argument, msg::MUST_CONTAIN_ONE_LETTER
          end

          # Fallback (should not be reached if safe_parse returned nil)
          raise Errors::Argument, msg::MUST_CONTAIN_ONE_LETTER
        end

        # @param byte [Integer]
        # @return [Boolean]
        def ascii_letter?(byte)
          (byte >= Constants::BYTE_UPPER_A && byte <= Constants::BYTE_UPPER_Z) ||
            (byte >= Constants::BYTE_LOWER_A && byte <= Constants::BYTE_LOWER_Z)
        end
      end
    end
  end
end
