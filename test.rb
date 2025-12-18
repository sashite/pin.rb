#!/usr/bin/env ruby
# frozen_string_literal: true

require "simplecov"

SimpleCov.command_name "Unit Tests"
SimpleCov.start

# Tests for Sashite::Pin (Piece Identifier Notation)
#
# Comprehensive test suite covering:
# - Validation and parsing
# - Symbol-based attributes
# - State modifiers (enhanced, diminished, normal)
# - Terminal marker support
# - Immutability and transformations
# - Equality and hashing
# - Game-specific examples

require_relative "lib/sashite/pin"
require "set"

# Helper function to run a test and report errors
def run_test(name)
  print "  #{name}... "
  yield
  puts "✓ Success"
rescue StandardError => e
  warn "✗ Failure: #{e.message}"
  warn "    #{e.backtrace.first}"
  exit(1)
end

puts
puts "Tests for Sashite::Pin (Piece Identifier Notation)"
puts

# ==============================================================================
# VALIDATION TESTS
# ==============================================================================

run_test("PIN validation accepts valid notations") do
  valid_pins = [
    # Basic pieces
    "K", "k", "Q", "q", "R", "r", "B", "b", "N", "n", "P", "p",
    "A", "a", "Z", "z",
    # Enhanced pieces
    "+K", "+k", "+Q", "+q", "+R", "+r", "+B", "+b", "+N", "+n", "+P", "+p",
    # Diminished pieces
    "-K", "-k", "-Q", "-q", "-R", "-r", "-B", "-b", "-N", "-n", "-P", "-p",
    # Terminal pieces
    "K^", "k^", "Q^", "q^", "R^", "r^",
    # Enhanced terminal pieces
    "+K^", "+k^", "+R^", "+r^",
    # Diminished terminal pieces
    "-K^", "-k^", "-P^", "-p^"
  ]

  valid_pins.each do |pin|
    raise "#{pin.inspect} should be valid" unless Sashite::Pin.valid?(pin)
  end
end

run_test("PIN validation rejects invalid notations") do
  invalid_pins = [
    # Empty and duplicates
    "", "KK", "++K", "--K", "+-K", "-+K", "K+", "K-", "+", "-",
    # Numbers and special characters
    "1", "9", "0", "!", "@", "#", "$", "%", "&", "*", "(", ")",
    # Whitespace
    " K", "K ", " +K", "+K ", "k+", "k-", "Kk", "kK",
    # Invalid combinations
    "123", "ABC", "abc", "K1", "1K", "+1", "-1", "1+", "1-",
    # Invalid terminal marker positions
    "^K", "^k", "K^^", "k^^", "+^K", "-^k", "K^+", "k^-", "^+K", "^-k"
  ]

  invalid_pins.each do |pin|
    raise "#{pin.inspect} should be invalid" if Sashite::Pin.valid?(pin)
  end
end

run_test("PIN validation handles non-string input") do
  non_strings = [nil, 123, :king, [], {}, true, false, 1.5]

  non_strings.each do |input|
    raise "#{input.inspect} should be invalid" if Sashite::Pin.valid?(input)
  end
end

# ==============================================================================
# PARSING TESTS
# ==============================================================================

run_test("parse creates correct instances with symbol attributes") do
  test_cases = {
    "K" => { type: :K, side: :first, state: :normal, terminal: false, letter: "K" },
    "k" => { type: :K, side: :second, state: :normal, terminal: false, letter: "k" },
    "+R" => { type: :R, side: :first, state: :enhanced, terminal: false, letter: "R" },
    "-p" => { type: :P, side: :second, state: :diminished, terminal: false, letter: "p" },
    "K^" => { type: :K, side: :first, state: :normal, terminal: true, letter: "K" },
    "+R^" => { type: :R, side: :first, state: :enhanced, terminal: true, letter: "R" },
    "-k^" => { type: :K, side: :second, state: :diminished, terminal: true, letter: "k" }
  }

  test_cases.each do |pin_string, expected|
    pin = Sashite::Pin.parse(pin_string)

    raise "#{pin_string}: wrong type" unless pin.type == expected[:type]
    raise "#{pin_string}: wrong side" unless pin.side == expected[:side]
    raise "#{pin_string}: wrong state" unless pin.state == expected[:state]
    raise "#{pin_string}: wrong terminal" unless pin.terminal? == expected[:terminal]
    raise "#{pin_string}: wrong letter" unless pin.letter == expected[:letter]
  end
end

run_test("parse handles terminal markers") do
  pin_string = "+R^"
  pin = Sashite::Pin.parse(pin_string)

  raise "parse should return Pin instance" unless pin.is_a?(Sashite::Pin)
  raise "pin should be terminal" unless pin.terminal?
  raise "pin should have correct PIN string" unless pin.to_s == pin_string
end

# ==============================================================================
# CREATION TESTS
# ==============================================================================

run_test("new creates instances with symbol parameters") do
  test_cases = [
    [:K, :first, :normal, false, "K"],
    [:K, :second, :normal, false, "k"],
    [:R, :first, :enhanced, false, "+R"],
    [:P, :second, :diminished, false, "-p"],
    [:K, :first, :normal, true, "K^"],
    [:R, :first, :enhanced, true, "+R^"],
    [:P, :second, :diminished, true, "-p^"]
  ]

  test_cases.each do |type, side, state, terminal, expected_pin|
    pin = Sashite::Pin.new(type, side, state, terminal: terminal)

    raise "type should be #{type}" unless pin.type == type
    raise "side should be #{side}" unless pin.side == side
    raise "state should be #{state}" unless pin.state == state
    raise "terminal should be #{terminal}" unless pin.terminal? == terminal
    raise "PIN string should be #{expected_pin}" unless pin.to_s == expected_pin
  end
end

run_test("new defaults state to :normal and terminal to false") do
  pin = Sashite::Pin.new(:K, :first)

  raise "state should default to :normal" unless pin.state == :normal
  raise "terminal should default to false" if pin.terminal?
  raise "to_s should be K" unless pin.to_s == "K"
end

# ==============================================================================
# TO_STRING AND DISPLAY TESTS
# ==============================================================================

run_test("to_s returns correct PIN string") do
  test_cases = [
    [:K, :first, :normal, false, "K"],
    [:K, :second, :normal, false, "k"],
    [:R, :first, :enhanced, false, "+R"],
    [:P, :second, :diminished, false, "-p"],
    [:K, :first, :normal, true, "K^"],
    [:R, :first, :enhanced, true, "+R^"],
    [:P, :second, :diminished, true, "-p^"]
  ]

  test_cases.each do |type, side, state, terminal, expected|
    pin = Sashite::Pin.new(type, side, state, terminal: terminal)
    result = pin.to_s

    raise "#{type}, #{side}, #{state}, #{terminal} should be #{expected}, got #{result}" unless result == expected
  end
end

run_test("letter and prefix methods") do
  test_cases = [
    ["K", "K", ""],
    ["k", "k", ""],
    ["+R", "R", "+"],
    ["-p", "p", "-"],
    ["K^", "K", ""],
    ["+R^", "R", "+"],
    ["-p^", "p", "-"]
  ]

  test_cases.each do |pin_string, expected_letter, expected_prefix|
    pin = Sashite::Pin.parse(pin_string)

    raise "#{pin_string}: wrong letter" unless pin.letter == expected_letter
    raise "#{pin_string}: wrong prefix" unless pin.prefix == expected_prefix
  end
end

run_test("suffix method") do
  test_cases = [
    ["K", ""],
    ["k", ""],
    ["+R", ""],
    ["K^", "^"],
    ["k^", "^"],
    ["+R^", "^"],
    ["-p^", "^"]
  ]

  test_cases.each do |pin_string, expected_suffix|
    pin = Sashite::Pin.parse(pin_string)

    raise "#{pin_string}: wrong suffix" unless pin.suffix == expected_suffix
  end
end

run_test("to_s equals prefix + letter + suffix") do
  test_cases = ["K", "k", "+R", "-p", "K^", "+R^", "-p^"]

  test_cases.each do |pin_string|
    pin = Sashite::Pin.parse(pin_string)
    expected = "#{pin.prefix}#{pin.letter}#{pin.suffix}"

    raise "#{pin_string}: to_s should equal prefix + letter + suffix" unless pin.to_s == expected
  end
end

# ==============================================================================
# STATE TRANSFORMATION TESTS
# ==============================================================================

run_test("state transformations return new instances") do
  pin = Sashite::Pin.new(:K, :first, :normal, terminal: false)

  # Test enhance
  enhanced = pin.enhance
  raise "enhance should return new instance" if enhanced.equal?(pin)
  raise "enhanced pin should be enhanced" unless enhanced.enhanced?
  raise "enhanced pin state should be :enhanced" unless enhanced.state == :enhanced
  raise "original pin should be unchanged" unless pin.state == :normal
  raise "enhanced pin should have same type and side" unless enhanced.type == pin.type && enhanced.side == pin.side

  # Test diminish
  diminished = pin.diminish
  raise "diminish should return new instance" if diminished.equal?(pin)
  raise "diminished pin should be diminished" unless diminished.diminished?
  raise "diminished pin state should be :diminished" unless diminished.state == :diminished
  raise "original pin should be unchanged" unless pin.state == :normal

  # Test flip
  flipped = pin.flip
  raise "flip should return new instance" if flipped.equal?(pin)
  raise "flipped pin should have opposite side" unless flipped.side == :second
  raise "flipped pin should have same type and state" unless flipped.type == pin.type && flipped.state == pin.state
  raise "original pin should be unchanged" unless pin.side == :first
end

run_test("state transformations preserve terminal status") do
  terminal_pin = Sashite::Pin.new(:K, :first, :normal, terminal: true)

  # Test enhance preserves terminal
  enhanced = terminal_pin.enhance
  raise "enhance should preserve terminal" unless enhanced.terminal?
  raise "enhanced terminal PIN should be +K^" unless enhanced.to_s == "+K^"

  # Test diminish preserves terminal
  diminished = terminal_pin.diminish
  raise "diminish should preserve terminal" unless diminished.terminal?
  raise "diminished terminal PIN should be -K^" unless diminished.to_s == "-K^"

  # Test flip preserves terminal
  flipped = terminal_pin.flip
  raise "flip should preserve terminal" unless flipped.terminal?
  raise "flipped terminal PIN should be k^" unless flipped.to_s == "k^"
end

run_test("attribute transformations") do
  pin = Sashite::Pin.new(:K, :first, :normal, terminal: false)

  # Test with_type
  queen = pin.with_type(:Q)
  raise "with_type should return new instance" if queen.equal?(pin)
  raise "new pin should have different type" unless queen.type == :Q
  raise "new pin should have same side and state" unless queen.side == pin.side && queen.state == pin.state

  # Test with_side
  second_king = pin.with_side(:second)
  raise "with_side should return new instance" if second_king.equal?(pin)
  raise "new pin should have different side" unless second_king.side == :second
  raise "new pin should have same type and state" unless second_king.type == pin.type && second_king.state == pin.state

  # Test with_state
  enhanced_king = pin.with_state(:enhanced)
  raise "with_state should return new instance" if enhanced_king.equal?(pin)
  raise "new pin should have different state" unless enhanced_king.state == :enhanced
  raise "new pin should have same type and side" unless enhanced_king.type == pin.type && enhanced_king.side == pin.side
end

run_test("attribute transformations preserve terminal status") do
  terminal_pin = Sashite::Pin.new(:K, :first, :normal, terminal: true)

  # Test with_type preserves terminal
  queen = terminal_pin.with_type(:Q)
  raise "with_type should preserve terminal" unless queen.terminal?
  raise "queen terminal PIN should be Q^" unless queen.to_s == "Q^"

  # Test with_side preserves terminal
  second_king = terminal_pin.with_side(:second)
  raise "with_side should preserve terminal" unless second_king.terminal?
  raise "second player terminal PIN should be k^" unless second_king.to_s == "k^"

  # Test with_state preserves terminal
  enhanced = terminal_pin.with_state(:enhanced)
  raise "with_state should preserve terminal" unless enhanced.terminal?
  raise "enhanced terminal PIN should be +K^" unless enhanced.to_s == "+K^"
end

# ==============================================================================
# TERMINAL MARKER TESTS
# ==============================================================================

run_test("terminal? method") do
  terminal_pin = Sashite::Pin.parse("K^")
  normal_pin = Sashite::Pin.parse("K")

  raise "K^ should be terminal" unless terminal_pin.terminal?
  raise "K should not be terminal" if normal_pin.terminal?
end

run_test("mark_terminal method") do
  pin = Sashite::Pin.new(:K, :first, :normal, terminal: false)
  terminal_pin = pin.mark_terminal

  raise "mark_terminal should return new instance" if terminal_pin.equal?(pin)
  raise "new pin should be terminal" unless terminal_pin.terminal?
  raise "new pin should have same type" unless terminal_pin.type == pin.type
  raise "new pin should have same side" unless terminal_pin.side == pin.side
  raise "new pin should have same state" unless terminal_pin.state == pin.state
  raise "original pin should be unchanged" if pin.terminal?
  raise "terminal PIN should be K^" unless terminal_pin.to_s == "K^"
end

run_test("mark_terminal returns self if already terminal") do
  pin = Sashite::Pin.new(:K, :first, :normal, terminal: true)
  result = pin.mark_terminal

  raise "mark_terminal should return self if already terminal" unless result.equal?(pin)
end

run_test("unmark_terminal method") do
  terminal_pin = Sashite::Pin.new(:K, :first, :normal, terminal: true)
  normal_pin = terminal_pin.unmark_terminal

  raise "unmark_terminal should return new instance" if normal_pin.equal?(terminal_pin)
  raise "new pin should not be terminal" if normal_pin.terminal?
  raise "new pin should have same type" unless normal_pin.type == terminal_pin.type
  raise "original pin should be unchanged" unless terminal_pin.terminal?
  raise "normal PIN should be K" unless normal_pin.to_s == "K"
end

run_test("unmark_terminal returns self if already non-terminal") do
  pin = Sashite::Pin.new(:K, :first, :normal, terminal: false)
  result = pin.unmark_terminal

  raise "unmark_terminal should return self if already non-terminal" unless result.equal?(pin)
end

run_test("with_terminal method") do
  pin = Sashite::Pin.new(:K, :first, :normal, terminal: false)

  # Change to terminal
  terminal_pin = pin.with_terminal(true)
  raise "with_terminal(true) should return new instance" if terminal_pin.equal?(pin)
  raise "new pin should be terminal" unless terminal_pin.terminal?

  # Back to non-terminal
  back_to_normal = terminal_pin.with_terminal(false)
  raise "with_terminal(false) should return new instance" if back_to_normal.equal?(terminal_pin)
  raise "new pin should not be terminal" if back_to_normal.terminal?
end

run_test("with_terminal returns self if same status") do
  terminal_pin = Sashite::Pin.new(:K, :first, :normal, terminal: true)
  result = terminal_pin.with_terminal(true)
  raise "with_terminal(true) should return self if already terminal" unless result.equal?(terminal_pin)

  normal_pin = Sashite::Pin.new(:K, :first, :normal, terminal: false)
  result2 = normal_pin.with_terminal(false)
  raise "with_terminal(false) should return self if already non-terminal" unless result2.equal?(normal_pin)
end

run_test("normalize preserves terminal status") do
  terminal_enhanced = Sashite::Pin.new(:K, :first, :enhanced, terminal: true)
  normalized = terminal_enhanced.normalize

  raise "normalize should preserve terminal" unless normalized.terminal?
  raise "normalized terminal PIN should be K^" unless normalized.to_s == "K^"
end

# ==============================================================================
# IMMUTABILITY TESTS
# ==============================================================================

run_test("immutability") do
  pin = Sashite::Pin.new(:R, :first, :enhanced, terminal: true)

  # Test that pin is frozen
  raise "pin should be frozen" unless pin.frozen?

  # Test that mutations don't affect original
  original_string = pin.to_s
  normalized = pin.normalize

  raise "original pin should be unchanged after normalize" unless pin.to_s == original_string
  raise "normalized pin should have removed state modifier" unless normalized.to_s == "R^"
  raise "normalized pin should still be terminal" unless normalized.terminal?
end

run_test("transformation methods return self when appropriate") do
  normal_pin = Sashite::Pin.new(:K, :first, :normal, terminal: false)
  enhanced_pin = Sashite::Pin.new(:K, :first, :enhanced, terminal: false)
  diminished_pin = Sashite::Pin.new(:K, :first, :diminished, terminal: false)

  # Test methods that should return self
  raise "normalize on normal pin should return self" unless normal_pin.normalize.equal?(normal_pin)
  raise "enhance on enhanced pin should return self" unless enhanced_pin.enhance.equal?(enhanced_pin)
  raise "diminish on diminished pin should return self" unless diminished_pin.diminish.equal?(diminished_pin)

  # Test with_* methods that should return self
  raise "with_type with same type should return self" unless normal_pin.with_type(:K).equal?(normal_pin)
  raise "with_side with same side should return self" unless normal_pin.with_side(:first).equal?(normal_pin)
  raise "with_state with same state should return self" unless normal_pin.with_state(:normal).equal?(normal_pin)
end

run_test("transformation chains") do
  pin = Sashite::Pin.new(:K, :first, :normal, terminal: false)

  # Test complex chain without terminal
  transformed = pin.flip.enhance.with_type(:Q).diminish
  expected_final = "-q"

  raise "complex chain should work" unless transformed.to_s == expected_final
  raise "original should be unchanged" unless pin.to_s == "K"

  # Test complex chain with terminal
  terminal_pin = Sashite::Pin.new(:K, :first, :normal, terminal: true)
  terminal_transformed = terminal_pin.flip.enhance.with_type(:Q).diminish
  expected_final_terminal = "-q^"

  raise "complex chain should preserve terminal" unless terminal_transformed.terminal?
  raise "complex chain with terminal should work" unless terminal_transformed.to_s == expected_final_terminal
  raise "original terminal pin should be unchanged" unless terminal_pin.to_s == "K^"
end

# ==============================================================================
# EQUALITY AND HASH TESTS
# ==============================================================================

run_test("equality and hash") do
  pin1 = Sashite::Pin.new(:K, :first, :normal, terminal: false)
  pin2 = Sashite::Pin.new(:K, :first, :normal, terminal: false)
  pin3 = Sashite::Pin.new(:K, :second, :normal, terminal: false)
  pin4 = Sashite::Pin.new(:K, :first, :enhanced, terminal: false)
  pin5 = Sashite::Pin.new(:K, :first, :normal, terminal: true)

  # Test equality
  raise "identical pins should be equal" unless pin1 == pin2
  raise "different side should not be equal" if pin1 == pin3
  raise "different state should not be equal" if pin1 == pin4
  raise "different terminal status should not be equal" if pin1 == pin5

  # Test hash consistency
  raise "equal pins should have same hash" unless pin1.hash == pin2.hash

  # Test in hash/set
  pins_set = Set.new([pin1, pin2, pin3, pin4, pin5])
  raise "set should contain 4 unique pins" unless pins_set.size == 4
end

run_test("equality includes terminal status") do
  terminal_pin = Sashite::Pin.new(:K, :first, :normal, terminal: true)
  normal_pin = Sashite::Pin.new(:K, :first, :normal, terminal: false)

  raise "terminal and non-terminal pins should not be equal" if terminal_pin == normal_pin
  raise "terminal pins should have different hash" if terminal_pin.hash == normal_pin.hash
end

# ==============================================================================
# QUERY METHODS TESTS
# ==============================================================================

run_test("type and side identification") do
  test_cases = [
    ["K", :K, :first, true, false],
    ["k", :K, :second, false, true],
    ["+R", :R, :first, true, false],
    ["-p", :P, :second, false, true],
    ["K^", :K, :first, true, false],
    ["k^", :K, :second, false, true]
  ]

  test_cases.each do |pin_string, expected_type, expected_side, is_first, is_second|
    pin = Sashite::Pin.parse(pin_string)

    raise "#{pin_string}: wrong type" unless pin.type == expected_type
    raise "#{pin_string}: wrong side" unless pin.side == expected_side
    raise "#{pin_string}: wrong first_player?" unless pin.first_player? == is_first
    raise "#{pin_string}: wrong second_player?" unless pin.second_player? == is_second
  end
end

run_test("same_type?, same_side?, and same_state? methods") do
  king1 = Sashite::Pin.new(:K, :first, :normal, terminal: false)
  king2 = Sashite::Pin.new(:K, :second, :enhanced, terminal: false)
  queen = Sashite::Pin.new(:Q, :first, :normal, terminal: false)
  enhanced_queen = Sashite::Pin.new(:Q, :second, :enhanced, terminal: false)

  # same_type? tests
  raise "K and K should be same type" unless king1.same_type?(king2)
  raise "K and Q should not be same type" if king1.same_type?(queen)

  # same_side? tests
  raise "first player pins should be same side" unless king1.same_side?(queen)
  raise "different side pins should not be same side" if king1.same_side?(king2)

  # same_state? tests
  raise "normal pins should be same state" unless king1.same_state?(queen)
  raise "enhanced pins should be same state" unless king2.same_state?(enhanced_queen)
  raise "different state pins should not be same state" if king1.same_state?(king2)
end

run_test("same_terminal? method") do
  terminal_king = Sashite::Pin.new(:K, :first, :normal, terminal: true)
  terminal_queen = Sashite::Pin.new(:Q, :second, :enhanced, terminal: true)
  normal_king = Sashite::Pin.new(:K, :first, :normal, terminal: false)

  raise "terminal pins should be same_terminal" unless terminal_king.same_terminal?(terminal_queen)
  raise "pins with different terminal status should not be same_terminal" if terminal_king.same_terminal?(normal_king)
end

run_test("state methods") do
  normal = Sashite::Pin.new(:K, :first, :normal, terminal: false)
  enhanced = Sashite::Pin.new(:K, :first, :enhanced, terminal: false)
  diminished = Sashite::Pin.new(:K, :first, :diminished, terminal: false)

  # Test state identification
  raise "normal pin should be normal" unless normal.normal?
  raise "normal pin should not be enhanced" if normal.enhanced?
  raise "normal pin should not be diminished" if normal.diminished?
  raise "normal pin state should be :normal" unless normal.state == :normal

  raise "enhanced pin should be enhanced" unless enhanced.enhanced?
  raise "enhanced pin should not be normal" if enhanced.normal?
  raise "enhanced pin state should be :enhanced" unless enhanced.state == :enhanced

  raise "diminished pin should be diminished" unless diminished.diminished?
  raise "diminished pin should not be normal" if diminished.normal?
  raise "diminished pin state should be :diminished" unless diminished.state == :diminished
end

# ==============================================================================
# ERROR HANDLING TESTS
# ==============================================================================

run_test("error handling for invalid symbols") do
  # Invalid types
  invalid_types = [:invalid, :k, :"1", :AA, "K", 1, nil]

  invalid_types.each do |type|
    begin
      Sashite::Pin.new(type, :first, :normal)
      raise "Should have raised error for invalid type #{type.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid type" unless e.message.include?("Type must be")
    end
  end

  # Invalid sides
  invalid_sides = [:invalid, :player1, :white, "first", 1, nil]

  invalid_sides.each do |side|
    begin
      Sashite::Pin.new(:K, side, :normal)
      raise "Should have raised error for invalid side #{side.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid side" unless e.message.include?("Side must be")
    end
  end

  # Invalid states
  invalid_states = [:invalid, :promoted, :active, "normal", 1, nil]

  invalid_states.each do |state|
    begin
      Sashite::Pin.new(:K, :first, state)
      raise "Should have raised error for invalid state #{state.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid state" unless e.message.include?("State must be")
    end
  end
end

run_test("error handling for invalid PIN strings") do
  invalid_pins = ["", "KK", "++K", "123", nil, :symbol, "^K", "K^^"]

  invalid_pins.each do |pin|
    begin
      Sashite::Pin.parse(pin)
      raise "Should have raised error for #{pin.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid PIN" unless e.message.include?("Invalid PIN")
    end
  end
end

# ==============================================================================
# GAME-SPECIFIC EXAMPLES
# ==============================================================================

run_test("Western Chess pieces") do
  # Standard pieces
  king = Sashite::Pin.new(:K, :first, :normal, terminal: true)
  raise "King should be first player" unless king.first_player?
  raise "King type should be :K" unless king.type == :K
  raise "King should be terminal" unless king.terminal?
  raise "King PIN should be K^" unless king.to_s == "K^"

  # State modifiers (conceptual examples)
  castling_king = king.enhance
  raise "Castling king should be enhanced" unless castling_king.enhanced?
  raise "Castling king should remain terminal" unless castling_king.terminal?
  raise "Castling king PIN should be +K^" unless castling_king.to_s == "+K^"

  pawn = Sashite::Pin.new(:P, :first, :normal, terminal: false)
  vulnerable_pawn = pawn.diminish
  raise "Vulnerable pawn should be diminished" unless vulnerable_pawn.diminished?
  raise "Vulnerable pawn should not be terminal" if vulnerable_pawn.terminal?
  raise "Vulnerable pawn PIN should be -P" unless vulnerable_pawn.to_s == "-P"
end

run_test("Japanese Chess (Shogi) pieces") do
  # Basic pieces
  rook = Sashite::Pin.new(:R, :first, :normal, terminal: false)
  bishop = Sashite::Pin.new(:B, :first, :normal, terminal: false)

  # Terminal king
  king = Sashite::Pin.new(:K, :first, :normal, terminal: true)
  raise "King should be terminal" unless king.terminal?
  raise "King PIN should be K^" unless king.to_s == "K^"

  # Promoted pieces
  dragon_king = rook.enhance
  raise "Dragon King should be enhanced rook" unless dragon_king.enhanced? && dragon_king.type == :R
  raise "Dragon King PIN should be +R" unless dragon_king.to_s == "+R"

  dragon_horse = bishop.enhance
  raise "Dragon Horse should be enhanced bishop" unless dragon_horse.enhanced? && dragon_horse.type == :B
  raise "Dragon Horse PIN should be +B" unless dragon_horse.to_s == "+B"

  # Promoted pawn (Tokin)
  pawn = Sashite::Pin.new(:P, :first, :normal, terminal: false)
  tokin = pawn.enhance
  raise "Tokin should be enhanced pawn" unless tokin.enhanced? && tokin.type == :P
  raise "Tokin PIN should be +P" unless tokin.to_s == "+P"
end

run_test("Chinese Chess (Xiangqi) pieces") do
  # Terminal generals
  red_general = Sashite::Pin.new(:G, :first, :normal, terminal: true)
  black_general = Sashite::Pin.new(:G, :second, :normal, terminal: true)

  raise "Red general should be terminal" unless red_general.terminal?
  raise "Black general should be terminal" unless black_general.terminal?
  raise "Red general PIN should be G^" unless red_general.to_s == "G^"
  raise "Black general PIN should be g^" unless black_general.to_s == "g^"

  # Non-terminal pieces
  advisor = Sashite::Pin.new(:A, :first, :normal, terminal: false)
  raise "Advisor should not be terminal" if advisor.terminal?
  raise "Advisor PIN should be A" unless advisor.to_s == "A"
end

run_test("Cross-game piece transformations") do
  # Test that pieces can be transformed across different contexts
  pin = Sashite::Pin.new(:K, :first, :normal, terminal: false)

  # Chain transformations
  transformed = pin.flip.enhance.flip.diminish
  expected_final = "-K"

  raise "Chained transformation should work" unless transformed.to_s == expected_final
  raise "Original pin should be unchanged" unless pin.to_s == "K"

  # Chain transformations with terminal
  terminal_pin = Sashite::Pin.new(:K, :first, :normal, terminal: true)
  terminal_transformed = terminal_pin.flip.enhance.flip.diminish
  expected_final_terminal = "-K^"

  raise "Chained transformation with terminal should work" unless terminal_transformed.to_s == expected_final_terminal
  raise "Terminal status should be preserved" unless terminal_transformed.terminal?
end

# ==============================================================================
# PRACTICAL USAGE SCENARIOS
# ==============================================================================

run_test("Practical usage - piece collections") do
  pins = [
    Sashite::Pin.new(:K, :first, :normal, terminal: true),
    Sashite::Pin.new(:Q, :first, :normal, terminal: false),
    Sashite::Pin.new(:R, :first, :enhanced, terminal: false),
    Sashite::Pin.new(:K, :second, :normal, terminal: true)
  ]

  # Filter by side
  first_player_pins = pins.select(&:first_player?)
  raise "Should have 3 first player pins" unless first_player_pins.size == 3

  # Group by type
  by_type = pins.group_by(&:type)
  raise "Should have kings grouped" unless by_type[:K].size == 2

  # Find promoted pieces
  promoted = pins.select(&:enhanced?)
  raise "Should have 1 promoted pin" unless promoted.size == 1
  raise "Promoted pin should be rook" unless promoted.first.type == :R

  # Find terminal pieces
  terminal_pins = pins.select(&:terminal?)
  raise "Should have 2 terminal pins" unless terminal_pins.size == 2
  raise "All terminal pins should be kings" unless terminal_pins.all? { |p| p.type == :K }
end

run_test("Practical usage - game state simulation") do
  # Simulate promoting a pawn
  pawn = Sashite::Pin.new(:P, :first, :normal, terminal: false)
  raise "Pawn should be normal initially" unless pawn.normal?

  # Promote to queen using with_type and enhance
  promoted = pawn.with_type(:Q).enhance
  raise "Promoted pin should be queen" unless promoted.type == :Q
  raise "Promoted pin should be enhanced" unless promoted.enhanced?
  raise "Original pawn should be unchanged" unless pawn.normal? && pawn.type == :P

  # Simulate capturing and flipping
  captured = promoted.flip
  raise "Captured pin should be second player" unless captured.second_player?
  raise "Captured pin should still be enhanced" unless captured.enhanced?
  raise "Captured pin should still be queen" unless captured.type == :Q

  # Simulate king under threat (conceptual - diminished state)
  king = Sashite::Pin.new(:K, :first, :normal, terminal: true)
  threatened_king = king.diminish
  raise "Threatened king should be diminished" unless threatened_king.diminished?
  raise "Threatened king should remain terminal" unless threatened_king.terminal?
  raise "Threatened king PIN should be -K^" unless threatened_king.to_s == "-K^"
end

# ==============================================================================
# EDGE CASES
# ==============================================================================

run_test("Edge case - all letters of alphabet") do
  letters = ("A".."Z").to_a

  letters.each do |letter|
    type_symbol = letter.to_sym

    # Test first player
    pin1 = Sashite::Pin.new(type_symbol, :first, :normal, terminal: false)
    raise "#{letter} should create valid pin" unless pin1.type == type_symbol
    raise "#{letter} should be first player" unless pin1.first_player?
    raise "#{letter} should have correct letter" unless pin1.letter == letter

    # Test second player
    pin2 = Sashite::Pin.new(type_symbol, :second, :normal, terminal: false)
    raise "#{letter} should create valid pin" unless pin2.type == type_symbol
    raise "#{letter} should be second player" unless pin2.second_player?
    raise "#{letter} should have correct letter" unless pin2.letter == letter.downcase

    # Test enhanced state
    enhanced = pin1.enhance
    raise "#{letter} enhanced should work" unless enhanced.enhanced?
    raise "#{letter} enhanced should have + prefix" unless enhanced.prefix == "+"

    # Test diminished state
    diminished = pin1.diminish
    raise "#{letter} diminished should work" unless diminished.diminished?
    raise "#{letter} diminished should have - prefix" unless diminished.prefix == "-"

    # Test terminal marker
    terminal = pin1.mark_terminal
    raise "#{letter} terminal should work" unless terminal.terminal?
    raise "#{letter} terminal should have ^ suffix" unless terminal.suffix == "^"
    raise "#{letter} terminal PIN should be #{letter}^" unless terminal.to_s == "#{letter}^"
  end
end

run_test("Edge case - unicode and special characters still invalid") do
  unicode_chars = ["α", "β", "♕", "♔", "🀄", "象", "將"]

  unicode_chars.each do |char|
    raise "#{char.inspect} should be invalid (not ASCII)" if Sashite::Pin.valid?(char)
    raise "#{char.inspect} with + should be invalid" if Sashite::Pin.valid?("+#{char}")
    raise "#{char.inspect} with - should be invalid" if Sashite::Pin.valid?("-#{char}")
    raise "#{char.inspect} with ^ should be invalid" if Sashite::Pin.valid?("#{char}^")
  end
end

run_test("Edge case - whitespace handling") do
  whitespace_cases = [
    " K", "K ", " +K", "+K ", " -K", "-K ",
    "\tK", "K\t", "\n+K", "+K\n", " K ", "\t+K\t",
    " K^", "K^ ", " +K^", "+K^ "
  ]

  whitespace_cases.each do |pin|
    raise "#{pin.inspect} should be invalid (whitespace)" if Sashite::Pin.valid?(pin)
  end
end

run_test("Edge case - multiple modifiers") do
  multiple_modifiers = ["++K", "--K", "+-K", "-+K", "+++K", "---K", "++K^", "--K^"]

  multiple_modifiers.each do |pin|
    raise "#{pin.inspect} should be invalid (multiple modifiers)" if Sashite::Pin.valid?(pin)
  end
end

# ==============================================================================
# REGEX COMPLIANCE
# ==============================================================================

run_test("Regex pattern compliance") do
  # Test against the specification regex: \A[-+]?[A-Za-z]\^?\z
  spec_regex = /\A[-+]?[A-Za-z]\^?\z/

  test_strings = [
    "K", "k", "+K", "+k", "-K", "-k", "A", "z", "+A", "-z",
    "K^", "k^", "+K^", "+k^", "-K^", "-k^",
    "", "KK", "++K", "--K", "K+", "K-", "+", "-", "1", "!",
    "^K", "K^^", "+^K", "K^+"
  ]

  test_strings.each do |string|
    spec_match = string.match?(spec_regex)
    pin_valid = Sashite::Pin.valid?(string)

    raise "#{string.inspect}: spec regex and PIN validation disagree" unless spec_match == pin_valid
  end
end

# ==============================================================================
# CONSTANTS
# ==============================================================================

run_test("Class constants are properly defined") do
  # Test type constants
  raise "VALID_TYPES should contain 26 symbols" unless Sashite::Pin::VALID_TYPES.size == 26
  raise "VALID_TYPES should include :K" unless Sashite::Pin::VALID_TYPES.include?(:K)
  raise "VALID_TYPES should include :A" unless Sashite::Pin::VALID_TYPES.include?(:A)
  raise "VALID_TYPES should include :Z" unless Sashite::Pin::VALID_TYPES.include?(:Z)

  # Test side constants
  raise "VALID_SIDES should contain :first and :second" unless Sashite::Pin::VALID_SIDES == %i[first second]

  # Test state constants
  raise "VALID_STATES should contain :normal, :enhanced, :diminished" unless Sashite::Pin::VALID_STATES == %i[normal enhanced diminished]

  # Test pattern constant
  raise "PIN_PATTERN should be a Regexp" unless Sashite::Pin::PIN_PATTERN.is_a?(Regexp)
end

run_test("Regular expression constant is correctly defined") do
  regex = Sashite::Pin::PIN_PATTERN

  raise "PIN_PATTERN should match valid PINs" unless "K".match?(regex)
  raise "PIN_PATTERN should match enhanced PINs" unless "+R".match?(regex)
  raise "PIN_PATTERN should match terminal PINs" unless "K^".match?(regex)
  raise "PIN_PATTERN should match enhanced terminal PINs" unless "+R^".match?(regex)
  raise "PIN_PATTERN should not match invalid PINs" if "KK".match?(regex)
  raise "PIN_PATTERN should not match terminal in wrong place" if "^K".match?(regex)
end

# ==============================================================================
# ROUNDTRIP PARSING
# ==============================================================================

run_test("Roundtrip parsing consistency") do
  test_cases = [
    [:K, :first, :normal, false],
    [:Q, :second, :enhanced, false],
    [:P, :first, :diminished, false],
    [:Z, :second, :normal, false],
    [:K, :first, :normal, true],
    [:Q, :second, :enhanced, true],
    [:P, :first, :diminished, true]
  ]

  test_cases.each do |type, side, state, terminal|
    # Create pin -> to_s -> parse -> compare
    original = Sashite::Pin.new(type, side, state, terminal: terminal)
    pin_string = original.to_s
    parsed = Sashite::Pin.parse(pin_string)

    raise "Roundtrip failed: original != parsed" unless original == parsed
    raise "Roundtrip failed: different type" unless original.type == parsed.type
    raise "Roundtrip failed: different side" unless original.side == parsed.side
    raise "Roundtrip failed: different state" unless original.state == parsed.state
    raise "Roundtrip failed: different terminal" unless original.terminal? == parsed.terminal?
  end
end

# ==============================================================================
# INSPECT
# ==============================================================================

run_test("inspect returns readable representation") do
  pin = Sashite::Pin.new(:K, :first, :normal, terminal: false)
  inspect_string = pin.inspect

  raise "inspect should include class name" unless inspect_string.include?("Sashite::Pin")
  raise "inspect should include PIN string" unless inspect_string.include?("K")

  terminal_pin = Sashite::Pin.new(:K, :first, :enhanced, terminal: true)
  terminal_inspect = terminal_pin.inspect

  raise "inspect should include terminal PIN" unless terminal_inspect.include?("+K^")
end

# ==============================================================================
# PERFORMANCE
# ==============================================================================

run_test("Performance - repeated operations") do
  1000.times do
    pin = Sashite::Pin.new(:K, :first, :normal, terminal: false)
    terminal_pin = Sashite::Pin.new(:K, :first, :normal, terminal: true)
    enhanced = pin.enhance
    flipped = pin.flip
    queen = pin.with_type(:Q)
    marked = pin.mark_terminal

    raise "Performance test failed" unless Sashite::Pin.valid?("K")
    raise "Performance test failed" unless Sashite::Pin.valid?("K^")
    raise "Performance test failed" unless enhanced.enhanced?
    raise "Performance test failed" unless flipped.second_player?
    raise "Performance test failed" unless queen.type == :Q
    raise "Performance test failed" unless marked.terminal?
    raise "Performance test failed" unless terminal_pin.terminal?
  end
end

puts
puts "All PIN tests passed!"
puts
