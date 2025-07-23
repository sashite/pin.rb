# frozen_string_literal: true

require "simplecov"

SimpleCov.command_name "Unit Tests"
SimpleCov.start

# Tests for Sashite::Pin (Piece Identifier Notation)
#
# Tests the PIN implementation for Ruby, focusing on the modern object-oriented API
# with the Identifier class using symbol-based attributes and the minimal module interface.

require_relative "lib/sashite-pin"
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

# Test basic validation (module level)
run_test("Module PIN validation accepts valid notations") do
  valid_pins = [
    "K", "k", "Q", "q", "R", "r", "B", "b", "N", "n", "P", "p",
    "A", "a", "Z", "z",
    "+K", "+k", "+Q", "+q", "+R", "+r", "+B", "+b", "+N", "+n", "+P", "+p",
    "-K", "-k", "-Q", "-q", "-R", "-r", "-B", "-b", "-N", "-n", "-P", "-p"
  ]

  valid_pins.each do |pin|
    raise "#{pin.inspect} should be valid" unless Sashite::Pin.valid?(pin)
  end
end

run_test("Module PIN validation rejects invalid notations") do
  invalid_pins = [
    "", "KK", "++K", "--K", "+-K", "-+K", "K+", "K-", "+", "-",
    "1", "9", "0", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")",
    " K", "K ", " +K", "+K ", "k+", "k-", "Kk", "kK",
    "123", "ABC", "abc", "K1", "1K", "+1", "-1", "1+", "1-"
  ]

  invalid_pins.each do |pin|
    raise "#{pin.inspect} should be invalid" if Sashite::Pin.valid?(pin)
  end
end

run_test("Module PIN validation handles non-string input") do
  non_strings = [nil, 123, :king, [], {}, true, false, 1.5]

  non_strings.each do |input|
    raise "#{input.inspect} should be invalid" if Sashite::Pin.valid?(input)
  end
end

# Test module parse method delegates to Piece
run_test("Module parse delegates to Identifier class") do
  pin_string = "+R"
  piece = Sashite::Pin.parse(pin_string)

  raise "parse should return Piece instance" unless piece.is_a?(Sashite::Pin::Identifier)
  raise "piece should have correct PIN string" unless piece.to_s == pin_string
end

# Test module piece factory method
run_test("Module piece factory method creates correct instances") do
  piece = Sashite::Pin.identifier(:K, :first, :enhanced)

  raise "piece factory should return Piece instance" unless piece.is_a?(Sashite::Pin::Identifier)
  raise "piece should have correct type" unless piece.type == :K
  raise "piece should have correct side" unless piece.side == :first
  raise "piece should have correct state" unless piece.state == :enhanced
  raise "piece should have correct PIN string" unless piece.to_s == "+K"
end

# Test the Identifier class with new symbol-based API
run_test("Piece.parse creates correct instances with symbol attributes") do
  test_cases = {
    "K" => { type: :K, side: :first, state: :normal, letter: "K" },
    "k" => { type: :K, side: :second, state: :normal, letter: "k" },
    "+R" => { type: :R, side: :first, state: :enhanced, letter: "R" },
    "-p" => { type: :P, side: :second, state: :diminished, letter: "p" }
  }

  test_cases.each do |pin_string, expected|
    piece = Sashite::Pin.parse(pin_string)

    raise "#{pin_string}: wrong type" unless piece.type == expected[:type]
    raise "#{pin_string}: wrong side" unless piece.side == expected[:side]
    raise "#{pin_string}: wrong state" unless piece.state == expected[:state]
    raise "#{pin_string}: wrong letter" unless piece.letter == expected[:letter]
  end
end

run_test("Piece constructor with symbol parameters") do
  test_cases = [
    [:K, :first, :normal, "K"],
    [:K, :second, :normal, "k"],
    [:R, :first, :enhanced, "+R"],
    [:P, :second, :diminished, "-p"]
  ]

  test_cases.each do |type, side, state, expected_pin|
    piece = Sashite::Pin::Identifier.new(type, side, state)

    raise "type should be #{type}" unless piece.type == type
    raise "side should be #{side}" unless piece.side == side
    raise "state should be #{state}" unless piece.state == state
    raise "PIN string should be #{expected_pin}" unless piece.to_s == expected_pin
  end
end

run_test("Piece to_s returns correct PIN string") do
  test_cases = [
    [:K, :first, :normal, "K"],
    [:K, :second, :normal, "k"],
    [:R, :first, :enhanced, "+R"],
    [:P, :second, :diminished, "-p"]
  ]

  test_cases.each do |type, side, state, expected|
    piece = Sashite::Pin::Identifier.new(type, side, state)
    result = piece.to_s

    raise "#{type}, #{side}, #{state} should be #{expected}, got #{result}" unless result == expected
  end
end

run_test("Piece letter and prefix methods") do
  test_cases = [
    ["K", "K", ""],
    ["k", "k", ""],
    ["+R", "R", "+"],
    ["-p", "p", "-"]
  ]

  test_cases.each do |pin_string, expected_letter, expected_prefix|
    piece = Sashite::Pin.parse(pin_string)

    raise "#{pin_string}: wrong letter" unless piece.letter == expected_letter
    raise "#{pin_string}: wrong prefix" unless piece.prefix == expected_prefix
    raise "#{pin_string}: to_s should equal prefix + letter" unless piece.to_s == "#{piece.prefix}#{piece.letter}"
  end
end

run_test("Piece state mutations return new instances") do
  piece = Sashite::Pin::Identifier.new(:K, :first, :normal)

  # Test enhance
  enhanced = piece.enhance
  raise "enhance should return new instance" if enhanced.equal?(piece)
  raise "enhanced piece should be enhanced" unless enhanced.enhanced?
  raise "enhanced piece state should be :enhanced" unless enhanced.state == :enhanced
  raise "original piece should be unchanged" unless piece.state == :normal
  raise "enhanced piece should have same type and side" unless enhanced.type == piece.type && enhanced.side == piece.side

  # Test diminish
  diminished = piece.diminish
  raise "diminish should return new instance" if diminished.equal?(piece)
  raise "diminished piece should be diminished" unless diminished.diminished?
  raise "diminished piece state should be :diminished" unless diminished.state == :diminished
  raise "original piece should be unchanged" unless piece.state == :normal

  # Test flip
  flipped = piece.flip
  raise "flip should return new instance" if flipped.equal?(piece)
  raise "flipped piece should have opposite side" unless flipped.side == :second
  raise "flipped piece should have same type and state" unless flipped.type == piece.type && flipped.state == piece.state
  raise "original piece should be unchanged" unless piece.side == :first
end

run_test("Piece attribute transformations") do
  piece = Sashite::Pin::Identifier.new(:K, :first, :normal)

  # Test with_type
  queen = piece.with_type(:Q)
  raise "with_type should return new instance" if queen.equal?(piece)
  raise "new piece should have different type" unless queen.type == :Q
  raise "new piece should have same side and state" unless queen.side == piece.side && queen.state == piece.state

  # Test with_side
  black_king = piece.with_side(:second)
  raise "with_side should return new instance" if black_king.equal?(piece)
  raise "new piece should have different side" unless black_king.side == :second
  raise "new piece should have same type and state" unless black_king.type == piece.type && black_king.state == piece.state

  # Test with_state
  enhanced_king = piece.with_state(:enhanced)
  raise "with_state should return new instance" if enhanced_king.equal?(piece)
  raise "new piece should have different state" unless enhanced_king.state == :enhanced
  raise "new piece should have same type and side" unless enhanced_king.type == piece.type && enhanced_king.side == piece.side
end

run_test("Piece immutability") do
  piece = Sashite::Pin::Identifier.new(:R, :first, :enhanced)

  # Test that piece is frozen
  raise "piece should be frozen" unless piece.frozen?

  # Test that mutations don't affect original
  original_string = piece.to_s
  normalized = piece.normalize

  raise "original piece should be unchanged after normalize" unless piece.to_s == original_string
  raise "normalized piece should be different" unless normalized.to_s == "R"
end

run_test("Piece equality and hash") do
  piece1 = Sashite::Pin::Identifier.new(:K, :first, :normal)
  piece2 = Sashite::Pin::Identifier.new(:K, :first, :normal)
  piece3 = Sashite::Pin::Identifier.new(:K, :second, :normal)
  piece4 = Sashite::Pin::Identifier.new(:K, :first, :enhanced)

  # Test equality
  raise "identical pieces should be equal" unless piece1 == piece2
  raise "different side should not be equal" if piece1 == piece3
  raise "different state should not be equal" if piece1 == piece4

  # Test hash consistency
  raise "equal pieces should have same hash" unless piece1.hash == piece2.hash

  # Test in hash/set
  pieces_set = Set.new([piece1, piece2, piece3, piece4])
  raise "set should contain 3 unique pieces" unless pieces_set.size == 3
end

run_test("Piece type and side identification") do
  test_cases = [
    ["K", :K, :first, true, false],
    ["k", :K, :second, false, true],
    ["+R", :R, :first, true, false],
    ["-p", :P, :second, false, true]
  ]

  test_cases.each do |pin_string, expected_type, expected_side, is_first, is_second|
    piece = Sashite::Pin.parse(pin_string)

    raise "#{pin_string}: wrong type" unless piece.type == expected_type
    raise "#{pin_string}: wrong side" unless piece.side == expected_side
    raise "#{pin_string}: wrong first_player?" unless piece.first_player? == is_first
    raise "#{pin_string}: wrong second_player?" unless piece.second_player? == is_second
  end
end

run_test("Piece same_type?, same_side?, and same_state? methods") do
  king1 = Sashite::Pin::Identifier.new(:K, :first, :normal)
  king2 = Sashite::Pin::Identifier.new(:K, :second, :enhanced)
  queen = Sashite::Pin::Identifier.new(:Q, :first, :normal)
  enhanced_queen = Sashite::Pin::Identifier.new(:Q, :second, :enhanced)

  # same_type? tests
  raise "K and K should be same type" unless king1.same_type?(king2)
  raise "K and Q should not be same type" if king1.same_type?(queen)

  # same_side? tests (renamed from same_player?)
  raise "first player pieces should be same side" unless king1.same_side?(queen)
  raise "different side pieces should not be same side" if king1.same_side?(king2)

  # same_state? tests
  raise "normal pieces should be same state" unless king1.same_state?(queen)
  raise "enhanced pieces should be same state" unless king2.same_state?(enhanced_queen)
  raise "different state pieces should not be same state" if king1.same_state?(king2)
end

run_test("Piece state methods") do
  normal = Sashite::Pin::Identifier.new(:K, :first, :normal)
  enhanced = Sashite::Pin::Identifier.new(:K, :first, :enhanced)
  diminished = Sashite::Pin::Identifier.new(:K, :first, :diminished)

  # Test state identification
  raise "normal piece should be normal" unless normal.normal?
  raise "normal piece should not be enhanced" if normal.enhanced?
  raise "normal piece should not be diminished" if normal.diminished?
  raise "normal piece state should be :normal" unless normal.state == :normal

  raise "enhanced piece should be enhanced" unless enhanced.enhanced?
  raise "enhanced piece should not be normal" if enhanced.normal?
  raise "enhanced piece state should be :enhanced" unless enhanced.state == :enhanced

  raise "diminished piece should be diminished" unless diminished.diminished?
  raise "diminished piece should not be normal" if diminished.normal?
  raise "diminished piece state should be :diminished" unless diminished.state == :diminished
end

run_test("Piece transformation methods return self when appropriate") do
  normal_piece = Sashite::Pin::Identifier.new(:K, :first, :normal)
  enhanced_piece = Sashite::Pin::Identifier.new(:K, :first, :enhanced)
  diminished_piece = Sashite::Pin::Identifier.new(:K, :first, :diminished)

  # Test methods that should return self
  raise "unenhance on normal piece should return self" unless normal_piece.unenhance.equal?(normal_piece)
  raise "undiminish on normal piece should return self" unless normal_piece.undiminish.equal?(normal_piece)
  raise "normalize on normal piece should return self" unless normal_piece.normalize.equal?(normal_piece)
  raise "enhance on enhanced piece should return self" unless enhanced_piece.enhance.equal?(enhanced_piece)
  raise "diminish on diminished piece should return self" unless diminished_piece.diminish.equal?(diminished_piece)

  # Test with_* methods that should return self
  raise "with_type with same type should return self" unless normal_piece.with_type(:K).equal?(normal_piece)
  raise "with_side with same side should return self" unless normal_piece.with_side(:first).equal?(normal_piece)
  raise "with_state with same state should return self" unless normal_piece.with_state(:normal).equal?(normal_piece)
end

run_test("Piece transformation chains") do
  piece = Sashite::Pin::Identifier.new(:K, :first, :normal)

  # Test enhance then unenhance
  enhanced = piece.enhance
  back_to_normal = enhanced.unenhance
  raise "enhance then unenhance should equal original" unless back_to_normal == piece

  # Test diminish then undiminish
  diminished = piece.diminish
  back_to_normal2 = diminished.undiminish
  raise "diminish then undiminish should equal original" unless back_to_normal2 == piece

  # Test complex chain
  transformed = piece.flip.enhance.with_type(:Q).diminish
  raise "complex chain should work" unless transformed.to_s == "-q"
  raise "original should be unchanged" unless piece.to_s == "K"
end

run_test("Piece error handling for invalid symbols") do
  # Invalid types
  invalid_types = [:invalid, :k, :"1", :AA, "K", 1, nil]

  invalid_types.each do |type|
    begin
      Sashite::Pin::Identifier.new(type, :first, :normal)
      raise "Should have raised error for invalid type #{type.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid type" unless e.message.include?("Type must be")
    end
  end

  # Invalid sides
  invalid_sides = [:invalid, :player1, :white, "first", 1, nil]

  invalid_sides.each do |side|
    begin
      Sashite::Pin::Identifier.new(:K, side, :normal)
      raise "Should have raised error for invalid side #{side.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid side" unless e.message.include?("Side must be")
    end
  end

  # Invalid states
  invalid_states = [:invalid, :promoted, :active, "normal", 1, nil]

  invalid_states.each do |state|
    begin
      Sashite::Pin::Identifier.new(:K, :first, state)
      raise "Should have raised error for invalid state #{state.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid state" unless e.message.include?("State must be")
    end
  end
end

run_test("Piece error handling for invalid PIN strings") do
  # Invalid PIN strings
  invalid_pins = ["", "KK", "++K", "123", nil, :symbol]

  invalid_pins.each do |pin|
    begin
      Sashite::Pin.parse(pin)
      raise "Should have raised error for #{pin.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid PIN" unless e.message.include?("Invalid PIN")
    end
  end
end

# Test game-specific examples with new API
run_test("Western Chess pieces with new API") do
  # Standard pieces
  king = Sashite::Pin.identifier(:K, :first, :normal)
  raise "King should be first player" unless king.first_player?
  raise "King type should be :K" unless king.type == :K

  # State modifiers
  castling_king = king.enhance
  raise "Castling king should be enhanced" unless castling_king.enhanced?
  raise "Castling king PIN should be +K" unless castling_king.to_s == "+K"

  pawn = Sashite::Pin.identifier(:P, :first, :normal)
  vulnerable_pawn = pawn.diminish
  raise "Vulnerable pawn should be diminished" unless vulnerable_pawn.diminished?
  raise "Vulnerable pawn PIN should be -P" unless vulnerable_pawn.to_s == "-P"
end

run_test("Japanese Chess (Shōgi) pieces with new API") do
  # Basic pieces
  rook = Sashite::Pin.identifier(:R, :first, :normal)
  bishop = Sashite::Pin.identifier(:B, :first, :normal)

  # Promoted pieces
  dragon_king = rook.enhance
  raise "Dragon King should be enhanced rook" unless dragon_king.enhanced? && dragon_king.type == :R
  raise "Dragon King PIN should be +R" unless dragon_king.to_s == "+R"

  dragon_horse = bishop.enhance
  raise "Dragon Horse should be enhanced bishop" unless dragon_horse.enhanced? && dragon_horse.type == :B
  raise "Dragon Horse PIN should be +B" unless dragon_horse.to_s == "+B"

  # Promoted pawn (Tokin)
  pawn = Sashite::Pin.identifier(:P, :first, :normal)
  tokin = pawn.enhance
  raise "Tokin should be enhanced pawn" unless tokin.enhanced? && tokin.type == :P
  raise "Tokin PIN should be +P" unless tokin.to_s == "+P"
end

run_test("Cross-game piece transformations with new API") do
  # Test that pieces can be transformed across different contexts
  piece = Sashite::Pin.identifier(:K, :first, :normal)

  # Chain transformations
  transformed = piece.flip.enhance.flip.diminish
  expected_final = "-K"  # Should end up as diminished first player king

  raise "Chained transformation should work" unless transformed.to_s == expected_final
  raise "Original piece should be unchanged" unless piece.to_s == "K"
end

# Test practical usage scenarios with new API
run_test("Practical usage - piece collections with new API") do
  pieces = [
    Sashite::Pin.identifier(:K, :first, :normal),
    Sashite::Pin.identifier(:Q, :first, :normal),
    Sashite::Pin.identifier(:R, :first, :enhanced),
    Sashite::Pin.identifier(:K, :second, :normal)
  ]

  # Filter by side
  first_player_pieces = pieces.select(&:first_player?)
  raise "Should have 3 first player pieces" unless first_player_pieces.size == 3

  # Group by type
  by_type = pieces.group_by(&:type)
  raise "Should have kings grouped" unless by_type[:K].size == 2

  # Find promoted pieces
  promoted = pieces.select(&:enhanced?)
  raise "Should have 1 promoted piece" unless promoted.size == 1
  raise "Promoted piece should be rook" unless promoted.first.type == :R
end

run_test("Practical usage - game state simulation with new API") do
  # Simulate promoting a pawn
  pawn = Sashite::Pin.identifier(:P, :first, :normal)
  raise "Pawn should be normal initially" unless pawn.normal?

  # Promote to queen using with_type and enhance
  promoted = pawn.with_type(:Q).enhance
  raise "Promoted piece should be queen" unless promoted.type == :Q
  raise "Promoted piece should be enhanced" unless promoted.enhanced?
  raise "Original pawn should be unchanged" unless pawn.normal? && pawn.type == :P

  # Simulate capturing and flipping
  captured = promoted.flip  # Becomes enemy piece
  raise "Captured piece should be second player" unless captured.second_player?
  raise "Captured piece should still be enhanced" unless captured.enhanced?
  raise "Captured piece should still be queen" unless captured.type == :Q
end

# Test edge cases
run_test("Edge case - all letters of alphabet with new API") do
  letters = ("A".."Z").to_a

  letters.each do |letter|
    type_symbol = letter.to_sym

    # Test first player
    piece1 = Sashite::Pin.identifier(type_symbol, :first, :normal)
    raise "#{letter} should create valid piece" unless piece1.type == type_symbol
    raise "#{letter} should be first player" unless piece1.first_player?
    raise "#{letter} should have correct letter" unless piece1.letter == letter

    # Test second player
    piece2 = Sashite::Pin.identifier(type_symbol, :second, :normal)
    raise "#{letter} should create valid piece" unless piece2.type == type_symbol
    raise "#{letter} should be second player" unless piece2.second_player?
    raise "#{letter} should have correct letter" unless piece2.letter == letter.downcase

    # Test enhanced state
    enhanced = piece1.enhance
    raise "#{letter} enhanced should work" unless enhanced.enhanced?
    raise "#{letter} enhanced should have + prefix" unless enhanced.prefix == "+"

    # Test diminished state
    diminished = piece1.diminish
    raise "#{letter} diminished should work" unless diminished.diminished?
    raise "#{letter} diminished should have - prefix" unless diminished.prefix == "-"
  end
end

run_test("Edge case - unicode and special characters still invalid") do
  unicode_chars = ["α", "β", "♕", "♔", "🀄", "象", "將"]

  unicode_chars.each do |char|
    raise "#{char.inspect} should be invalid (not ASCII)" if Sashite::Pin.valid?(char)
    raise "#{char.inspect} with + should be invalid" if Sashite::Pin.valid?("+#{char}")
    raise "#{char.inspect} with - should be invalid" if Sashite::Pin.valid?("-#{char}")
  end
end

run_test("Edge case - whitespace handling still works") do
  whitespace_cases = [
    " K", "K ", " +K", "+K ", " -K", "-K ",
    "\tK", "K\t", "\n+K", "+K\n", " K ", "\t+K\t"
  ]

  whitespace_cases.each do |pin|
    raise "#{pin.inspect} should be invalid (whitespace)" if Sashite::Pin.valid?(pin)
  end
end

run_test("Edge case - multiple modifiers still invalid") do
  multiple_modifiers = ["++K", "--K", "+-K", "-+K", "+++K", "---K"]

  multiple_modifiers.each do |pin|
    raise "#{pin.inspect} should be invalid (multiple modifiers)" if Sashite::Pin.valid?(pin)
  end
end

# Test regex compliance
run_test("Regex pattern compliance") do
  # Test against the specification regex: \A[-+]?[A-Za-z]\z
  spec_regex = /\A[-+]?[A-Za-z]\z/

  test_strings = [
    "K", "k", "+K", "+k", "-K", "-k", "A", "z", "+A", "-z",
    "", "KK", "++K", "--K", "K+", "K-", "+", "-", "1", "!"
  ]

  test_strings.each do |string|
    spec_match = string.match?(spec_regex)
    pin_valid = Sashite::Pin.valid?(string)

    raise "#{string.inspect}: spec regex and PIN validation disagree" unless spec_match == pin_valid
  end
end

# Test constants
run_test("Regular expression constant is correctly defined") do
  regex = Sashite::Pin::Identifier::PIN_PATTERN

  raise "PIN_PATTERN should match valid PINs" unless "K".match?(regex)
  raise "PIN_PATTERN should match enhanced PINs" unless "+R".match?(regex)
  raise "PIN_PATTERN should not match invalid PINs" if "KK".match?(regex)
end

# Test performance with new API
run_test("Performance - repeated operations with new API") do
  # Test performance with many repeated calls
  1000.times do
    piece = Sashite::Pin.identifier(:K, :first, :normal)
    enhanced = piece.enhance
    flipped = piece.flip
    queen = piece.with_type(:Q)

    raise "Performance test failed" unless Sashite::Pin.valid?("K")
    raise "Performance test failed" unless enhanced.enhanced?
    raise "Performance test failed" unless flipped.second_player?
    raise "Performance test failed" unless queen.type == :Q
  end
end

# Test constants and validation
run_test("Identifier class constants are properly defined") do
  piece_class = Sashite::Pin::Identifier

  # Test state constants
  raise "NORMAL_STATE should be :normal" unless piece_class::NORMAL_STATE == :normal
  raise "ENHANCED_STATE should be :enhanced" unless piece_class::ENHANCED_STATE == :enhanced
  raise "DIMINISHED_STATE should be :diminished" unless piece_class::DIMINISHED_STATE == :diminished

  # Test side constants
  raise "FIRST_PLAYER should be :first" unless piece_class::FIRST_PLAYER == :first
  raise "SECOND_PLAYER should be :second" unless piece_class::SECOND_PLAYER == :second

  # Test prefix constants
  raise "ENHANCED_PREFIX should be '+'" unless piece_class::ENHANCED_PREFIX == "+"
  raise "DIMINISHED_PREFIX should be '-'" unless piece_class::DIMINISHED_PREFIX == "-"
  raise "NORMAL_PREFIX should be ''" unless piece_class::NORMAL_PREFIX == ""
end

# Test roundtrip parsing
run_test("Roundtrip parsing consistency") do
  test_cases = [
    [:K, :first, :normal],
    [:Q, :second, :enhanced],
    [:P, :first, :diminished],
    [:Z, :second, :normal]
  ]

  test_cases.each do |type, side, state|
    # Create piece -> to_s -> parse -> compare
    original = Sashite::Pin::Identifier.new(type, side, state)
    pin_string = original.to_s
    parsed = Sashite::Pin.parse(pin_string)

    raise "Roundtrip failed: original != parsed" unless original == parsed
    raise "Roundtrip failed: different type" unless original.type == parsed.type
    raise "Roundtrip failed: different side" unless original.side == parsed.side
    raise "Roundtrip failed: different state" unless original.state == parsed.state
  end
end

puts
puts "All PIN tests passed!"
puts
