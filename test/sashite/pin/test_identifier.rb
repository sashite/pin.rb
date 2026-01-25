#!/usr/bin/env ruby
# frozen_string_literal: true

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
puts "=== Identifier Tests ==="
puts

# ============================================================================
# CONSTRUCTOR TESTS
# ============================================================================

puts "Constructor:"

run_test("creates identifier with abbr and side") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  raise "wrong abbr" unless pin.abbr == :K
  raise "wrong side" unless pin.side == :first
  raise "wrong state" unless pin.state == :normal
  raise "wrong terminal" unless pin.terminal? == false
end

run_test("creates identifier with state") do
  pin = Sashite::Pin::Identifier.new(:R, :second, :enhanced)
  raise "wrong abbr" unless pin.abbr == :R
  raise "wrong side" unless pin.side == :second
  raise "wrong state" unless pin.state == :enhanced
  raise "wrong terminal" unless pin.terminal? == false
end

run_test("creates identifier with terminal") do
  pin = Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: true)
  raise "wrong abbr" unless pin.abbr == :K
  raise "wrong side" unless pin.side == :first
  raise "wrong state" unless pin.state == :normal
  raise "wrong terminal" unless pin.terminal? == true
end

run_test("creates identifier with all attributes") do
  pin = Sashite::Pin::Identifier.new(:Q, :second, :diminished, terminal: true)
  raise "wrong abbr" unless pin.abbr == :Q
  raise "wrong side" unless pin.side == :second
  raise "wrong state" unless pin.state == :diminished
  raise "wrong terminal" unless pin.terminal? == true
end

run_test("identifier is frozen") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  raise "should be frozen" unless pin.frozen?
end

run_test("accepts all valid abbrs A-Z") do
  (:A..:Z).each do |abbr|
    pin = Sashite::Pin::Identifier.new(abbr, :first)
    raise "wrong abbr for #{abbr}" unless pin.abbr == abbr
  end
end

# ============================================================================
# CONSTRUCTOR ERROR CASES
# ============================================================================

puts
puts "Constructor error cases:"

run_test("raises on invalid abbr") do
  Sashite::Pin::Identifier.new(:invalid, :first)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INVALID_ABBR
end

run_test("raises on lowercase abbr symbol") do
  Sashite::Pin::Identifier.new(:k, :first)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INVALID_ABBR
end

run_test("raises on string abbr") do
  Sashite::Pin::Identifier.new("K", :first)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INVALID_ABBR
end

run_test("raises on invalid side") do
  Sashite::Pin::Identifier.new(:K, :invalid)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INVALID_SIDE
end

run_test("raises on invalid state") do
  Sashite::Pin::Identifier.new(:K, :first, :invalid)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INVALID_STATE
end

run_test("raises on non-boolean terminal") do
  Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: "true")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INVALID_TERMINAL
end

run_test("raises on nil terminal") do
  Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: nil)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INVALID_TERMINAL
end

run_test("raises on integer terminal") do
  Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: 1)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INVALID_TERMINAL
end

# ============================================================================
# STRING CONVERSION - TO_S
# ============================================================================

puts
puts "String conversion - to_s:"

run_test("formats simple first player") do
  raise "wrong format" unless Sashite::Pin::Identifier.new(:K, :first).to_s == "K"
end

run_test("formats simple second player") do
  raise "wrong format" unless Sashite::Pin::Identifier.new(:K, :second).to_s == "k"
end

run_test("formats enhanced first player") do
  raise "wrong format" unless Sashite::Pin::Identifier.new(:R, :first, :enhanced).to_s == "+R"
end

run_test("formats enhanced second player") do
  raise "wrong format" unless Sashite::Pin::Identifier.new(:R, :second, :enhanced).to_s == "+r"
end

run_test("formats diminished first player") do
  raise "wrong format" unless Sashite::Pin::Identifier.new(:P, :first, :diminished).to_s == "-P"
end

run_test("formats diminished second player") do
  raise "wrong format" unless Sashite::Pin::Identifier.new(:P, :second, :diminished).to_s == "-p"
end

run_test("formats terminal first player") do
  raise "wrong format" unless Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: true).to_s == "K^"
end

run_test("formats terminal second player") do
  raise "wrong format" unless Sashite::Pin::Identifier.new(:K, :second, :normal, terminal: true).to_s == "k^"
end

run_test("formats enhanced terminal") do
  raise "wrong format" unless Sashite::Pin::Identifier.new(:K, :first, :enhanced, terminal: true).to_s == "+K^"
end

run_test("formats diminished terminal") do
  raise "wrong format" unless Sashite::Pin::Identifier.new(:K, :second, :diminished, terminal: true).to_s == "-k^"
end

# ============================================================================
# STRING CONVERSION - COMPONENTS
# ============================================================================

puts
puts "String conversion - components:"

run_test("letter returns uppercase for first player") do
  raise "wrong letter" unless Sashite::Pin::Identifier.new(:K, :first).letter == "K"
end

run_test("letter returns lowercase for second player") do
  raise "wrong letter" unless Sashite::Pin::Identifier.new(:K, :second).letter == "k"
end

run_test("prefix returns empty for normal") do
  raise "wrong prefix" unless Sashite::Pin::Identifier.new(:K, :first, :normal).prefix == ""
end

run_test("prefix returns + for enhanced") do
  raise "wrong prefix" unless Sashite::Pin::Identifier.new(:K, :first, :enhanced).prefix == "+"
end

run_test("prefix returns - for diminished") do
  raise "wrong prefix" unless Sashite::Pin::Identifier.new(:K, :first, :diminished).prefix == "-"
end

run_test("suffix returns empty for non-terminal") do
  raise "wrong suffix" unless Sashite::Pin::Identifier.new(:K, :first).suffix == ""
end

run_test("suffix returns ^ for terminal") do
  raise "wrong suffix" unless Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: true).suffix == "^"
end

# ============================================================================
# STATE TRANSFORMATIONS
# ============================================================================

puts
puts "State transformations:"

run_test("enhance returns enhanced identifier") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  enhanced = pin.enhance
  raise "wrong state" unless enhanced.state == :enhanced
  raise "wrong abbr" unless enhanced.abbr == :K
  raise "wrong side" unless enhanced.side == :first
end

run_test("enhance returns self if already enhanced") do
  pin = Sashite::Pin::Identifier.new(:K, :first, :enhanced)
  raise "should return same object" unless pin.enhance.equal?(pin)
end

run_test("enhance preserves terminal") do
  pin = Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: true)
  raise "should preserve terminal" unless pin.enhance.terminal? == true
end

run_test("diminish returns diminished identifier") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  diminished = pin.diminish
  raise "wrong state" unless diminished.state == :diminished
end

run_test("diminish returns self if already diminished") do
  pin = Sashite::Pin::Identifier.new(:K, :first, :diminished)
  raise "should return same object" unless pin.diminish.equal?(pin)
end

run_test("normalize returns normal identifier") do
  pin = Sashite::Pin::Identifier.new(:K, :first, :enhanced)
  normalized = pin.normalize
  raise "wrong state" unless normalized.state == :normal
end

run_test("normalize returns self if already normal") do
  pin = Sashite::Pin::Identifier.new(:K, :first, :normal)
  raise "should return same object" unless pin.normalize.equal?(pin)
end

# ============================================================================
# SIDE TRANSFORMATIONS
# ============================================================================

puts
puts "Side transformations:"

run_test("flip changes first to second") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  flipped = pin.flip
  raise "wrong side" unless flipped.side == :second
  raise "wrong abbr" unless flipped.abbr == :K
end

run_test("flip changes second to first") do
  pin = Sashite::Pin::Identifier.new(:K, :second)
  flipped = pin.flip
  raise "wrong side" unless flipped.side == :first
end

run_test("flip preserves state") do
  pin = Sashite::Pin::Identifier.new(:K, :first, :enhanced)
  raise "should preserve state" unless pin.flip.state == :enhanced
end

run_test("flip preserves terminal") do
  pin = Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: true)
  raise "should preserve terminal" unless pin.flip.terminal? == true
end

# ============================================================================
# TERMINAL TRANSFORMATIONS
# ============================================================================

puts
puts "Terminal transformations:"

run_test("terminal returns terminal identifier") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  term = pin.terminal
  raise "should be terminal" unless term.terminal? == true
end

run_test("terminal returns self if already terminal") do
  pin = Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: true)
  raise "should return same object" unless pin.terminal.equal?(pin)
end

run_test("non_terminal returns non-terminal identifier") do
  pin = Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: true)
  non_term = pin.non_terminal
  raise "should not be terminal" unless non_term.terminal? == false
end

run_test("non_terminal returns self if not terminal") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  raise "should return same object" unless pin.non_terminal.equal?(pin)
end

# ============================================================================
# ATTRIBUTE TRANSFORMATIONS
# ============================================================================

puts
puts "Attribute transformations:"

run_test("with_abbr returns identifier with new abbr") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  queen = pin.with_abbr(:Q)
  raise "wrong abbr" unless queen.abbr == :Q
  raise "wrong side" unless queen.side == :first
end

run_test("with_abbr returns self if same abbr") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  raise "should return same object" unless pin.with_abbr(:K).equal?(pin)
end

run_test("with_abbr raises on invalid abbr") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  pin.with_abbr(:invalid)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INVALID_ABBR
end

run_test("with_side returns identifier with new side") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  second = pin.with_side(:second)
  raise "wrong side" unless second.side == :second
end

run_test("with_side returns self if same side") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  raise "should return same object" unless pin.with_side(:first).equal?(pin)
end

run_test("with_state returns identifier with new state") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  enhanced = pin.with_state(:enhanced)
  raise "wrong state" unless enhanced.state == :enhanced
end

run_test("with_state returns self if same state") do
  pin = Sashite::Pin::Identifier.new(:K, :first, :normal)
  raise "should return same object" unless pin.with_state(:normal).equal?(pin)
end

run_test("with_terminal returns identifier with new terminal") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  term = pin.with_terminal(true)
  raise "should be terminal" unless term.terminal? == true
end

run_test("with_terminal returns self if same terminal") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  raise "should return same object" unless pin.with_terminal(false).equal?(pin)
end

run_test("with_terminal raises on non-boolean") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  pin.with_terminal("true")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Pin::Errors::Argument::Messages::INVALID_TERMINAL
end

# ============================================================================
# STATE QUERIES
# ============================================================================

puts
puts "State queries:"

run_test("normal? returns true for normal state") do
  raise "should be normal" unless Sashite::Pin::Identifier.new(:K, :first, :normal).normal? == true
end

run_test("normal? returns false for enhanced state") do
  raise "should not be normal" unless Sashite::Pin::Identifier.new(:K, :first, :enhanced).normal? == false
end

run_test("normal? returns false for diminished state") do
  raise "should not be normal" unless Sashite::Pin::Identifier.new(:K, :first, :diminished).normal? == false
end

run_test("enhanced? returns true for enhanced state") do
  raise "should be enhanced" unless Sashite::Pin::Identifier.new(:K, :first, :enhanced).enhanced? == true
end

run_test("enhanced? returns false for other states") do
  raise "should not be enhanced" unless Sashite::Pin::Identifier.new(:K, :first, :normal).enhanced? == false
  raise "should not be enhanced" unless Sashite::Pin::Identifier.new(:K, :first, :diminished).enhanced? == false
end

run_test("diminished? returns true for diminished state") do
  raise "should be diminished" unless Sashite::Pin::Identifier.new(:K, :first, :diminished).diminished? == true
end

run_test("diminished? returns false for other states") do
  raise "should not be diminished" unless Sashite::Pin::Identifier.new(:K, :first, :normal).diminished? == false
  raise "should not be diminished" unless Sashite::Pin::Identifier.new(:K, :first, :enhanced).diminished? == false
end

# ============================================================================
# SIDE QUERIES
# ============================================================================

puts
puts "Side queries:"

run_test("first_player? returns true for first side") do
  raise "should be first" unless Sashite::Pin::Identifier.new(:K, :first).first_player? == true
end

run_test("first_player? returns false for second side") do
  raise "should not be first" unless Sashite::Pin::Identifier.new(:K, :second).first_player? == false
end

run_test("second_player? returns true for second side") do
  raise "should be second" unless Sashite::Pin::Identifier.new(:K, :second).second_player? == true
end

run_test("second_player? returns false for first side") do
  raise "should not be second" unless Sashite::Pin::Identifier.new(:K, :first).second_player? == false
end

# ============================================================================
# COMPARISON QUERIES
# ============================================================================

puts
puts "Comparison queries:"

run_test("same_abbr? returns true for same abbr") do
  pin1 = Sashite::Pin::Identifier.new(:K, :first)
  pin2 = Sashite::Pin::Identifier.new(:K, :second)
  raise "should have same abbr" unless pin1.same_abbr?(pin2) == true
end

run_test("same_abbr? returns false for different abbr") do
  pin1 = Sashite::Pin::Identifier.new(:K, :first)
  pin2 = Sashite::Pin::Identifier.new(:Q, :first)
  raise "should not have same abbr" unless pin1.same_abbr?(pin2) == false
end

run_test("same_side? returns true for same side") do
  pin1 = Sashite::Pin::Identifier.new(:K, :first)
  pin2 = Sashite::Pin::Identifier.new(:Q, :first)
  raise "should have same side" unless pin1.same_side?(pin2) == true
end

run_test("same_side? returns false for different side") do
  pin1 = Sashite::Pin::Identifier.new(:K, :first)
  pin2 = Sashite::Pin::Identifier.new(:K, :second)
  raise "should not have same side" unless pin1.same_side?(pin2) == false
end

run_test("same_state? returns true for same state") do
  pin1 = Sashite::Pin::Identifier.new(:K, :first, :enhanced)
  pin2 = Sashite::Pin::Identifier.new(:Q, :second, :enhanced)
  raise "should have same state" unless pin1.same_state?(pin2) == true
end

run_test("same_state? returns false for different state") do
  pin1 = Sashite::Pin::Identifier.new(:K, :first, :enhanced)
  pin2 = Sashite::Pin::Identifier.new(:K, :first, :normal)
  raise "should not have same state" unless pin1.same_state?(pin2) == false
end

run_test("same_terminal? returns true for same terminal") do
  pin1 = Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: true)
  pin2 = Sashite::Pin::Identifier.new(:Q, :second, :enhanced, terminal: true)
  raise "should have same terminal" unless pin1.same_terminal?(pin2) == true
end

run_test("same_terminal? returns false for different terminal") do
  pin1 = Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: true)
  pin2 = Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: false)
  raise "should not have same terminal" unless pin1.same_terminal?(pin2) == false
end

# ============================================================================
# EQUALITY
# ============================================================================

puts
puts "Equality:"

run_test("== returns true for equal identifiers") do
  pin1 = Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: false)
  pin2 = Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: false)
  raise "should be equal" unless pin1 == pin2
end

run_test("== returns false for different abbr") do
  pin1 = Sashite::Pin::Identifier.new(:K, :first)
  pin2 = Sashite::Pin::Identifier.new(:Q, :first)
  raise "should not be equal" if pin1 == pin2
end

run_test("== returns false for different side") do
  pin1 = Sashite::Pin::Identifier.new(:K, :first)
  pin2 = Sashite::Pin::Identifier.new(:K, :second)
  raise "should not be equal" if pin1 == pin2
end

run_test("== returns false for different state") do
  pin1 = Sashite::Pin::Identifier.new(:K, :first, :normal)
  pin2 = Sashite::Pin::Identifier.new(:K, :first, :enhanced)
  raise "should not be equal" if pin1 == pin2
end

run_test("== returns false for different terminal") do
  pin1 = Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: false)
  pin2 = Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: true)
  raise "should not be equal" if pin1 == pin2
end

run_test("== returns false for non-Identifier") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  raise "should not equal string" if pin == "K"
  raise "should not equal symbol" if pin == :K
  raise "should not equal nil" if pin == nil
end

# ============================================================================
# HASH
# ============================================================================

puts
puts "Hash:"

run_test("equal identifiers have same hash") do
  pin1 = Sashite::Pin::Identifier.new(:K, :first, :enhanced, terminal: true)
  pin2 = Sashite::Pin::Identifier.new(:K, :first, :enhanced, terminal: true)
  raise "hash should be equal" unless pin1.hash == pin2.hash
end

run_test("can be used as Hash key") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  hash = { pin => "value" }
  lookup = Sashite::Pin::Identifier.new(:K, :first)
  raise "hash lookup should work" unless hash[lookup] == "value"
end

# ============================================================================
# INSPECT
# ============================================================================

puts
puts "Inspect:"

run_test("returns readable representation for simple identifier") do
  pin = Sashite::Pin::Identifier.new(:K, :first)
  result = pin.inspect
  raise "should include class name" unless result.include?("Sashite::Pin::Identifier")
  raise "should include string representation" unless result.include?("K")
end

run_test("returns readable representation with modifiers") do
  pin = Sashite::Pin::Identifier.new(:K, :first, :enhanced, terminal: true)
  result = pin.inspect
  raise "should include full string representation" unless result.include?("+K^")
end

puts
puts "All Identifier tests passed!"
puts
