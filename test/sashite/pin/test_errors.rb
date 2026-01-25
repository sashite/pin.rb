#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../lib/sashite/pin/errors"

# Helper function to run a test and report errors
def run_test(name)
  print "  #{name}... "
  yield
  puts "✓"
rescue StandardError => e
  warn "✗ Failure: #{e.message}"
  warn "    #{e.backtrace.first}"
  exit(1)
end

puts
puts "=== Errors Tests ==="
puts

# ============================================================================
# PARSING ERROR MESSAGES
# ============================================================================

puts "Parsing error messages:"

run_test("EMPTY_INPUT is defined") do
  raise "wrong value" unless Sashite::Pin::Errors::Argument::Messages::EMPTY_INPUT == "empty input"
end

run_test("INPUT_TOO_LONG is defined") do
  raise "wrong value" unless Sashite::Pin::Errors::Argument::Messages::INPUT_TOO_LONG == "input exceeds 3 characters"
end

run_test("MUST_CONTAIN_ONE_LETTER is defined") do
  raise "wrong value" unless Sashite::Pin::Errors::Argument::Messages::MUST_CONTAIN_ONE_LETTER == "must contain exactly one letter"
end

run_test("INVALID_STATE_MODIFIER is defined") do
  raise "wrong value" unless Sashite::Pin::Errors::Argument::Messages::INVALID_STATE_MODIFIER == "invalid state modifier"
end

run_test("INVALID_TERMINAL_MARKER is defined") do
  raise "wrong value" unless Sashite::Pin::Errors::Argument::Messages::INVALID_TERMINAL_MARKER == "invalid terminal marker"
end

# ============================================================================
# VALIDATION ERROR MESSAGES
# ============================================================================

puts
puts "Validation error messages:"

run_test("INVALID_ABBR is defined") do
  raise "wrong value" unless Sashite::Pin::Errors::Argument::Messages::INVALID_ABBR == "abbr must be a symbol from :A to :Z"
end

run_test("INVALID_SIDE is defined") do
  raise "wrong value" unless Sashite::Pin::Errors::Argument::Messages::INVALID_SIDE == "side must be :first or :second"
end

run_test("INVALID_STATE is defined") do
  raise "wrong value" unless Sashite::Pin::Errors::Argument::Messages::INVALID_STATE == "state must be :normal, :enhanced, or :diminished"
end

run_test("INVALID_TERMINAL is defined") do
  raise "wrong value" unless Sashite::Pin::Errors::Argument::Messages::INVALID_TERMINAL == "terminal must be true or false"
end

# ============================================================================
# ERROR CLASS
# ============================================================================

puts
puts "Error class:"

run_test("Argument inherits from ArgumentError") do
  raise "wrong inheritance" unless Sashite::Pin::Errors::Argument < ArgumentError
end

run_test("Argument can be raised with message") do
  raise Sashite::Pin::Errors::Argument, Sashite::Pin::Errors::Argument::Messages::EMPTY_INPUT
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == "empty input"
end

run_test("Argument can be rescued as ArgumentError") do
  raise Sashite::Pin::Errors::Argument, "test"
rescue ArgumentError => e
  raise "should be rescuable as ArgumentError" unless e.message == "test"
end

# ============================================================================
# ERROR MESSAGES ARE FROZEN
# ============================================================================

puts
puts "Immutability:"

run_test("EMPTY_INPUT is frozen") do
  raise "should be frozen" unless Sashite::Pin::Errors::Argument::Messages::EMPTY_INPUT.frozen?
end

run_test("INVALID_ABBR is frozen") do
  raise "should be frozen" unless Sashite::Pin::Errors::Argument::Messages::INVALID_ABBR.frozen?
end

puts
puts "All Errors tests passed!"
puts
