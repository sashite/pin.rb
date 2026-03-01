#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../helper"
require_relative "../../../lib/sashite/pin/errors"

puts
puts "=== Errors Tests ==="
puts

Messages = Sashite::Pin::Errors::Argument::Messages

# ============================================================================
# PARSING ERROR MESSAGES
# ============================================================================

puts "Parsing error messages:"

Test("EMPTY_INPUT is defined") do
  raise "wrong value" unless Messages::EMPTY_INPUT == "empty input"
end

Test("INPUT_TOO_LONG is defined") do
  raise "wrong value" unless Messages::INPUT_TOO_LONG == "input exceeds 3 characters"
end

Test("MUST_CONTAIN_ONE_LETTER is defined") do
  raise "wrong value" unless Messages::MUST_CONTAIN_ONE_LETTER == "must contain exactly one letter"
end

Test("INVALID_STATE_MODIFIER is defined") do
  raise "wrong value" unless Messages::INVALID_STATE_MODIFIER == "invalid state modifier"
end

Test("INVALID_TERMINAL_MARKER is defined") do
  raise "wrong value" unless Messages::INVALID_TERMINAL_MARKER == "invalid terminal marker"
end

# ============================================================================
# VALIDATION ERROR MESSAGES
# ============================================================================

puts
puts "Validation error messages:"

Test("INVALID_ABBR is defined") do
  raise "wrong value" unless Messages::INVALID_ABBR == "abbr must be a symbol from :A to :Z"
end

Test("INVALID_SIDE is defined") do
  raise "wrong value" unless Messages::INVALID_SIDE == "side must be :first or :second"
end

Test("INVALID_STATE is defined") do
  raise "wrong value" unless Messages::INVALID_STATE == "state must be :normal, :enhanced, or :diminished"
end

Test("INVALID_TERMINAL is defined") do
  raise "wrong value" unless Messages::INVALID_TERMINAL == "terminal must be true or false"
end

# ============================================================================
# ERROR CLASS
# ============================================================================

puts
puts "Error class:"

Test("Argument inherits from ArgumentError") do
  raise "wrong inheritance" unless Sashite::Pin::Errors::Argument < ArgumentError
end

Test("Argument can be raised with message") do
  raise Sashite::Pin::Errors::Argument, Messages::EMPTY_INPUT
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == "empty input"
end

Test("Argument can be rescued as ArgumentError") do
  raise Sashite::Pin::Errors::Argument, "test"
rescue ArgumentError => e
  raise "should be rescuable as ArgumentError" unless e.message == "test"
end

# ============================================================================
# IMMUTABILITY — ALL MESSAGES ARE FROZEN
# ============================================================================

puts
puts "Immutability:"

%i[
  EMPTY_INPUT INPUT_TOO_LONG MUST_CONTAIN_ONE_LETTER
  INVALID_STATE_MODIFIER INVALID_TERMINAL_MARKER
  INVALID_ABBR INVALID_SIDE INVALID_STATE INVALID_TERMINAL
].each do |name|
  Test("#{name} is frozen") do
    raise "should be frozen" unless Messages.const_get(name).frozen?
  end
end

puts
puts "All Errors tests passed!"
puts
