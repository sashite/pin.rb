# frozen_string_literal: true

module Sashite
  module Pin
    # Performance-oriented constants for PIN (Piece Identifier Notation).
    #
    # All lookups are O(1) frozen Hashes. Byte-level constants eliminate
    # repeated method calls in the parser hot path.
    module Constants
      # ====================================================================
      # Domain values
      # ====================================================================

      # Valid piece name abbreviations (uppercase symbols :A..:Z).
      VALID_ABBRS = %i[A B C D E F G H I J K L M N O P Q R S T U V W X Y Z].freeze

      # Valid player sides.
      VALID_SIDES = %i[first second].freeze

      # Valid piece states.
      VALID_STATES = %i[normal enhanced diminished].freeze

      # ====================================================================
      # O(1) validation lookups (frozen Hashes → faster than Array#include?)
      # ====================================================================

      # { :A => true, :B => true, … :Z => true }
      ABBR_SET = VALID_ABBRS.each_with_object({}) { |a, h| h[a] = true }.freeze

      # { :first => true, :second => true }
      SIDE_SET = VALID_SIDES.each_with_object({}) { |s, h| h[s] = true }.freeze

      # { :normal => true, :enhanced => true, :diminished => true }
      STATE_SET = VALID_STATES.each_with_object({}) { |s, h| h[s] = true }.freeze

      # ====================================================================
      # String fragments (frozen, reused by Identifier#to_s)
      # ====================================================================

      ENHANCED_PREFIX  = "+"
      DIMINISHED_PREFIX = "-"
      TERMINAL_SUFFIX  = "^"
      EMPTY_STRING     = ""

      # ====================================================================
      # Byte constants (used by Parser for zero-allocation character checks)
      # ====================================================================

      # State modifier bytes
      BYTE_PLUS  = 0x2B # '+'
      BYTE_MINUS = 0x2D # '-'

      # Terminal marker byte
      BYTE_CARET = 0x5E # '^'

      # ASCII letter ranges
      BYTE_UPPER_A = 0x41 # 'A'
      BYTE_UPPER_Z = 0x5A # 'Z'
      BYTE_LOWER_A = 0x61 # 'a'
      BYTE_LOWER_Z = 0x7A # 'z'

      # Case conversion offset (lowercase - uppercase = 32)
      CASE_OFFSET = 0x20

      # ====================================================================
      # Token length
      # ====================================================================

      # Maximum byte length of a valid PIN string: "+K^"
      MAX_BYTE_LENGTH = 3
    end
  end
end
