# frozen_string_literal: true

require_relative "constants"
require_relative "errors"

module Sashite
  module Pin
    # Secure parser for PIN (Piece Identifier Notation) strings.
    #
    # This parser uses character-by-character validation without regex
    # to prevent ReDoS attacks and ensure strict ASCII compliance.
    #
    # @example
    #   Parser.parse("K")   # => { type: :K, side: :first, state: :normal, terminal: false }
    #   Parser.parse("+r^") # => { type: :R, side: :second, state: :enhanced, terminal: true }
    #
    # @see https://sashite.dev/specs/pin/1.0.0/
    module Parser
      # Parses a PIN string into its components.
      #
      # @param input [String] The PIN string to parse
      # @return [Hash] A hash with :type, :side, :state, and :terminal keys
      # @raise [Errors::Argument] If the input is not a valid PIN string
      def self.parse(input)
        validate_input_type(input)
        validate_not_empty(input)
        validate_length(input)

        parse_components(input)
      end

      # Validates a PIN string without raising an exception.
      #
      # @param input [String] The PIN string to validate
      # @return [Boolean] true if valid, false otherwise
      def self.valid?(input)
        return false unless ::String === input

        parse(input)
        true
      rescue Errors::Argument
        false
      end

      class << self
        private

        # Validates that input is a String.
        #
        # @param input [Object] The input to validate
        # @raise [Errors::Argument] If input is not a String
        def validate_input_type(input)
          return if ::String === input

          raise Errors::Argument, Errors::Argument::Messages::MUST_CONTAIN_ONE_LETTER
        end

        # Validates that input is not empty.
        #
        # @param input [String] The input to validate
        # @raise [Errors::Argument] If input is empty
        def validate_not_empty(input)
          return unless input.empty?

          raise Errors::Argument, Errors::Argument::Messages::EMPTY_INPUT
        end

        # Validates that input does not exceed maximum length.
        #
        # @param input [String] The input to validate
        # @raise [Errors::Argument] If input is too long
        def validate_length(input)
          return if input.bytesize <= Constants::MAX_STRING_LENGTH

          raise Errors::Argument, Errors::Argument::Messages::INPUT_TOO_LONG
        end

        # Parses the PIN string into its components.
        #
        # @param input [String] The validated PIN string
        # @return [Hash] A hash with :type, :side, :state, and :terminal keys
        # @raise [Errors::Argument] If the structure is invalid
        def parse_components(input)
          pos = 0
          state = :normal
          terminal = false

          # Check for state modifier at position 0
          byte = input.getbyte(pos)
          if state_modifier?(byte)
            state = decode_state_modifier(byte)
            pos += 1
          end

          # Must have a letter at current position
          raise Errors::Argument, Errors::Argument::Messages::MUST_CONTAIN_ONE_LETTER if pos >= input.bytesize

          byte = input.getbyte(pos)
          raise Errors::Argument, Errors::Argument::Messages::MUST_CONTAIN_ONE_LETTER unless ascii_letter?(byte)

          type = byte.chr.upcase.to_sym
          side = uppercase_letter?(byte) ? :first : :second
          pos += 1

          # Check for terminal marker
          if pos < input.bytesize
            byte = input.getbyte(pos)
            raise Errors::Argument, Errors::Argument::Messages::INVALID_TERMINAL_MARKER unless terminal_marker?(byte)

            terminal = true
            pos += 1
          end

          # Ensure no extra characters
          raise Errors::Argument, Errors::Argument::Messages::MUST_CONTAIN_ONE_LETTER if pos < input.bytesize

          { type: type, side: side, state: state, terminal: terminal }
        end

        # Checks if a byte is a state modifier (+ or -).
        #
        # @param byte [Integer] The byte to check
        # @return [Boolean] true if state modifier
        def state_modifier?(byte)
          byte == 0x2B || byte == 0x2D # '+' or '-'
        end

        # Decodes a state modifier byte to a state symbol.
        #
        # @param byte [Integer] The byte to decode
        # @return [Symbol] :enhanced or :diminished
        def decode_state_modifier(byte)
          byte == 0x2B ? :enhanced : :diminished
        end

        # Checks if a byte is an ASCII letter (A-Z or a-z).
        #
        # @param byte [Integer] The byte to check
        # @return [Boolean] true if ASCII letter
        def ascii_letter?(byte)
          uppercase_letter?(byte) || lowercase_letter?(byte)
        end

        # Checks if a byte is an uppercase ASCII letter (A-Z).
        #
        # @param byte [Integer] The byte to check
        # @return [Boolean] true if uppercase letter
        def uppercase_letter?(byte)
          byte >= 0x41 && byte <= 0x5A # 'A' to 'Z'
        end

        # Checks if a byte is a lowercase ASCII letter (a-z).
        #
        # @param byte [Integer] The byte to check
        # @return [Boolean] true if lowercase letter
        def lowercase_letter?(byte)
          byte >= 0x61 && byte <= 0x7A # 'a' to 'z'
        end

        # Checks if a byte is a terminal marker (^).
        #
        # @param byte [Integer] The byte to check
        # @return [Boolean] true if terminal marker
        def terminal_marker?(byte)
          byte == 0x5E # '^'
        end
      end
    end
  end
end
