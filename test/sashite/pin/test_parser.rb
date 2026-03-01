#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../helper"
require_relative "../../../lib/sashite/pin/parser"
require_relative "../../../lib/sashite/pin/identifier"

puts
puts "=== Parser Tests ==="
puts

Parser = Sashite::Pin::Parser
Id     = Sashite::Pin::Identifier
Msg    = Sashite::Pin::Errors::Argument::Messages

# ============================================================================
# SAFE_PARSE - VALID INPUTS - SIMPLE LETTERS
# ============================================================================

puts "safe_parse - simple letters:"

Test("parses uppercase letter 'K'") do
  result = Parser.safe_parse("K")
  raise "wrong abbr" unless result[:abbr] == :K
  raise "wrong side" unless result[:side] == :first
  raise "wrong state" unless result[:state] == :normal
  raise "wrong terminal" unless result[:terminal] == false
end

Test("parses lowercase letter 'k'") do
  result = Parser.safe_parse("k")
  raise "wrong abbr" unless result[:abbr] == :K
  raise "wrong side" unless result[:side] == :second
  raise "wrong state" unless result[:state] == :normal
  raise "wrong terminal" unless result[:terminal] == false
end

Test("parses all uppercase letters A-Z") do
  ("A".."Z").each do |letter|
    result = Parser.safe_parse(letter)
    raise "nil for #{letter}" if result.nil?
    raise "wrong abbr for #{letter}" unless result[:abbr] == letter.to_sym
    raise "wrong side for #{letter}" unless result[:side] == :first
  end
end

Test("parses all lowercase letters a-z") do
  ("a".."z").each do |letter|
    result = Parser.safe_parse(letter)
    raise "nil for #{letter}" if result.nil?
    raise "wrong abbr for #{letter}" unless result[:abbr] == letter.upcase.to_sym
    raise "wrong side for #{letter}" unless result[:side] == :second
  end
end

# ============================================================================
# SAFE_PARSE - VALID INPUTS - STATE MODIFIERS
# ============================================================================

puts
puts "safe_parse - state modifiers:"

Test("parses enhanced uppercase '+R'") do
  result = Parser.safe_parse("+R")
  raise "wrong abbr" unless result[:abbr] == :R
  raise "wrong side" unless result[:side] == :first
  raise "wrong state" unless result[:state] == :enhanced
  raise "wrong terminal" unless result[:terminal] == false
end

Test("parses enhanced lowercase '+r'") do
  result = Parser.safe_parse("+r")
  raise "wrong abbr" unless result[:abbr] == :R
  raise "wrong side" unless result[:side] == :second
  raise "wrong state" unless result[:state] == :enhanced
end

Test("parses diminished uppercase '-P'") do
  result = Parser.safe_parse("-P")
  raise "wrong abbr" unless result[:abbr] == :P
  raise "wrong side" unless result[:side] == :first
  raise "wrong state" unless result[:state] == :diminished
end

Test("parses diminished lowercase '-p'") do
  result = Parser.safe_parse("-p")
  raise "wrong abbr" unless result[:abbr] == :P
  raise "wrong side" unless result[:side] == :second
  raise "wrong state" unless result[:state] == :diminished
end

# ============================================================================
# SAFE_PARSE - VALID INPUTS - TERMINAL MARKER
# ============================================================================

puts
puts "safe_parse - terminal marker:"

Test("parses terminal uppercase 'K^'") do
  result = Parser.safe_parse("K^")
  raise "wrong abbr" unless result[:abbr] == :K
  raise "wrong side" unless result[:side] == :first
  raise "wrong state" unless result[:state] == :normal
  raise "wrong terminal" unless result[:terminal] == true
end

Test("parses terminal lowercase 'k^'") do
  result = Parser.safe_parse("k^")
  raise "wrong abbr" unless result[:abbr] == :K
  raise "wrong side" unless result[:side] == :second
  raise "wrong terminal" unless result[:terminal] == true
end

# ============================================================================
# SAFE_PARSE - VALID INPUTS - COMBINED
# ============================================================================

puts
puts "safe_parse - combined modifiers:"

Test("parses enhanced terminal '+K^'") do
  result = Parser.safe_parse("+K^")
  raise "wrong abbr" unless result[:abbr] == :K
  raise "wrong side" unless result[:side] == :first
  raise "wrong state" unless result[:state] == :enhanced
  raise "wrong terminal" unless result[:terminal] == true
end

Test("parses diminished terminal '-k^'") do
  result = Parser.safe_parse("-k^")
  raise "wrong abbr" unless result[:abbr] == :K
  raise "wrong side" unless result[:side] == :second
  raise "wrong state" unless result[:state] == :diminished
  raise "wrong terminal" unless result[:terminal] == true
end

# ============================================================================
# SAFE_PARSE - INVALID INPUTS (returns nil, never raises)
# ============================================================================

puts
puts "safe_parse - invalid inputs return nil:"

Test("returns nil for empty string") do
  raise "should be nil" unless Parser.safe_parse("").nil?
end

Test("returns nil for too-long input") do
  raise "should be nil" unless Parser.safe_parse("+K^X").nil?
  raise "should be nil" unless Parser.safe_parse("invalid").nil?
end

Test("returns nil for modifier only") do
  raise "should be nil" unless Parser.safe_parse("+").nil?
  raise "should be nil" unless Parser.safe_parse("-").nil?
end

Test("returns nil for digit only") do
  raise "should be nil" unless Parser.safe_parse("1").nil?
end

Test("returns nil for terminal marker only") do
  raise "should be nil" unless Parser.safe_parse("^").nil?
end

Test("returns nil for two letters") do
  raise "should be nil" unless Parser.safe_parse("KQ").nil?
end

Test("returns nil for letter + invalid char") do
  raise "should be nil" unless Parser.safe_parse("K!").nil?
  raise "should be nil" unless Parser.safe_parse("K1").nil?
end

Test("returns nil for non-string types") do
  raise "should be nil" unless Parser.safe_parse(nil).nil?
  raise "should be nil" unless Parser.safe_parse(123).nil?
  raise "should be nil" unless Parser.safe_parse(:K).nil?
  raise "should be nil" unless Parser.safe_parse([:K]).nil?
  raise "should be nil" unless Parser.safe_parse({ abbr: :K }).nil?
end

# ============================================================================
# PARSE - RAISING PATH (specific error messages)
# ============================================================================

puts
puts "parse - empty input:"

Test("raises on empty string") do
  Parser.parse("")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::EMPTY_INPUT
end

puts
puts "parse - input too long:"

Test("raises on 4 characters") do
  Parser.parse("+K^X")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INPUT_TOO_LONG
end

Test("raises on many characters") do
  Parser.parse("invalid")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INPUT_TOO_LONG
end

puts
puts "parse - must contain one letter:"

Test("raises on modifier only") do
  Parser.parse("+")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::MUST_CONTAIN_ONE_LETTER
end

Test("raises on digit only") do
  Parser.parse("1")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::MUST_CONTAIN_ONE_LETTER
end

Test("raises on terminal marker only") do
  Parser.parse("^")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::MUST_CONTAIN_ONE_LETTER
end

Test("raises on non-string type") do
  Parser.parse(nil)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::MUST_CONTAIN_ONE_LETTER
end

puts
puts "parse - invalid terminal marker:"

Test("raises on two letters") do
  Parser.parse("KQ")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_TERMINAL_MARKER
end

Test("raises on letter followed by invalid character") do
  Parser.parse("K!")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_TERMINAL_MARKER
end

Test("raises on letter followed by digit") do
  Parser.parse("K1")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_TERMINAL_MARKER
end

# ============================================================================
# VALID? METHOD
# ============================================================================

puts
puts "valid? method:"

Test("returns true for valid simple letter") do
  raise "should be valid" unless Parser.valid?("K")
  raise "should be valid" unless Parser.valid?("k")
end

Test("returns true for valid with modifiers") do
  raise "should be valid" unless Parser.valid?("+R")
  raise "should be valid" unless Parser.valid?("-p")
  raise "should be valid" unless Parser.valid?("K^")
  raise "should be valid" unless Parser.valid?("+K^")
end

Test("returns false for invalid inputs") do
  raise "should be invalid" if Parser.valid?("")
  raise "should be invalid" if Parser.valid?("KK")
  raise "should be invalid" if Parser.valid?("invalid")
  raise "should be invalid" if Parser.valid?(nil)
end

# ============================================================================
# SECURITY TESTS - NULL BYTE INJECTION
# ============================================================================

puts
puts "Security - null byte injection:"

Test("rejects null byte at end") do
  raise "should be invalid" if Parser.valid?("K\x00")
end

Test("rejects null byte at start") do
  raise "should be invalid" if Parser.valid?("\x00K")
end

Test("rejects null byte in middle") do
  raise "should be invalid" if Parser.valid?("+\x00K")
end

# ============================================================================
# SECURITY TESTS - CONTROL CHARACTERS
# ============================================================================

puts
puts "Security - control characters:"

Test("rejects newline") do
  raise "should be invalid" if Parser.valid?("K\n")
  raise "should be invalid" if Parser.valid?("\nK")
end

Test("rejects carriage return") do
  raise "should be invalid" if Parser.valid?("K\r")
  raise "should be invalid" if Parser.valid?("\r\nK")
end

Test("rejects tab") do
  raise "should be invalid" if Parser.valid?("K\t")
  raise "should be invalid" if Parser.valid?("\tK")
end

Test("rejects other control characters") do
  raise "should be invalid" if Parser.valid?("K\x01") # SOH
  raise "should be invalid" if Parser.valid?("K\x1b") # ESC
  raise "should be invalid" if Parser.valid?("K\x7f") # DEL
end

# ============================================================================
# SECURITY TESTS - UNICODE LOOKALIKES
# ============================================================================

puts
puts "Security - Unicode lookalikes:"

Test("rejects Cyrillic lookalikes") do
  raise "should be invalid" if Parser.valid?("\xD0\x9A")  # Cyrillic 'К' (U+041A)
  raise "should be invalid" if Parser.valid?("\xD0\xB0")  # Cyrillic 'а' (U+0430)
end

Test("rejects Greek lookalikes") do
  raise "should be invalid" if Parser.valid?("\xCE\x91")  # Greek 'Α' (U+0391)
end

Test("rejects full-width characters") do
  raise "should be invalid" if Parser.valid?("\xEF\xBC\xAB")  # Full-width 'K' (U+FF2B)
  raise "should be invalid" if Parser.valid?("\xEF\xBD\x8B")  # Full-width 'k' (U+FF4B)
end

# ============================================================================
# SECURITY TESTS - COMBINING CHARACTERS
# ============================================================================

puts
puts "Security - combining characters:"

Test("rejects combining acute accent") do
  raise "should be invalid" if Parser.valid?("K\xCC\x81")  # U+0301
end

Test("rejects combining diaeresis") do
  raise "should be invalid" if Parser.valid?("K\xCC\x88")  # U+0308
end

# ============================================================================
# SECURITY TESTS - ZERO-WIDTH CHARACTERS
# ============================================================================

puts
puts "Security - zero-width characters:"

Test("rejects zero-width space") do
  raise "should be invalid" if Parser.valid?("K\xE2\x80\x8B")  # U+200B
end

Test("rejects zero-width non-joiner") do
  raise "should be invalid" if Parser.valid?("K\xE2\x80\x8C")  # U+200C
end

Test("rejects BOM") do
  raise "should be invalid" if Parser.valid?("\xEF\xBB\xBFK")  # U+FEFF
end

# ============================================================================
# SECURITY TESTS - NON-STRING INPUT
# ============================================================================

puts
puts "Security - non-string input:"

Test("rejects nil") do
  raise "should be invalid" if Parser.valid?(nil)
end

Test("rejects integer") do
  raise "should be invalid" if Parser.valid?(123)
end

Test("rejects array") do
  raise "should be invalid" if Parser.valid?([:K])
end

Test("rejects hash") do
  raise "should be invalid" if Parser.valid?({ abbr: :K })
end

Test("rejects symbol") do
  raise "should be invalid" if Parser.valid?(:K)
end

# ============================================================================
# ROUND-TRIP TESTS (parse → Identifier.fetch → to_s)
# ============================================================================

puts
puts "Round-trip tests:"

Test("round-trip simple letters") do
  %w[K k Q q R r].each do |pin|
    result = Parser.parse(pin)
    identifier = Id.fetch(result[:abbr], result[:side], result[:state], terminal: result[:terminal])
    raise "round-trip failed for #{pin}" unless identifier.to_s == pin
  end
end

Test("round-trip with state modifiers") do
  %w[+K +k -P -p +R -r].each do |pin|
    result = Parser.parse(pin)
    identifier = Id.fetch(result[:abbr], result[:side], result[:state], terminal: result[:terminal])
    raise "round-trip failed for #{pin}" unless identifier.to_s == pin
  end
end

Test("round-trip with terminal marker") do
  %w[K^ k^ Q^ q^].each do |pin|
    result = Parser.parse(pin)
    identifier = Id.fetch(result[:abbr], result[:side], result[:state], terminal: result[:terminal])
    raise "round-trip failed for #{pin}" unless identifier.to_s == pin
  end
end

Test("round-trip combined") do
  %w[+K^ -k^ +Q^ -q^].each do |pin|
    result = Parser.parse(pin)
    identifier = Id.fetch(result[:abbr], result[:side], result[:state], terminal: result[:terminal])
    raise "round-trip failed for #{pin}" unless identifier.to_s == pin
  end
end

puts
puts "All Parser tests passed!"
puts
