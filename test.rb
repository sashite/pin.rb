# frozen_string_literal: true

# Tests for Sashite::Pin (Piece Identifier Notation)
#
# Tests the PIN implementation for Ruby, focusing on the modern object-oriented API
# with the Piece class and the minimal module interface (valid? and parse only).

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
run_test("Module parse delegates to Piece class") do
  pin_string = "+R"
  piece = Sashite::Pin.parse(pin_string)

  raise "parse should return Piece instance" unless piece.is_a?(Sashite::Pin::Piece)
  raise "piece should have correct PIN string" unless piece.to_s == pin_string
end

# Test the Piece class
run_test("Piece.parse creates correct instances") do
  test_cases = {
    "K" => { letter: "K", enhanced: false, diminished: false },
    "k" => { letter: "k", enhanced: false, diminished: false },
    "+R" => { letter: "R", enhanced: true, diminished: false },
    "-p" => { letter: "p", enhanced: false, diminished: true }
  }

  test_cases.each do |pin_string, expected|
    piece = Sashite::Pin.parse(pin_string)

    raise "#{pin_string}: wrong letter" unless piece.letter == expected[:letter]
    raise "#{pin_string}: wrong enhanced state" unless piece.enhanced? == expected[:enhanced]
    raise "#{pin_string}: wrong diminished state" unless piece.diminished? == expected[:diminished]
  end
end

run_test("Piece to_s returns correct PIN string") do
  test_cases = [
    ["K", false, false, "K"],
    ["k", false, false, "k"],
    ["R", true, false, "+R"],
    ["p", false, true, "-p"]
  ]

  test_cases.each do |letter, enhanced, diminished, expected|
    piece = Sashite::Pin::Piece.new(letter, enhanced: enhanced, diminished: diminished)
    result = piece.to_s

    raise "#{letter} with enhanced=#{enhanced}, diminished=#{diminished} should be #{expected}, got #{result}" unless result == expected
  end
end

run_test("Piece state mutations return new instances") do
  piece = Sashite::Pin.parse("K")

  # Test enhance
  enhanced = piece.enhance
  raise "enhance should return new instance" if enhanced.equal?(piece)
  raise "enhanced piece should be enhanced" unless enhanced.enhanced?
  raise "original piece should be unchanged" if piece.enhanced?
  raise "enhanced piece should have same letter" unless enhanced.letter == piece.letter

  # Test diminish
  diminished = piece.diminish
  raise "diminish should return new instance" if diminished.equal?(piece)
  raise "diminished piece should be diminished" unless diminished.diminished?
  raise "original piece should be unchanged" if piece.diminished?

  # Test flip
  flipped = piece.flip
  raise "flip should return new instance" if flipped.equal?(piece)
  raise "flipped piece should have lowercase letter" unless flipped.letter == "k"
  raise "original piece should be unchanged" unless piece.letter == "K"
end

run_test("Piece immutability") do
  piece = Sashite::Pin.parse("+R")

  # Test that piece is frozen
  raise "piece should be frozen" unless piece.frozen?

  # Test that letter is frozen
  raise "letter should be frozen" unless piece.letter.frozen?

  # Test that mutations don't affect original
  original_string = piece.to_s
  normalized = piece.normalize

  raise "original piece should be unchanged after normalize" unless piece.to_s == original_string
  raise "normalized piece should be different" unless normalized.to_s == "R"
end

run_test("Piece equality and hash") do
  piece1 = Sashite::Pin.parse("K")
  piece2 = Sashite::Pin.parse("K")
  piece3 = Sashite::Pin.parse("k")
  piece4 = Sashite::Pin.parse("+K")

  # Test equality
  raise "identical pieces should be equal" unless piece1 == piece2
  raise "different case should not be equal" if piece1 == piece3
  raise "different state should not be equal" if piece1 == piece4

  # Test hash consistency
  raise "equal pieces should have same hash" unless piece1.hash == piece2.hash

  # Test in hash/set
  pieces_set = Set.new([piece1, piece2, piece3, piece4])
  raise "set should contain 3 unique pieces" unless pieces_set.size == 3
end

run_test("Piece type and player identification") do
  test_cases = [
    ["K", "K", :first, true, false],
    ["k", "K", :second, false, true],
    ["+R", "R", :first, true, false],
    ["-p", "P", :second, false, true]
  ]

  test_cases.each do |pin_string, expected_type, expected_side, is_first, is_second|
    piece = Sashite::Pin.parse(pin_string)

    raise "#{pin_string}: wrong type" unless piece.type == expected_type
    raise "#{pin_string}: wrong side" unless piece.side == expected_side
    raise "#{pin_string}: wrong first_player?" unless piece.first_player? == is_first
    raise "#{pin_string}: wrong second_player?" unless piece.second_player? == is_second
  end
end

run_test("Piece same_type? and same_player? methods") do
  king1 = Sashite::Pin.parse("K")
  king2 = Sashite::Pin.parse("k")
  king3 = Sashite::Pin.parse("+K")
  queen = Sashite::Pin.parse("Q")

  # same_type? tests
  raise "K and k should be same type" unless king1.same_type?(king2)
  raise "K and +K should be same type" unless king1.same_type?(king3)
  raise "K and Q should not be same type" if king1.same_type?(queen)

  # same_player? tests
  raise "K and +K should be same player" unless king1.same_player?(king3)
  raise "K and k should not be same player" if king1.same_player?(king2)
  raise "K and Q should be same player" unless king1.same_player?(queen)
end

run_test("Piece state methods") do
  normal = Sashite::Pin.parse("K")
  enhanced = Sashite::Pin.parse("+K")
  diminished = Sashite::Pin.parse("-K")

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

run_test("Piece transformation methods") do
  piece = Sashite::Pin.parse("K")

  # Test unenhance on normal piece (should return self)
  unenhanced = piece.unenhance
  raise "unenhance on normal piece should return self" unless unenhanced.equal?(piece)

  # Test undiminish on normal piece (should return self)
  undiminished = piece.undiminish
  raise "undiminish on normal piece should return self" unless undiminished.equal?(piece)

  # Test normalize on normal piece (should return self)
  normalized = piece.normalize
  raise "normalize on normal piece should return self" unless normalized.equal?(piece)

  # Test enhance then unenhance
  enhanced = piece.enhance
  back_to_normal = enhanced.unenhance
  raise "enhance then unenhance should equal original" unless back_to_normal == piece

  # Test diminish then undiminish
  diminished = piece.diminish
  back_to_normal2 = diminished.undiminish
  raise "diminish then undiminish should equal original" unless back_to_normal2 == piece
end

run_test("Piece error handling") do
  # Invalid PIN strings
  invalid_pins = ["", "KK", "++K", "123", nil]

  invalid_pins.each do |pin|
    begin
      Sashite::Pin.parse(pin)
      raise "Should have raised error for #{pin.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid PIN" unless e.message.include?("Invalid PIN")
    end
  end

  # Invalid constructor arguments
  begin
    Sashite::Pin::Piece.new("KK")
    raise "Should have raised error for invalid letter"
  rescue ArgumentError => e
    raise "Error message should mention invalid letter" unless e.message.include?("Letter must be")
  end

  begin
    Sashite::Pin::Piece.new("K", enhanced: true, diminished: true)
    raise "Should have raised error for conflicting states"
  rescue ArgumentError => e
    raise "Error message should mention conflicting states" unless e.message.include?("both enhanced and diminished")
  end
end

# Test game-specific examples
run_test("Western Chess pieces") do
  # Standard pieces
  king = Sashite::Pin.parse("K")
  raise "King should be first player" unless king.first_player?
  raise "King type should be K" unless king.type == "K"

  # State modifiers
  castling_king = king.enhance
  raise "Castling king should be enhanced" unless castling_king.enhanced?
  raise "Castling king PIN should be +K" unless castling_king.to_s == "+K"

  pawn = Sashite::Pin.parse("P")
  vulnerable_pawn = pawn.diminish
  raise "Vulnerable pawn should be diminished" unless vulnerable_pawn.diminished?
  raise "Vulnerable pawn PIN should be -P" unless vulnerable_pawn.to_s == "-P"
end

run_test("Japanese Chess (Shōgi) pieces") do
  # Basic pieces
  rook = Sashite::Pin.parse("R")
  bishop = Sashite::Pin.parse("B")

  # Promoted pieces
  dragon_king = rook.enhance
  raise "Dragon King should be enhanced rook" unless dragon_king.enhanced? && dragon_king.type == "R"
  raise "Dragon King PIN should be +R" unless dragon_king.to_s == "+R"

  dragon_horse = bishop.enhance
  raise "Dragon Horse should be enhanced bishop" unless dragon_horse.enhanced? && dragon_horse.type == "B"
  raise "Dragon Horse PIN should be +B" unless dragon_horse.to_s == "+B"

  # Promoted pawn (Tokin)
  pawn = Sashite::Pin.parse("P")
  tokin = pawn.enhance
  raise "Tokin should be enhanced pawn" unless tokin.enhanced? && tokin.type == "P"
  raise "Tokin PIN should be +P" unless tokin.to_s == "+P"
end

run_test("Cross-game piece transformations") do
  # Test that pieces can be transformed across different contexts
  piece = Sashite::Pin.parse("K")

  # Chain transformations
  transformed = piece.flip.enhance.flip.diminish
  expected_final = "-K"  # Should end up as diminished first player king

  raise "Chained transformation should work" unless transformed.to_s == expected_final
  raise "Original piece should be unchanged" unless piece.to_s == "K"
end

# Test practical usage scenarios
run_test("Practical usage - piece collections") do
  pieces = [
    Sashite::Pin.parse("K"),
    Sashite::Pin.parse("Q"),
    Sashite::Pin.parse("+R"),
    Sashite::Pin.parse("k")
  ]

  # Filter by player
  white_pieces = pieces.select(&:first_player?)
  raise "Should have 3 white pieces" unless white_pieces.size == 3

  # Group by type
  by_type = pieces.group_by(&:type)
  raise "Should have kings grouped" unless by_type["K"].size == 2

  # Find promoted pieces
  promoted = pieces.select(&:enhanced?)
  raise "Should have 1 promoted piece" unless promoted.size == 1
  raise "Promoted piece should be rook" unless promoted.first.type == "R"
end

run_test("Practical usage - game state simulation") do
  # Simulate promoting a pawn
  pawn = Sashite::Pin.parse("P")
  raise "Pawn should be normal initially" unless pawn.normal?

  # Promote to queen (conceptually, PIN doesn't enforce piece type rules)
  promoted = pawn.enhance
  raise "Promoted pawn should be enhanced" unless promoted.enhanced?
  raise "Original pawn should be unchanged" unless pawn.normal?

  # Simulate capturing and flipping
  captured = promoted.flip  # Becomes enemy piece
  raise "Captured piece should be second player" unless captured.second_player?
  raise "Captured piece should still be enhanced" unless captured.enhanced?
end

# Test edge cases
run_test("Edge case - all letters of alphabet") do
  letters = ("A".."Z").to_a + ("a".."z").to_a

  letters.each do |letter|
    # Test bare letter
    raise "#{letter} should be valid" unless Sashite::Pin.valid?(letter)

    piece = Sashite::Pin.parse(letter)
    raise "#{letter} should parse correctly" unless piece.letter == letter

    # Test with enhanced state
    enhanced = "+#{letter}"
    raise "#{enhanced} should be valid" unless Sashite::Pin.valid?(enhanced)

    enhanced_piece = Sashite::Pin.parse(enhanced)
    raise "#{enhanced} should be enhanced" unless enhanced_piece.enhanced?

    # Test with diminished state
    diminished = "-#{letter}"
    raise "#{diminished} should be valid" unless Sashite::Pin.valid?(diminished)

    diminished_piece = Sashite::Pin.parse(diminished)
    raise "#{diminished} should be diminished" unless diminished_piece.diminished?
  end
end

run_test("Edge case - unicode and special characters") do
  unicode_chars = ["α", "β", "♕", "♔", "🀄", "象", "將"]

  unicode_chars.each do |char|
    raise "#{char.inspect} should be invalid (not ASCII)" if Sashite::Pin.valid?(char)
    raise "#{char.inspect} with + should be invalid" if Sashite::Pin.valid?("+#{char}")
    raise "#{char.inspect} with - should be invalid" if Sashite::Pin.valid?("-#{char}")
  end
end

run_test("Edge case - whitespace handling") do
  whitespace_cases = [
    " K", "K ", " +K", "+K ", " -K", "-K ",
    "\tK", "K\t", "\n+K", "+K\n", " K ", "\t+K\t"
  ]

  whitespace_cases.each do |pin|
    raise "#{pin.inspect} should be invalid (whitespace)" if Sashite::Pin.valid?(pin)
  end
end

run_test("Edge case - multiple modifiers") do
  multiple_modifiers = ["++K", "--K", "+-K", "-+K", "+++K", "---K"]

  multiple_modifiers.each do |pin|
    raise "#{pin.inspect} should be invalid (multiple modifiers)" if Sashite::Pin.valid?(pin)
  end
end

run_test("Edge case - modifier without letter") do
  orphaned_modifiers = ["+", "-", "++", "--", "+-", "-+"]

  orphaned_modifiers.each do |pin|
    raise "#{pin.inspect} should be invalid (no letter)" if Sashite::Pin.valid?(pin)
  end
end

run_test("Edge case - modifier in wrong position") do
  wrong_position = ["K+", "K-", "k+", "k-", "R+", "r-"]

  wrong_position.each do |pin|
    raise "#{pin.inspect} should be invalid (modifier in wrong position)" if Sashite::Pin.valid?(pin)
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
run_test("PIN_REGEX constant is correctly defined") do
  regex = Sashite::Pin::PIN_REGEX

  raise "PIN_REGEX should match valid PINs" unless "K".match?(regex)
  raise "PIN_REGEX should match enhanced PINs" unless "+R".match?(regex)
  raise "PIN_REGEX should not match invalid PINs" if "KK".match?(regex)
end

# Test performance
run_test("Performance - repeated operations") do
  # Test performance with many repeated calls
  1000.times do
    piece = Sashite::Pin.parse("K")
    enhanced = piece.enhance
    flipped = piece.flip

    raise "Performance test failed" unless Sashite::Pin.valid?("K")
    raise "Performance test failed" unless enhanced.enhanced?
    raise "Performance test failed" unless flipped.second_player?
  end
end

puts
puts "All PIN tests passed!"
puts
