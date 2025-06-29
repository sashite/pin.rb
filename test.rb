# frozen_string_literal: true

# Tests for Sashite::Pin (Piece Identifier Notation)
#
# Tests the PIN implementation for Ruby, focusing on the modern object-oriented API
# with the Piece class, while maintaining basic validation tests.

require_relative "lib/sashite-pin"

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

# Test the new Piece class
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

# Test constants (the ones that remain)
run_test("PIN_REGEX constant is correctly defined") do
  regex = Sashite::Pin::PIN_REGEX

  raise "PIN_REGEX should match valid PINs" unless "K".match?(regex)
  raise "PIN_REGEX should match enhanced PINs" unless "+R".match?(regex)
  raise "PIN_REGEX should not match invalid PINs" if "KK".match?(regex)
end

puts
puts "All PIN tests passed!"
puts("Letter extraction for various PINs") do
  test_cases = {
    "K" => "K", "k" => "k", "+R" => "R", "-r" => "r",
    "+P" => "P", "-p" => "p", "A" => "A", "z" => "z"
  }

  test_cases.each do |pin, expected_letter|
    letter = Sashite::Pin.letter(pin)
    raise "#{pin} should have letter #{expected_letter}, got #{letter}" unless letter == expected_letter
  end
end

run_test("Letter extraction raises error for invalid PIN") do
  invalid_pins = ["", "KK", "++K", "123"]

  invalid_pins.each do |pin|
    begin
      Sashite::Pin.letter(pin)
      raise "Should have raised ArgumentError for #{pin.inspect}"
    rescue ArgumentError
      # Expected behavior
    end
  end
end

# Test player identification
run_test("First player identification") do
  first_player_pins = ["K", "Q", "R", "B", "N", "P", "A", "Z", "+K", "-R", "+P"]

  first_player_pins.each do |pin|
    raise "#{pin} should be first player" unless Sashite::Pin.first_player?(pin)
    raise "#{pin} should not be second player" if Sashite::Pin.second_player?(pin)
  end
end

run_test("Second player identification") do
  second_player_pins = ["k", "q", "r", "b", "n", "p", "a", "z", "+k", "-r", "+p"]

  second_player_pins.each do |pin|
    raise "#{pin} should be second player" unless Sashite::Pin.second_player?(pin)
    raise "#{pin} should not be first player" if Sashite::Pin.first_player?(pin)
  end
end

# Test state identification
run_test("Enhanced state identification") do
  enhanced_pins = ["+K", "+k", "+R", "+r", "+P", "+p"]

  enhanced_pins.each do |pin|
    raise "#{pin} should be enhanced" unless Sashite::Pin.enhanced?(pin)
    raise "#{pin} should not be diminished" if Sashite::Pin.diminished?(pin)
    raise "#{pin} should not be normal" if Sashite::Pin.normal?(pin)
  end
end

run_test("Diminished state identification") do
  diminished_pins = ["-K", "-k", "-R", "-r", "-P", "-p"]

  diminished_pins.each do |pin|
    raise "#{pin} should be diminished" unless Sashite::Pin.diminished?(pin)
    raise "#{pin} should not be enhanced" if Sashite::Pin.enhanced?(pin)
    raise "#{pin} should not be normal" if Sashite::Pin.normal?(pin)
  end
end

run_test("Normal state identification") do
  normal_pins = ["K", "k", "R", "r", "P", "p"]

  normal_pins.each do |pin|
    raise "#{pin} should be normal" unless Sashite::Pin.normal?(pin)
    raise "#{pin} should not be enhanced" if Sashite::Pin.enhanced?(pin)
    raise "#{pin} should not be diminished" if Sashite::Pin.diminished?(pin)
  end
end

# Test type extraction
run_test("Type extraction") do
  test_cases = {
    "K" => "K", "k" => "K", "+R" => "R", "-r" => "R",
    "P" => "P", "p" => "P", "+p" => "P", "-P" => "P",
    "a" => "A", "z" => "Z", "+a" => "A", "-z" => "Z"
  }

  test_cases.each do |pin, expected_type|
    type = Sashite::Pin.type(pin)
    raise "#{pin} should have type #{expected_type}, got #{type}" unless type == expected_type
  end
end

# Test PIN creation
run_test("PIN creation with valid components") do
  test_cases = [
    ["K", nil, "K"],
    ["k", nil, "k"],
    ["R", "+", "+R"],
    ["r", "+", "+r"],
    ["P", "-", "-P"],
    ["p", "-", "-p"],
    ["A", nil, "A"],
    ["z", nil, "z"]
  ]

  test_cases.each do |letter, state, expected|
    result = Sashite::Pin.create(letter, state)
    raise "create(#{letter.inspect}, #{state.inspect}) should return #{expected.inspect}, got #{result.inspect}" unless result == expected
  end
end

run_test("PIN creation with invalid letter") do
  invalid_letters = ["", "KK", "1", "!", " K", "K "]

  invalid_letters.each do |letter|
    begin
      Sashite::Pin.create(letter)
      raise "Should have raised ArgumentError for letter #{letter.inspect}"
    rescue ArgumentError
      # Expected behavior
    end
  end
end

run_test("PIN creation with invalid state") do
  invalid_states = ["", "++", "--", "x", "1", " +", "+ "]

  invalid_states.each do |state|
    begin
      Sashite::Pin.create("K", state)
      raise "Should have raised ArgumentError for state #{state.inspect}"
    rescue ArgumentError
      # Expected behavior
    end
  end
end

# Test constants
run_test("Constants are correctly defined") do
  raise "ENHANCED should be +" unless Sashite::Pin::ENHANCED == "+"
  raise "DIMINISHED should be -" unless Sashite::Pin::DIMINISHED == "-"
  raise "STATE_MODIFIERS should contain + and -" unless Sashite::Pin::STATE_MODIFIERS == ["+", "-"]

  # Test immutability
  raise "ENHANCED should be frozen" unless Sashite::Pin::ENHANCED.frozen?
  raise "DIMINISHED should be frozen" unless Sashite::Pin::DIMINISHED.frozen?
  raise "STATE_MODIFIERS should be frozen" unless Sashite::Pin::STATE_MODIFIERS.frozen?
end

# Test regex pattern
run_test("Regex pattern validation") do
  # Test the regex directly
  regex = Sashite::Pin::PIN_REGEX

  valid_samples = ["K", "k", "+R", "-p", "A", "z"]
  valid_samples.each do |pin|
    raise "#{pin} should match regex" unless pin.match?(regex)
  end

  invalid_samples = ["", "KK", "++K", "1", "+", "-"]
  invalid_samples.each do |pin|
    raise "#{pin} should not match regex" if pin.match?(regex)
  end
end

# Test game-specific examples
run_test("Western Chess examples") do
  chess_pins = {
    "P" => "White pawn", "p" => "Black pawn",
    "-P" => "White pawn (en passant vulnerable)", "-p" => "Black pawn (en passant vulnerable)",
    "R" => "White rook", "r" => "Black rook",
    "+R" => "White rook (castling eligible)", "+r" => "Black rook (castling eligible)",
    "N" => "White knight", "n" => "Black knight",
    "B" => "White bishop", "b" => "Black bishop",
    "Q" => "White queen", "q" => "Black queen",
    "K" => "White king", "k" => "Black king",
    "+K" => "White king (castling eligible)", "+k" => "Black king (castling eligible)"
  }

  chess_pins.each do |pin, description|
    raise "#{pin} (#{description}) should be valid" unless Sashite::Pin.valid?(pin)
  end
end

run_test("Japanese Chess (Shōgi) examples") do
  shogi_pins = {
    "K" => "White king", "k" => "Black king",
    "R" => "White rook", "r" => "Black rook",
    "+R" => "White promoted rook (Dragon King)", "+r" => "Black promoted rook (Dragon King)",
    "B" => "White bishop", "b" => "Black bishop",
    "+B" => "White promoted bishop (Dragon Horse)", "+b" => "Black promoted bishop (Dragon Horse)",
    "G" => "White gold general", "g" => "Black gold general",
    "S" => "White silver general", "s" => "Black silver general",
    "+S" => "White promoted silver general", "+s" => "Black promoted silver general",
    "N" => "White knight", "n" => "Black knight",
    "+N" => "White promoted knight", "+n" => "Black promoted knight",
    "L" => "White lance", "l" => "Black lance",
    "+L" => "White promoted lance", "+l" => "Black promoted lance",
    "P" => "White pawn", "p" => "Black pawn",
    "+P" => "White promoted pawn (Tokin)", "+p" => "Black promoted pawn (Tokin)"
  }

  shogi_pins.each do |pin, description|
    raise "#{pin} (#{description}) should be valid" unless Sashite::Pin.valid?(pin)
  end
end

run_test("Thai Chess (Makruk) examples") do
  makruk_pins = {
    "K" => "White king", "k" => "Black king",
    "M" => "White queen (Met)", "m" => "Black queen (Met)",
    "R" => "White rook (Ruea)", "r" => "Black rook (Ruea)",
    "B" => "White bishop (Khon)", "b" => "Black bishop (Khon)",
    "N" => "White knight (Ma)", "n" => "Black knight (Ma)",
    "P" => "White pawn (Bia)", "p" => "Black pawn (Bia)",
    "+P" => "White promoted pawn (Bia Kaew)", "+p" => "Black promoted pawn (Bia Kaew)"
  }

  makruk_pins.each do |pin, description|
    raise "#{pin} (#{description}) should be valid" unless Sashite::Pin.valid?(pin)
  end
end

run_test("Chinese Chess (Xiangqi) examples") do
  xiangqi_pins = {
    "G" => "Red general", "g" => "Black general",
    "+G" => "Red flying general", "+g" => "Black flying general",
    "A" => "Red advisor", "a" => "Black advisor",
    "E" => "Red elephant", "e" => "Black elephant",
    "H" => "Red horse", "h" => "Black horse",
    "R" => "Red chariot", "r" => "Black chariot",
    "C" => "Red cannon", "c" => "Black cannon",
    "P" => "Red soldier", "p" => "Black soldier",
    "+P" => "Red soldier (crossed river)", "+p" => "Black soldier (crossed river)"
  }

  xiangqi_pins.each do |pin, description|
    raise "#{pin} (#{description}) should be valid" unless Sashite::Pin.valid?(pin)
  end
end

# Test edge cases and boundary conditions
run_test("Edge case - all letters of alphabet") do
  letters = ("A".."Z").to_a + ("a".."z").to_a

  letters.each do |letter|
    # Test bare letter
    raise "#{letter} should be valid" unless Sashite::Pin.valid?(letter)

    # Test with enhanced state
    enhanced = "+#{letter}"
    raise "#{enhanced} should be valid" unless Sashite::Pin.valid?(enhanced)

    # Test with diminished state
    diminished = "-#{letter}"
    raise "#{diminished} should be valid" unless Sashite::Pin.valid?(diminished)
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

# Test performance and stress conditions
run_test("Performance - repeated validation") do
  # Test performance with many repeated calls
  1000.times do
    raise "Performance test failed" unless Sashite::Pin.valid?("K")
    raise "Performance test failed" unless Sashite::Pin.valid?("+R")
    raise "Performance test failed" unless Sashite::Pin.valid?("-p")
    raise "Performance test failed" if Sashite::Pin.valid?("invalid")
  end
end

run_test("Performance - component extraction") do
  # Test performance of component extraction
  pins = ["K", "+R", "-p", "Q", "+q", "-B"]

  1000.times do
    pins.each do |pin|
      Sashite::Pin.letter(pin)
      Sashite::Pin.state(pin)
      Sashite::Pin.type(pin)
      Sashite::Pin.first_player?(pin)
      Sashite::Pin.enhanced?(pin)
    end
  end
end

# Test specification compliance
run_test("Specification compliance - grammar") do
  # Test BNF grammar: <pin> ::= <letter> | <state-modifier> <letter>

  # Valid according to grammar
  valid_grammar = ["K", "k", "+K", "+k", "-K", "-k"]
  valid_grammar.each do |pin|
    raise "#{pin} should be valid per grammar" unless Sashite::Pin.valid?(pin)
  end

  # Invalid according to grammar
  invalid_grammar = ["", "KK", "++K", "K+", "+", "-"]
  invalid_grammar.each do |pin|
    raise "#{pin} should be invalid per grammar" if Sashite::Pin.valid?(pin)
  end
end

run_test("Specification compliance - regex pattern") do
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

# Test integration scenarios
run_test("Integration - piece comparison") do
  # Test comparing pieces of same type
  def same_type?(pin1, pin2)
    Sashite::Pin.valid?(pin1) &&
    Sashite::Pin.valid?(pin2) &&
    Sashite::Pin.type(pin1) == Sashite::Pin.type(pin2)
  end

  raise "K and k should be same type" unless same_type?("K", "k")
  raise "+R and r should be same type" unless same_type?("+R", "r")
  raise "-P and +p should be same type" unless same_type?("-P", "+p")
  raise "K and Q should not be same type" if same_type?("K", "Q")
end

run_test("Integration - move description") do
  def describe_piece(pin)
    return "Invalid piece" unless Sashite::Pin.valid?(pin)

    player = Sashite::Pin.first_player?(pin) ? "White" : "Black"
    type = Sashite::Pin.type(pin)
    state = case Sashite::Pin.state(pin)
           when "+" then " (promoted)"
           when "-" then " (special)"
           else ""
           end

    "#{player} #{type}#{state}"
  end

  test_cases = {
    "K" => "White K",
    "k" => "Black K",
    "+R" => "White R (promoted)",
    "-p" => "Black P (special)"
  }

  test_cases.each do |pin, expected|
    result = describe_piece(pin)
    raise "#{pin} should describe as #{expected}, got #{result}" unless result == expected
  end
end

run_test("Integration - piece transformation") do
  # Test promoting a piece (changing state)
  def promote_piece(pin)
    return nil unless Sashite::Pin.valid?(pin)
    return pin if Sashite::Pin.enhanced?(pin)  # Already promoted

    letter = Sashite::Pin.letter(pin)
    Sashite::Pin.create(letter, "+")
  end

  test_cases = {
    "P" => "+P",
    "p" => "+p",
    "R" => "+R",
    "+R" => "+R"  # Already promoted
  }

  test_cases.each do |original, expected|
    result = promote_piece(original)
    raise "Promoting #{original} should give #{expected}, got #{result}" unless result == expected
  end
end

# Test error handling
run_test("Error handling - invalid PIN for state extraction") do
  invalid_pins = ["", "KK", "++K", "123", nil, 42]

  invalid_pins.each do |pin|
    begin
      Sashite::Pin.state(pin)
      raise "Should have raised error for #{pin.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid PIN" unless e.message.include?("Invalid PIN")
    end
  end
end

run_test("Error handling - invalid PIN for letter extraction") do
  invalid_pins = ["", "KK", "++K", "123"]

  invalid_pins.each do |pin|
    begin
      Sashite::Pin.letter(pin)
      raise "Should have raised error for #{pin.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid PIN" unless e.message.include?("Invalid PIN")
    end
  end
end

run_test("Error handling - invalid PIN for player identification") do
  invalid_pins = ["", "KK", "++K"]

  invalid_pins.each do |pin|
    begin
      Sashite::Pin.first_player?(pin)
      raise "Should have raised error for #{pin.inspect}"
    rescue ArgumentError
      # Expected
    end

    begin
      Sashite::Pin.second_player?(pin)
      raise "Should have raised error for #{pin.inspect}"
    rescue ArgumentError
      # Expected
    end
  end
end

# Test immutability and thread safety
run_test("Immutability - constants cannot be modified") do
  begin
    Sashite::Pin::ENHANCED << "EXTRA"
    raise "Should not be able to modify frozen constant"
  rescue FrozenError
    # Expected behavior
  end

  begin
    Sashite::Pin::STATE_MODIFIERS << "EXTRA"
    raise "Should not be able to modify frozen constant"
  rescue FrozenError
    # Expected behavior
  end
end

run_test("Immutability - method return values") do
  pin = "+R"

  letter = Sashite::Pin.letter(pin)
  state = Sashite::Pin.state(pin)
  type = Sashite::Pin.type(pin)

  # Test that returned strings are safe to modify (or frozen)
  original_letter = letter.dup
  original_state = state.dup if state
  original_type = type.dup

  begin
    letter << "EXTRA"
  rescue FrozenError
    # It's ok if they're frozen
  end

  # Verify original values unchanged
  raise "letter should be unchanged" unless Sashite::Pin.letter(pin) == original_letter
  raise "state should be unchanged" unless Sashite::Pin.state(pin) == original_state
  raise "type should be unchanged" unless Sashite::Pin.type(pin) == original_type
end

# Test comprehensive coverage
run_test("Comprehensive coverage - all state combinations") do
  letters = ["K", "k", "R", "r", "P", "p"]
  states = [nil, "+", "-"]

  letters.each do |letter|
    states.each do |state|
      pin = state ? "#{state}#{letter}" : letter

      raise "#{pin} should be valid" unless Sashite::Pin.valid?(pin)
      raise "Letter extraction failed for #{pin}" unless Sashite::Pin.letter(pin) == letter
      raise "State extraction failed for #{pin}" unless Sashite::Pin.state(pin) == state
      raise "Type extraction failed for #{pin}" unless Sashite::Pin.type(pin) == letter.upcase

      # Test player identification
      if letter.match?(/[A-Z]/)
        raise "#{pin} should be first player" unless Sashite::Pin.first_player?(pin)
        raise "#{pin} should not be second player" if Sashite::Pin.second_player?(pin)
      else
        raise "#{pin} should be second player" unless Sashite::Pin.second_player?(pin)
        raise "#{pin} should not be first player" if Sashite::Pin.first_player?(pin)
      end

      # Test state identification
      case state
      when "+"
        raise "#{pin} should be enhanced" unless Sashite::Pin.enhanced?(pin)
        raise "#{pin} should not be diminished" if Sashite::Pin.diminished?(pin)
        raise "#{pin} should not be normal" if Sashite::Pin.normal?(pin)
      when "-"
        raise "#{pin} should be diminished" unless Sashite::Pin.diminished?(pin)
        raise "#{pin} should not be enhanced" if Sashite::Pin.enhanced?(pin)
        raise "#{pin} should not be normal" if Sashite::Pin.normal?(pin)
      when nil
        raise "#{pin} should be normal" unless Sashite::Pin.normal?(pin)
        raise "#{pin} should not be enhanced" if Sashite::Pin.enhanced?(pin)
        raise "#{pin} should not be diminished" if Sashite::Pin.diminished?(pin)
      end
    end
  end
end

# Test the new Piece class
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

# Integration test with old API
run_test("Integration between Piece class and module methods") do
  pin_string = "+R"

  # Parse with new API
  piece = Sashite::Pin.parse(pin_string)

  # Verify compatibility with old API
  raise "valid? should work" unless Sashite::Pin.valid?(pin_string)
  raise "letter should match" unless Sashite::Pin.letter(pin_string) == piece.letter
  raise "state should match" unless Sashite::Pin.state(pin_string) == "+"
  raise "enhanced? should match" unless Sashite::Pin.enhanced?(pin_string) == piece.enhanced?
  raise "first_player? should match" unless Sashite::Pin.first_player?(pin_string) == piece.first_player?

  # Verify round-trip
  raise "to_s should recreate original" unless piece.to_s == pin_string
end
