#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../helper"
require_relative "../../../lib/sashite/pin/identifier"

puts
puts "=== Identifier Tests ==="
puts

Id  = Sashite::Pin::Identifier
Msg = Sashite::Pin::Errors::Argument::Messages

# ============================================================================
# FLYWEIGHT POOL
# ============================================================================

puts "Flyweight pool:"

Test("pool contains 312 instances") do
  count = 0
  %i[A B C D E F G H I J K L M N O P Q R S T U V W X Y Z].each do |abbr|
    %i[first second].each do |side|
      %i[normal enhanced diminished].each do |state|
        [false, true].each do |terminal|
          pin = Id.fetch(abbr, side, state, terminal: terminal)
          raise "nil for #{abbr}/#{side}/#{state}/#{terminal}" if pin.nil?
          count += 1
        end
      end
    end
  end
  raise "wrong count: #{count}" unless count == 312
end

Test("all pool instances are frozen") do
  %i[K Q R P].each do |abbr|
    %i[first second].each do |side|
      %i[normal enhanced diminished].each do |state|
        [false, true].each do |terminal|
          raise "not frozen" unless Id.fetch(abbr, side, state, terminal: terminal).frozen?
        end
      end
    end
  end
end

Test("fetch returns identical object for same components") do
  a = Id.fetch(:K, :first)
  b = Id.fetch(:K, :first)
  raise "should be same object" unless a.equal?(b)
end

Test("fetch returns different objects for different components") do
  a = Id.fetch(:K, :first)
  b = Id.fetch(:K, :second)
  raise "should not be same object" if a.equal?(b)
end

# ============================================================================
# FETCH - VALID INPUTS
# ============================================================================

puts
puts "fetch - valid inputs:"

Test("fetch with abbr and side (defaults)") do
  pin = Id.fetch(:K, :first)
  raise "wrong abbr" unless pin.abbr == :K
  raise "wrong side" unless pin.side == :first
  raise "wrong state" unless pin.state == :normal
  raise "wrong terminal" unless pin.terminal? == false
end

Test("fetch with state") do
  pin = Id.fetch(:R, :second, :enhanced)
  raise "wrong abbr" unless pin.abbr == :R
  raise "wrong side" unless pin.side == :second
  raise "wrong state" unless pin.state == :enhanced
  raise "wrong terminal" unless pin.terminal? == false
end

Test("fetch with terminal") do
  pin = Id.fetch(:K, :first, :normal, terminal: true)
  raise "wrong abbr" unless pin.abbr == :K
  raise "wrong side" unless pin.side == :first
  raise "wrong state" unless pin.state == :normal
  raise "wrong terminal" unless pin.terminal? == true
end

Test("fetch with all attributes") do
  pin = Id.fetch(:Q, :second, :diminished, terminal: true)
  raise "wrong abbr" unless pin.abbr == :Q
  raise "wrong side" unless pin.side == :second
  raise "wrong state" unless pin.state == :diminished
  raise "wrong terminal" unless pin.terminal? == true
end

Test("fetch all valid abbrs A-Z") do
  (:A..:Z).each do |abbr|
    pin = Id.fetch(abbr, :first)
    raise "wrong abbr for #{abbr}" unless pin.abbr == abbr
  end
end

# ============================================================================
# FETCH - ERROR CASES
# ============================================================================

puts
puts "fetch - error cases:"

Test("raises on invalid abbr") do
  Id.fetch(:invalid, :first)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_ABBR
end

Test("raises on lowercase abbr symbol") do
  Id.fetch(:k, :first)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_ABBR
end

Test("raises on string abbr") do
  Id.fetch("K", :first)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_ABBR
end

Test("raises on invalid side") do
  Id.fetch(:K, :invalid)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_SIDE
end

Test("raises on invalid state") do
  Id.fetch(:K, :first, :invalid)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_STATE
end

Test("raises on non-boolean terminal") do
  Id.fetch(:K, :first, :normal, terminal: "true")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_TERMINAL
end

Test("raises on nil terminal") do
  Id.fetch(:K, :first, :normal, terminal: nil)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_TERMINAL
end

Test("raises on integer terminal") do
  Id.fetch(:K, :first, :normal, terminal: 1)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_TERMINAL
end

# ============================================================================
# CONSTRUCTOR (new) - still works for pool construction / backward compat
# ============================================================================

puts
puts "Constructor (new):"

Test("creates identifier with abbr and side") do
  pin = Id.new(:K, :first)
  raise "wrong abbr" unless pin.abbr == :K
  raise "wrong side" unless pin.side == :first
  raise "wrong state" unless pin.state == :normal
  raise "wrong terminal" unless pin.terminal? == false
end

Test("constructor raises on invalid abbr") do
  Id.new(:invalid, :first)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_ABBR
end

Test("constructor raises on invalid side") do
  Id.new(:K, :invalid)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_SIDE
end

Test("constructor raises on invalid state") do
  Id.new(:K, :first, :invalid)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_STATE
end

Test("constructor raises on non-boolean terminal") do
  Id.new(:K, :first, :normal, terminal: "true")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_TERMINAL
end

# ============================================================================
# STRING CONVERSION - TO_S (pre-computed)
# ============================================================================

puts
puts "String conversion - to_s:"

Test("formats simple first player") do
  raise "wrong" unless Id.fetch(:K, :first).to_s == "K"
end

Test("formats simple second player") do
  raise "wrong" unless Id.fetch(:K, :second).to_s == "k"
end

Test("formats enhanced first player") do
  raise "wrong" unless Id.fetch(:R, :first, :enhanced).to_s == "+R"
end

Test("formats enhanced second player") do
  raise "wrong" unless Id.fetch(:R, :second, :enhanced).to_s == "+r"
end

Test("formats diminished first player") do
  raise "wrong" unless Id.fetch(:P, :first, :diminished).to_s == "-P"
end

Test("formats diminished second player") do
  raise "wrong" unless Id.fetch(:P, :second, :diminished).to_s == "-p"
end

Test("formats terminal first player") do
  raise "wrong" unless Id.fetch(:K, :first, :normal, terminal: true).to_s == "K^"
end

Test("formats terminal second player") do
  raise "wrong" unless Id.fetch(:K, :second, :normal, terminal: true).to_s == "k^"
end

Test("formats enhanced terminal") do
  raise "wrong" unless Id.fetch(:K, :first, :enhanced, terminal: true).to_s == "+K^"
end

Test("formats diminished terminal") do
  raise "wrong" unless Id.fetch(:K, :second, :diminished, terminal: true).to_s == "-k^"
end

Test("to_s returns frozen string") do
  raise "should be frozen" unless Id.fetch(:K, :first).to_s.frozen?
end

# ============================================================================
# STATE TRANSFORMATIONS (zero-allocation, returns pool instance)
# ============================================================================

puts
puts "State transformations:"

Test("enhance returns enhanced identifier") do
  pin = Id.fetch(:K, :first)
  enhanced = pin.enhance
  raise "wrong state" unless enhanced.state == :enhanced
  raise "wrong abbr" unless enhanced.abbr == :K
  raise "wrong side" unless enhanced.side == :first
end

Test("enhance returns self if already enhanced") do
  pin = Id.fetch(:K, :first, :enhanced)
  raise "should return same object" unless pin.enhance.equal?(pin)
end

Test("enhance preserves terminal") do
  pin = Id.fetch(:K, :first, :normal, terminal: true)
  raise "should preserve terminal" unless pin.enhance.terminal? == true
end

Test("enhance returns pool instance") do
  pin = Id.fetch(:K, :first)
  raise "should be pool instance" unless pin.enhance.equal?(Id.fetch(:K, :first, :enhanced))
end

Test("diminish returns diminished identifier") do
  pin = Id.fetch(:K, :first)
  diminished = pin.diminish
  raise "wrong state" unless diminished.state == :diminished
end

Test("diminish returns self if already diminished") do
  pin = Id.fetch(:K, :first, :diminished)
  raise "should return same object" unless pin.diminish.equal?(pin)
end

Test("diminish returns pool instance") do
  pin = Id.fetch(:K, :first)
  raise "should be pool instance" unless pin.diminish.equal?(Id.fetch(:K, :first, :diminished))
end

Test("normalize returns normal identifier") do
  pin = Id.fetch(:K, :first, :enhanced)
  normalized = pin.normalize
  raise "wrong state" unless normalized.state == :normal
end

Test("normalize returns self if already normal") do
  pin = Id.fetch(:K, :first, :normal)
  raise "should return same object" unless pin.normalize.equal?(pin)
end

Test("normalize returns pool instance") do
  pin = Id.fetch(:K, :first, :enhanced)
  raise "should be pool instance" unless pin.normalize.equal?(Id.fetch(:K, :first))
end

# ============================================================================
# SIDE TRANSFORMATIONS (zero-allocation, returns pool instance)
# ============================================================================

puts
puts "Side transformations:"

Test("flip changes first to second") do
  pin = Id.fetch(:K, :first)
  flipped = pin.flip
  raise "wrong side" unless flipped.side == :second
  raise "wrong abbr" unless flipped.abbr == :K
end

Test("flip changes second to first") do
  pin = Id.fetch(:K, :second)
  flipped = pin.flip
  raise "wrong side" unless flipped.side == :first
end

Test("flip preserves state") do
  pin = Id.fetch(:K, :first, :enhanced)
  raise "should preserve state" unless pin.flip.state == :enhanced
end

Test("flip preserves terminal") do
  pin = Id.fetch(:K, :first, :normal, terminal: true)
  raise "should preserve terminal" unless pin.flip.terminal? == true
end

Test("flip returns pool instance") do
  pin = Id.fetch(:K, :first)
  raise "should be pool instance" unless pin.flip.equal?(Id.fetch(:K, :second))
end

Test("double flip returns self") do
  pin = Id.fetch(:K, :first, :enhanced, terminal: true)
  raise "should return same object" unless pin.flip.flip.equal?(pin)
end

# ============================================================================
# TERMINAL TRANSFORMATIONS (zero-allocation, returns pool instance)
# ============================================================================

puts
puts "Terminal transformations:"

Test("terminal returns terminal identifier") do
  pin = Id.fetch(:K, :first)
  term = pin.terminal
  raise "should be terminal" unless term.terminal? == true
end

Test("terminal returns self if already terminal") do
  pin = Id.fetch(:K, :first, :normal, terminal: true)
  raise "should return same object" unless pin.terminal.equal?(pin)
end

Test("terminal returns pool instance") do
  pin = Id.fetch(:K, :first)
  raise "should be pool instance" unless pin.terminal.equal?(Id.fetch(:K, :first, :normal, terminal: true))
end

Test("non_terminal returns non-terminal identifier") do
  pin = Id.fetch(:K, :first, :normal, terminal: true)
  non_term = pin.non_terminal
  raise "should not be terminal" unless non_term.terminal? == false
end

Test("non_terminal returns self if not terminal") do
  pin = Id.fetch(:K, :first)
  raise "should return same object" unless pin.non_terminal.equal?(pin)
end

Test("non_terminal returns pool instance") do
  pin = Id.fetch(:K, :first, :normal, terminal: true)
  raise "should be pool instance" unless pin.non_terminal.equal?(Id.fetch(:K, :first))
end

# ============================================================================
# ATTRIBUTE TRANSFORMATIONS (validated, returns pool instance)
# ============================================================================

puts
puts "Attribute transformations:"

Test("with_abbr returns identifier with new abbr") do
  pin = Id.fetch(:K, :first)
  queen = pin.with_abbr(:Q)
  raise "wrong abbr" unless queen.abbr == :Q
  raise "wrong side" unless queen.side == :first
end

Test("with_abbr returns self if same abbr") do
  pin = Id.fetch(:K, :first)
  raise "should return same object" unless pin.with_abbr(:K).equal?(pin)
end

Test("with_abbr returns pool instance") do
  pin = Id.fetch(:K, :first)
  raise "should be pool instance" unless pin.with_abbr(:Q).equal?(Id.fetch(:Q, :first))
end

Test("with_abbr raises on invalid abbr") do
  pin = Id.fetch(:K, :first)
  pin.with_abbr(:invalid)
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_ABBR
end

Test("with_side returns identifier with new side") do
  pin = Id.fetch(:K, :first)
  second = pin.with_side(:second)
  raise "wrong side" unless second.side == :second
end

Test("with_side returns self if same side") do
  pin = Id.fetch(:K, :first)
  raise "should return same object" unless pin.with_side(:first).equal?(pin)
end

Test("with_side returns pool instance") do
  pin = Id.fetch(:K, :first)
  raise "should be pool instance" unless pin.with_side(:second).equal?(Id.fetch(:K, :second))
end

Test("with_state returns identifier with new state") do
  pin = Id.fetch(:K, :first)
  enhanced = pin.with_state(:enhanced)
  raise "wrong state" unless enhanced.state == :enhanced
end

Test("with_state returns self if same state") do
  pin = Id.fetch(:K, :first, :normal)
  raise "should return same object" unless pin.with_state(:normal).equal?(pin)
end

Test("with_state returns pool instance") do
  pin = Id.fetch(:K, :first)
  raise "should be pool instance" unless pin.with_state(:enhanced).equal?(Id.fetch(:K, :first, :enhanced))
end

Test("with_terminal returns identifier with new terminal") do
  pin = Id.fetch(:K, :first)
  term = pin.with_terminal(true)
  raise "should be terminal" unless term.terminal? == true
end

Test("with_terminal returns self if same terminal") do
  pin = Id.fetch(:K, :first)
  raise "should return same object" unless pin.with_terminal(false).equal?(pin)
end

Test("with_terminal returns pool instance") do
  pin = Id.fetch(:K, :first)
  raise "should be pool instance" unless pin.with_terminal(true).equal?(Id.fetch(:K, :first, :normal, terminal: true))
end

Test("with_terminal raises on non-boolean") do
  pin = Id.fetch(:K, :first)
  pin.with_terminal("true")
  raise "should have raised"
rescue Sashite::Pin::Errors::Argument => e
  raise "wrong message" unless e.message == Msg::INVALID_TERMINAL
end

# ============================================================================
# TRANSFORMATION CHAINING (zero-allocation end-to-end)
# ============================================================================

puts
puts "Transformation chaining:"

Test("chained transformations return pool instance") do
  result = Id.fetch(:P, :first).enhance.flip.terminal
  expected = Id.fetch(:P, :second, :enhanced, terminal: true)
  raise "should be pool instance" unless result.equal?(expected)
end

Test("all intermediate steps are pool instances") do
  a = Id.fetch(:R, :first)
  b = a.enhance
  c = b.flip
  d = c.terminal
  e = d.diminish

  raise "b not pooled" unless b.equal?(Id.fetch(:R, :first, :enhanced))
  raise "c not pooled" unless c.equal?(Id.fetch(:R, :second, :enhanced))
  raise "d not pooled" unless d.equal?(Id.fetch(:R, :second, :enhanced, terminal: true))
  raise "e not pooled" unless e.equal?(Id.fetch(:R, :second, :diminished, terminal: true))
end

# ============================================================================
# STATE QUERIES
# ============================================================================

puts
puts "State queries:"

Test("normal? returns true for normal state") do
  raise "should be normal" unless Id.fetch(:K, :first, :normal).normal? == true
end

Test("normal? returns false for enhanced state") do
  raise "should not be normal" unless Id.fetch(:K, :first, :enhanced).normal? == false
end

Test("normal? returns false for diminished state") do
  raise "should not be normal" unless Id.fetch(:K, :first, :diminished).normal? == false
end

Test("enhanced? returns true for enhanced state") do
  raise "should be enhanced" unless Id.fetch(:K, :first, :enhanced).enhanced? == true
end

Test("enhanced? returns false for other states") do
  raise "should not be enhanced" unless Id.fetch(:K, :first, :normal).enhanced? == false
  raise "should not be enhanced" unless Id.fetch(:K, :first, :diminished).enhanced? == false
end

Test("diminished? returns true for diminished state") do
  raise "should be diminished" unless Id.fetch(:K, :first, :diminished).diminished? == true
end

Test("diminished? returns false for other states") do
  raise "should not be diminished" unless Id.fetch(:K, :first, :normal).diminished? == false
  raise "should not be diminished" unless Id.fetch(:K, :first, :enhanced).diminished? == false
end

# ============================================================================
# SIDE QUERIES
# ============================================================================

puts
puts "Side queries:"

Test("first_player? returns true for first side") do
  raise "should be first" unless Id.fetch(:K, :first).first_player? == true
end

Test("first_player? returns false for second side") do
  raise "should not be first" unless Id.fetch(:K, :second).first_player? == false
end

Test("second_player? returns true for second side") do
  raise "should be second" unless Id.fetch(:K, :second).second_player? == true
end

Test("second_player? returns false for first side") do
  raise "should not be second" unless Id.fetch(:K, :first).second_player? == false
end

# ============================================================================
# COMPARISON QUERIES
# ============================================================================

puts
puts "Comparison queries:"

Test("same_abbr? returns true for same abbr") do
  pin1 = Id.fetch(:K, :first)
  pin2 = Id.fetch(:K, :second)
  raise "should have same abbr" unless pin1.same_abbr?(pin2) == true
end

Test("same_abbr? returns false for different abbr") do
  pin1 = Id.fetch(:K, :first)
  pin2 = Id.fetch(:Q, :first)
  raise "should not have same abbr" unless pin1.same_abbr?(pin2) == false
end

Test("same_side? returns true for same side") do
  pin1 = Id.fetch(:K, :first)
  pin2 = Id.fetch(:Q, :first)
  raise "should have same side" unless pin1.same_side?(pin2) == true
end

Test("same_side? returns false for different side") do
  pin1 = Id.fetch(:K, :first)
  pin2 = Id.fetch(:K, :second)
  raise "should not have same side" unless pin1.same_side?(pin2) == false
end

Test("same_state? returns true for same state") do
  pin1 = Id.fetch(:K, :first, :enhanced)
  pin2 = Id.fetch(:Q, :second, :enhanced)
  raise "should have same state" unless pin1.same_state?(pin2) == true
end

Test("same_state? returns false for different state") do
  pin1 = Id.fetch(:K, :first, :enhanced)
  pin2 = Id.fetch(:K, :first, :normal)
  raise "should not have same state" unless pin1.same_state?(pin2) == false
end

Test("same_terminal? returns true for same terminal") do
  pin1 = Id.fetch(:K, :first, :normal, terminal: true)
  pin2 = Id.fetch(:Q, :second, :enhanced, terminal: true)
  raise "should have same terminal" unless pin1.same_terminal?(pin2) == true
end

Test("same_terminal? returns false for different terminal") do
  pin1 = Id.fetch(:K, :first, :normal, terminal: true)
  pin2 = Id.fetch(:K, :first, :normal, terminal: false)
  raise "should not have same terminal" unless pin1.same_terminal?(pin2) == false
end

# ============================================================================
# EQUALITY
# ============================================================================

puts
puts "Equality:"

Test("== returns true for same pool instance") do
  pin1 = Id.fetch(:K, :first)
  pin2 = Id.fetch(:K, :first)
  raise "should be equal" unless pin1 == pin2
end

Test("== returns true via identity shortcut") do
  pin = Id.fetch(:K, :first)
  raise "should be equal" unless pin == pin
end

Test("== returns true for new instance with same attributes") do
  pool  = Id.fetch(:K, :first, :enhanced, terminal: true)
  fresh = Id.new(:K, :first, :enhanced, terminal: true)
  raise "should be equal" unless pool == fresh
end

Test("== returns false for different abbr") do
  raise "should not be equal" if Id.fetch(:K, :first) == Id.fetch(:Q, :first)
end

Test("== returns false for different side") do
  raise "should not be equal" if Id.fetch(:K, :first) == Id.fetch(:K, :second)
end

Test("== returns false for different state") do
  raise "should not be equal" if Id.fetch(:K, :first, :normal) == Id.fetch(:K, :first, :enhanced)
end

Test("== returns false for different terminal") do
  raise "should not be equal" if Id.fetch(:K, :first) == Id.fetch(:K, :first, :normal, terminal: true)
end

Test("== returns false for non-Identifier") do
  pin = Id.fetch(:K, :first)
  raise "should not equal string" if pin == "K"
  raise "should not equal symbol" if pin == :K
  raise "should not equal nil" if pin == nil
end

# ============================================================================
# HASH
# ============================================================================

puts
puts "Hash:"

Test("equal identifiers have same hash") do
  pin1 = Id.fetch(:K, :first, :enhanced, terminal: true)
  pin2 = Id.fetch(:K, :first, :enhanced, terminal: true)
  raise "hash should be equal" unless pin1.hash == pin2.hash
end

Test("new instance has same hash as pool instance") do
  pool  = Id.fetch(:K, :first)
  fresh = Id.new(:K, :first)
  raise "hash should be equal" unless pool.hash == fresh.hash
end

Test("can be used as Hash key") do
  pin = Id.fetch(:K, :first)
  hash = { pin => "value" }
  raise "hash lookup should work" unless hash[Id.fetch(:K, :first)] == "value"
end

Test("all 312 instances have distinct hashes") do
  hashes = ::Set.new
  %i[A B C D E F G H I J K L M N O P Q R S T U V W X Y Z].each do |abbr|
    %i[first second].each do |side|
      %i[normal enhanced diminished].each do |state|
        [false, true].each do |terminal|
          hashes.add(Id.fetch(abbr, side, state, terminal: terminal).hash)
        end
      end
    end
  end
  raise "expected 312, got #{hashes.size}" unless hashes.size == 312
end

# ============================================================================
# INSPECT (pre-computed)
# ============================================================================

puts
puts "Inspect:"

Test("returns readable representation for simple identifier") do
  result = Id.fetch(:K, :first).inspect
  raise "should include class name" unless result.include?("Sashite::Pin::Identifier")
  raise "should include string representation" unless result.include?("K")
end

Test("returns readable representation with modifiers") do
  result = Id.fetch(:K, :first, :enhanced, terminal: true).inspect
  raise "should include full string representation" unless result.include?("+K^")
end

Test("inspect returns frozen string") do
  raise "should be frozen" unless Id.fetch(:K, :first).inspect.frozen?
end

puts
puts "All Identifier tests passed!"
puts
