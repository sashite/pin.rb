# frozen_string_literal: true

module Sashite
  module Pin
    # Constants for PIN (Piece Identifier Notation).
    #
    # This module defines the valid values for PIN attributes.
    module Constants
      # Valid piece name abbreviations (uppercase symbols A-Z).
      VALID_ABBRS = %i[A B C D E F G H I J K L M N O P Q R S T U V W X Y Z].freeze

      # Valid player sides.
      VALID_SIDES = %i[first second].freeze

      # Valid piece states.
      VALID_STATES = %i[normal enhanced diminished].freeze

      # Maximum length of a valid PIN string.
      # Corresponds to "+K^" (state modifier + letter + terminal marker).
      MAX_STRING_LENGTH = 3

      # State modifier for enhanced state.
      ENHANCED_PREFIX = "+"

      # State modifier for diminished state.
      DIMINISHED_PREFIX = "-"

      # Empty string (no modifier).
      EMPTY_STRING = ""

      # Terminal marker suffix.
      TERMINAL_SUFFIX = "^"
    end
  end
end
