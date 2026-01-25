# frozen_string_literal: true

module Sashite
  module Pin
    module Errors
      class Argument < ::ArgumentError
        # Centralized error messages for PIN parsing and validation.
        #
        # @example
        #   raise Errors::Argument, Messages::EMPTY_INPUT
        module Messages
          # Parsing errors
          EMPTY_INPUT = "empty input"
          INPUT_TOO_LONG = "input exceeds 3 characters"
          MUST_CONTAIN_ONE_LETTER = "must contain exactly one letter"
          INVALID_STATE_MODIFIER = "invalid state modifier"
          INVALID_TERMINAL_MARKER = "invalid terminal marker"

          # Validation errors (constructor)
          INVALID_ABBR = "abbr must be a symbol from :A to :Z"
          INVALID_SIDE = "side must be :first or :second"
          INVALID_STATE = "state must be :normal, :enhanced, or :diminished"
          INVALID_TERMINAL = "terminal must be true or false"
        end
      end
    end
  end
end
