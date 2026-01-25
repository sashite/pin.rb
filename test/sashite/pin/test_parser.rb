#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../lib/sashite/pin/parser"
require_relative "../../../lib/sashite/pin/identifier"

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
puts "=== Parser Tests ==="
puts

# ============================================================================
# VALID INPUTS - SIMPLE LETTERS
# ============================================================================

puts "Valid inputs - simple letters:"

run_test("parses uppercase letter 'K'") do
  result = Sashite::Pin::Parser.parse("K")
  raise "wrong abbr" unless result[:abbr] == :K
  raise "wrong side" unless result[:side] == :first
  raise "wrong state" unless result[:state] == :normal
  raise "wrong terminal" unless result[:terminal] == false
end

run_test("parses lowercase letter 'k'") do
  result = Sashite::Pin::Parser.parse("k")
  raise "wrong abbr" unless result[:abbr] == :K
  raise "wrong side" unless result[:side] == :second
  raise "wrong state" unless result[:state] == :normal
  raise "wrong terminal" unless result[:terminal] == false
end

run_test("parses all uppercase letters A-Z") do
  ("A".."Z").each do |letter|
    result = Sashite::Pin::Parser.parse(letter)
    raise "wrong abbr for #{letter}" unless result[:abbr] == letter.to_sym
    raise "wrong side for #{letter}" unless result[:side] == :first
  end
end

run_test("parses all lowercase letters a-z") do
  ("a".."z").each do |letter|
    result = Sashite::Pin::Parser.parse(letter)
    raise "wrong abbr for #{letter}" unless result[:abbr] == letter.upcase.to_sym
    raise "wrong side for #{letter}" unless result[:side] == :second
  end
end

# ============================================================================
# VALID INPUTS - WITH STATE MODIFIERS
# ============================================================================

puts
puts "Valid inputs - state modifiers:"

run_test("parses enhanced uppercase '+R'") do
  result = Sashite::Pin::Parser.parse("+R")
  raise "wrong abbr" unless result[:abbr] == :R
  raise "wrong side" unless result[:side] == :first
  raise "wrong state" unless result[:state] == :enhanced
  raise "wrong terminal" unless result[:terminal] == false
end

run_test("parses enhanced lowercase '+r'") do
  result = Sashite::Pin::Parser.parse("+r")
  raise "wrong abbr" unless result[:abbr] == :R
  raise "wrong side" unless result[:side] == :second
  raise "wrong state" unless result[:state] == :enhanced
end

run_test("parses diminished uppercase '-P'") do
  result = Sashite::Pin::Parser.parse("-P")
  raise "wrong abbr" unless result[:abbr] == :P
  raise "wrong side" unless result[:side] == :first
  raise "wrong state" unless result[:state] == :diminished
end

run_test("parses diminished lowercase '-p'") do
  result = Sashite::Pin::Parser.parse("-p")
  raise "wrong abbr" unless result[:abbr] == :P
  raise "wrong side" unless result[:side] == :second
  raise "wrong state" unless result[:state] == :diminished
end

# ============================================================================
# VALID INPUTS - WITH TERMINAL MARKER
# ============================================================================

puts
puts "Valid inputs - terminal marker:"

run_test("parses terminal uppercase 'K^'") do
  result = Sashite::Pin::Parser.parse("K^")
  raise "wrong abbr" unless result[:abbr] == :K
  raise "wrong side" unless result[:side] == :first
  raise "wrong state" unless result[:state] == :normal
  raise "wrong terminal" unless result[:terminal] == true
end

run_test("parses terminal lowercase 'k^'") do
  result = Sashite::Pin::Parser.parse("k^")
  raise "wrong abbr" unless result[:abbr] == :K
  raise "wrong side" unless result[:side] == :second
  raise "wrong terminal" unless result[:terminal] == true
end

# ============================================================================
# VALID INPUTS - COMBINED
# ============================================================================

puts
puts "Valid inputs - combined modifiers:"

run_test("parses enhanced terminal '+K^'") do
  result = Sashite::Pin::Parser.parse("+K^")
  raise "wrong abbr" unless result[:abbr] == :K
  raise "wrong side" unless result[:side] == :first
  raise "wrong state" unless result[:state] == :enhanced
  raise "wrong terminal" unless result[:terminal] == true
end

run_test("parses diminished terminal '-k^'") do
  result = Sashite::Pin::Parser.parse("-k^")
  raise "wrong abbr" unless result[:abbr] == :K
  raise "wrong side" unless result[:side] == :second
  raise "wrong state" unless result[:state] == :diminished
  raise "wrong terminal" unless result[:terminal] == true
end

# ============================================================================
# VALID? METHOD
# ============================================================================

puts
puts "valid? method:"

run_test("returns true for valid simple letter") do
  raise "should be valid" unless Sashite::Pin::Parser.valid?("K")
  raise "should be valid" unless Sashite::Pin::Parser.valid?("k")
end

run_test("returns true for valid with modifiers") do
  raise "should be valid" unless Sashite::Pin::Parser.valid?("+R")
  raise "should be valid" unless Sashite::Pin::Parser.valid?("-p")
  raise "should be valid" unless Sashite::Pin::Parser.valid?("K^")
  raise "should be valid" unless Sashite::Pin::Parser.valid?("+K^")
end

run_test("returns false for invalid inputs") do
  raise "should be invalid" if Sashite::Pin::Parser.valid?("")
  raise "should be invalid" if Sashite::Pin::Parser.valid?("KK")
  raise "should be invalid" if Sashite::Pin::Parser.valid?("invalid")
  raise "should be invalid" if Sashite::Pin::Parser.valid?(nil)
end

# ============================================================================
# ERROR CASES - EMPTY INPUT
# ============================================================================

puts
puts "Error cases - empty input:"

run_test("raises on empty string") do
  Sashite::Pin::Parser.parse("")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::EMPTY_INPUT
end

# ============================================================================
# ERROR CASES - INPUT TOO LONG
# ============================================================================

puts
puts "Error cases - input too long:"

run_test("raises on 4 characters") do
  Sashite::Pin::Parser.parse("+K^X")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INPUT_TOO_LONG
end

run_test("raises on many characters") do
  Sashite::Pin::Parser.parse("invalid")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INPUT_TOO_LONG
end

# ============================================================================
# ERROR CASES - MUST CONTAIN ONE LETTER
# ============================================================================

puts
puts "Error cases - must contain one letter:"

run_test("raises on modifier only") do
  Sashite::Pin::Parser.parse("+")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::MUST_CONTAIN_ONE_LETTER
end

run_test("raises on digit only") do
  Sashite::Pin::Parser.parse("1")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::MUST_CONTAIN_ONE_LETTER
end

run_test("raises on terminal marker only") do
  Sashite::Pin::Parser.parse("^")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::MUST_CONTAIN_ONE_LETTER
end

# ============================================================================
# ERROR CASES - INVALID TERMINAL MARKER
# ============================================================================

puts
puts "Error cases - invalid terminal marker:"

run_test("raises on two letters") do
  Sashite::Pin::Parser.parse("KQ")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INVALID_TERMINAL_MARKER
end

run_test("raises on letter followed by invalid character") do
  Sashite::Pin::Parser.parse("K!")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INVALID_TERMINAL_MARKER
end

run_test("raises on letter followed by digit") do
  Sashite::Pin::Parser.parse("K1")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INVALID_TERMINAL_MARKER
end

# ============================================================================
# SECURITY TESTS - NULL BYTE INJECTION
# ============================================================================

puts
puts "Security - null byte injection:"

run_test("rejects null byte at end") do
  raise "should be invalid" if Sashite::Pin::Parser.valid?("K\x00")
end

run_test("rejects null byte at start") do
  raise "should be invalid" if Sashite::Pin::Parser.valid?("\x00K")
end

run_test("rejects null byte in middle") do
  raise "should be invalid" if Sashite::Pin::Parser.valid?("+\x00K")
end

# ============================================================================
# SECURITY TESTS - CONTROL CHARACTERS
# ============================================================================

puts
puts "Security - control characters:"

run_test("rejects newline") do
  raise "should be invalid" if Sashite::Pin::Parser.valid?("K\n")
  raise "should be invalid" if Sashite::Pin::Parser.valid?("\nK")
end

run_test("rejects carriage return") do
  raise "should be invalid" if Sashite::Pin::Parser.valid?("K\r")
  raise "should be invalid" if Sashite::Pin::Parser.valid?("\r\nK")
end

run_test("rejects tab") do
  raise "should be invalid" if Sashite::Pin::Parser.valid?("K\t")
  raise "should be invalid" if Sashite::Pin::Parser.valid?("\tK")
end

run_test("rejects other control characters") do
  raise "should be invalid" if Sashite::Pin::Parser.valid?("K\x01") # SOH
  raise "should be invalid" if Sashite::Pin::Parser.valid?("K\x1b") # ESC
  raise "should be invalid" if Sashite::Pin::Parser.valid?("K\x7f") # DEL
end

# ============================================================================
# SECURITY TESTS - UNICODE LOOKALIKES
# ============================================================================

puts
puts "Security - Unicode lookalikes:"

run_test("rejects Cyrillic lookalikes") do
  # Cyrillic 'К' (U+041A) looks like Latin 'K'
  raise "should be invalid" if Sashite::Pin::Parser.valid?("\xD0\x9A")
  # Cyrillic 'а' (U+0430) looks like Latin 'a'
  raise "should be invalid" if Sashite::Pin::Parser.valid?("\xD0\xB0")
end

run_test("rejects Greek lookalikes") do
  # Greek 'Α' (U+0391) looks like Latin 'A'
  raise "should be invalid" if Sashite::Pin::Parser.valid?("\xCE\x91")
end

run_test("rejects full-width characters") do
  # Full-width 'K' (U+FF2B)
  raise "should be invalid" if Sashite::Pin::Parser.valid?("\xEF\xBC\xAB")
  # Full-width 'k' (U+FF4B)
  raise "should be invalid" if Sashite::Pin::Parser.valid?("\xEF\xBD\x8B")
end

# ============================================================================
# SECURITY TESTS - COMBINING CHARACTERS
# ============================================================================

puts
puts "Security - combining characters:"

run_test("rejects combining acute accent") do
  # 'K' + combining acute accent (U+0301)
  raise "should be invalid" if Sashite::Pin::Parser.valid?("K\xCC\x81")
end

run_test("rejects combining diaeresis") do
  # 'K' + combining diaeresis (U+0308)
  raise "should be invalid" if Sashite::Pin::Parser.valid?("K\xCC\x88")
end

# ============================================================================
# SECURITY TESTS - ZERO-WIDTH CHARACTERS
# ============================================================================

puts
puts "Security - zero-width characters:"

run_test("rejects zero-width space") do
  # Zero-width space (U+200B)
  raise "should be invalid" if Sashite::Pin::Parser.valid?("K\xE2\x80\x8B")
end

run_test("rejects zero-width non-joiner") do
  # Zero-width non-joiner (U+200C)
  raise "should be invalid" if Sashite::Pin::Parser.valid?("K\xE2\x80\x8C")
end

run_test("rejects BOM") do
  # Byte order mark (U+FEFF)
  raise "should be invalid" if Sashite::Pin::Parser.valid?("\xEF\xBB\xBFK")
end

# ============================================================================
# SECURITY TESTS - NON-STRING INPUT
# ============================================================================

puts
puts "Security - non-string input:"

run_test("rejects nil") do
  raise "should be invalid" if Sashite::Pin::Parser.valid?(nil)
end

run_test("rejects integer") do
  raise "should be invalid" if Sashite::Pin::Parser.valid?(123)
end

run_test("rejects array") do
  raise "should be invalid" if Sashite::Pin::Parser.valid?([:K])
end

run_test("rejects hash") do
  raise "should be invalid" if Sashite::Pin::Parser.valid?({ abbr: :K })
end

run_test("rejects symbol") do
  raise "should be invalid" if Sashite::Pin::Parser.valid?(:K)
end

# ============================================================================
# ROUND-TRIP TESTS
# ============================================================================

puts
puts "Round-trip tests:"

run_test("round-trip simple letters") do
  %w[K k Q q R r].each do |pin|
    result = Sashite::Pin::Parser.parse(pin)
    identifier = Sashite::Pin::Identifier.new(result[:abbr], result[:side], result[:state], terminal: result[:terminal])
    raise "round-trip failed for #{pin}" unless identifier.to_s == pin
  end
end

run_test("round-trip with state modifiers") do
  %w[+K +k -P -p +R -r].each do |pin|
    result = Sashite::Pin::Parser.parse(pin)
    identifier = Sashite::Pin::Identifier.new(result[:abbr], result[:side], result[:state], terminal: result[:terminal])
    raise "round-trip failed for #{pin}" unless identifier.to_s == pin
  end
end

run_test("round-trip with terminal marker") do
  %w[K^ k^ Q^ q^].each do |pin|
    result = Sashite::Pin::Parser.parse(pin)
    identifier = Sashite::Pin::Identifier.new(result[:abbr], result[:side], result[:state], terminal: result[:terminal])
    raise "round-trip failed for #{pin}" unless identifier.to_s == pin
  end
end

run_test("round-trip combined") do
  %w[+K^ -k^ +Q^ -q^].each do |pin|
    result = Sashite::Pin::Parser.parse(pin)
    identifier = Sashite::Pin::Identifier.new(result[:abbr], result[:side], result[:state], terminal: result[:terminal])
    raise "round-trip failed for #{pin}" unless identifier.to_s == pin
  end
end

puts
puts "All Parser tests passed!"
puts
