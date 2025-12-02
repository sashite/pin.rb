# Pin.rb

[![Version](https://img.shields.io/github/v/tag/sashite/pin.rb?label=Version&logo=github)](https://github.com/sashite/pin.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/sashite/pin.rb/main)
![Ruby](https://github.com/sashite/pin.rb/actions/workflows/main.yml/badge.svg?branch=main)
[![License](https://img.shields.io/github/license/sashite/pin.rb?label=License&logo=github)](https://github.com/sashite/pin.rb/raw/main/LICENSE.md)

> **PIN** (Piece Identifier Notation) implementation for the Ruby language.

## What is PIN?

PIN (Piece Identifier Notation) provides an ASCII-based format for representing pieces in abstract strategy board games. PIN translates piece attributes from the [Game Protocol](https://sashite.dev/game-protocol/) into a compact, portable notation system.

This gem implements the [PIN Specification v1.0.0](https://sashite.dev/specs/pin/1.0.0/), providing a modern Ruby interface with immutable identifier objects and functional programming principles.

## Installation

```ruby
# In your Gemfile
gem "sashite-pin"
```

Or install manually:

```sh
gem install sashite-pin
```

## Usage

```ruby
require "sashite/pin"

# Parse PIN strings into identifier objects
identifier = Sashite::Pin.parse("K")          # => #<Pin::Identifier type=:K side=:first state=:normal terminal=false>
identifier.to_s                               # => "K"
identifier.type                               # => :K
identifier.side                               # => :first
identifier.state                              # => :normal
identifier.terminal?                          # => false

# Parse terminal pieces (e.g., kings in chess)
terminal_king = Sashite::Pin.parse("K^")      # => #<Pin::Identifier type=:K side=:first state=:normal terminal=true>
terminal_king.to_s                            # => "K^"
terminal_king.terminal?                       # => true

# Create identifiers directly
identifier = Sashite::Pin.identifier(:K, :first, :normal)                    # => #<Pin::Identifier type=:K side=:first state=:normal>
terminal_king = Sashite::Pin.identifier(:K, :first, :normal, terminal: true) # => #<Pin::Identifier type=:K side=:first state=:normal terminal=true>
identifier = Sashite::Pin::Identifier.new(:R, :second, :enhanced)  # => #<Pin::Identifier type=:R side=:second state=:enhanced>

# Validate PIN strings
Sashite::Pin.valid?("K")                 # => true
Sashite::Pin.valid?("+R")                # => true
Sashite::Pin.valid?("K^")                # => true
Sashite::Pin.valid?("+K^")               # => true
Sashite::Pin.valid?("invalid")           # => false

# State manipulation (returns new immutable instances)
enhanced = identifier.enhance                 # => #<Pin::Identifier type=:K side=:first state=:enhanced>
enhanced.to_s                                 # => "+K"
diminished = identifier.diminish              # => #<Pin::Identifier type=:K side=:first state=:diminished>
diminished.to_s                               # => "-K"

# Terminal marker manipulation
normal_king = Sashite::Pin.parse("K")
terminal_king = normal_king.mark_terminal     # => "K^"
back_to_normal = terminal_king.unmark_terminal # => "K"

# Side manipulation
flipped = identifier.flip                     # => #<Pin::Identifier type=:K side=:second state=:normal>
flipped.to_s                                  # => "k"

# Type manipulation
queen = identifier.with_type(:Q)              # => #<Pin::Identifier type=:Q side=:first state=:normal>
queen.to_s                                    # => "Q"

# State queries
identifier.normal?                            # => true
enhanced.enhanced?                            # => true
diminished.diminished?                        # => true

# Side queries
identifier.first_player?                      # => true
flipped.second_player?                        # => true

# Attribute access
identifier.letter                             # => "K"
enhanced.prefix                               # => "+"
identifier.prefix                             # => ""
terminal_king.suffix                          # => "^"

# Type and side comparison
king1 = Sashite::Pin.parse("K")
king2 = Sashite::Pin.parse("k")
queen = Sashite::Pin.parse("Q")

king1.same_type?(king2)                       # => true (both kings)
king1.same_side?(queen)                       # => true (both first player)
king1.same_type?(queen)                       # => false (different types)

# Functional transformations can be chained
pawn = Sashite::Pin.parse("P")
enemy_promoted = pawn.flip.enhance            # => "+p" (second player promoted pawn)

# Transformations preserve terminal status
terminal_piece = Sashite::Pin.parse("K^")
enhanced_terminal = terminal_piece.enhance    # => "+K^"
```

## Format Specification

### Structure

```
[<state-modifier>]<letter>[<terminal-marker>]
```

### Components

* **Letter** (`A-Z`, `a-z`): Represents piece type and side

  * Uppercase: First player pieces
  * Lowercase: Second player pieces
* **State Modifier** (optional prefix):

  * `+`: Enhanced state (promoted, upgraded, empowered)
  * `-`: Diminished state (weakened, restricted, temporary)
  * No prefix: Normal state
* **Terminal Marker** (optional suffix):

  * `^`: Terminal piece (critical to match continuation)
  * No suffix: Non-terminal piece

### Regular Expression

```ruby
/\A[-+]?[A-Za-z]\^?\z/
```

### Examples

* `K` - First player king (normal state)
* `K^` - First player king (normal state, terminal)
* `k` - Second player king (normal state)
* `k^` - Second player king (normal state, terminal)
* `+R` - First player rook (enhanced state)
* `+R^` - First player rook (enhanced state, terminal)
* `-p` - Second player pawn (diminished state)

## API Reference

### Main Module Methods

* `Sashite::Pin.valid?(pin_string)` - Check if string is valid PIN notation
* `Sashite::Pin.parse(pin_string)` - Parse PIN string into Identifier object
* `Sashite::Pin.identifier(type, side, state = :normal, terminal: false)` - Create identifier instance directly

### Identifier Class

#### Creation and Parsing

* `Sashite::Pin::Identifier.new(type, side, state = :normal, terminal: false)` - Create identifier instance
* `Sashite::Pin::Identifier.parse(pin_string)` - Parse PIN string (same as module method)
* `Sashite::Pin::Identifier.valid?(pin_string)` - Validate PIN string (class method)

#### Attribute Access

* `#type` - Get piece type (symbol \:A to \:Z, always uppercase)
* `#side` - Get player side (\:first or \:second)
* `#state` - Get state (\:normal, \:enhanced, or \:diminished)
* `#terminal` - Get terminal status (Boolean)
* `#letter` - Get letter representation (string, case determined by side)
* `#prefix` - Get state prefix (string: "+", "-", or "")
* `#suffix` - Get terminal marker (string: "^" or "")
* `#to_s` - Convert to PIN string representation

#### Type and Case Handling

**Important**: The `type` attribute is always stored as an uppercase symbol (`:A` to `:Z`), regardless of the input case when parsing. The display case in `#letter` and `#to_s` is determined by the `side` attribute:

```ruby
# Both create the same internal type representation
identifier1 = Sashite::Pin.parse("K")  # type: :K, side: :first
identifier2 = Sashite::Pin.parse("k")  # type: :K, side: :second

identifier1.type    # => :K (uppercase symbol)
identifier2.type    # => :K (same uppercase symbol)

identifier1.letter  # => "K" (uppercase display)
identifier2.letter  # => "k" (lowercase display)
```

#### State Queries

* `#normal?` - Check if normal state (no modifiers)
* `#enhanced?` - Check if enhanced state
* `#diminished?` - Check if diminished state

#### Side Queries

* `#first_player?` - Check if first player identifier
* `#second_player?` - Check if second player identifier

#### Terminal Queries

* `#terminal?` - Check if terminal piece

#### State Transformations (immutable - return new instances)

* `#enhance` - Create enhanced version
* `#unenhance` - Remove enhanced state
* `#diminish` - Create diminished version
* `#undiminish` - Remove diminished state
* `#normalize` - Remove all state modifiers
* `#flip` - Switch player (change side)

#### Attribute Transformations (immutable - return new instances)

* `#with_type(new_type)` - Create identifier with different type
* `#with_side(new_side)` - Create identifier with different side
* `#with_state(new_state)` - Create identifier with different state

#### Terminal Transformations (immutable - return new instances)

* `#mark_terminal` - Create terminal version
* `#unmark_terminal` - Create non-terminal version
* `#with_terminal(boolean)` - Create identifier with specified terminal status

#### Comparison Methods

* `#same_type?(other)` - Check if same piece type
* `#same_side?(other)` - Check if same side
* `#same_state?(other)` - Check if same state
* `#same_terminal?(other)` - Check if same terminal status
* `#==(other)` - Full equality comparison

### Constants

* `Sashite::Pin::Identifier::PIN_PATTERN` - Regular expression for PIN validation (internal use)
* `Sashite::Pin::Identifier::TERMINAL_MARKER` - Terminal marker character (`"^"`)

## Advanced Usage

### Type Normalization Examples

```ruby
# Parsing different cases results in same type
white_king = Sashite::Pin.parse("K")
black_king = Sashite::Pin.parse("k")

# Types are normalized to uppercase
white_king.type  # => :K
black_king.type  # => :K (same type!)

# Sides are different
white_king.side  # => :first
black_king.side  # => :second

# Display follows side convention
white_king.letter # => "K"
black_king.letter # => "k"

# Same type, different sides
white_king.same_type?(black_king)  # => true
white_king.same_side?(black_king)  # => false
```

### Immutable Transformations
```ruby
# All transformations return new instances
original = Sashite::Pin.identifier(:K, :first, :normal)
enhanced = original.enhance
diminished = original.diminish

# Original piece is never modified
puts original.to_s    # => "K"
puts enhanced.to_s    # => "+K"
puts diminished.to_s  # => "-K"

# Transformations can be chained
result = original.flip.enhance.with_type(:Q)
puts result.to_s      # => "+q"

# Terminal status is preserved through transformations
terminal_king = Sashite::Pin.parse("K^")
enhanced_terminal = terminal_king.enhance
puts enhanced_terminal.to_s  # => "+K^"
```

### Game State Management
```ruby
class GameBoard
  def initialize
    @pieces = {}
  end

  def place(square, piece)
    @pieces[square] = piece
  end

  def promote(square, new_type = :Q)
    piece = @pieces[square]
    return nil unless piece&.normal?  # Can only promote normal pieces

    @pieces[square] = piece.with_type(new_type).enhance
  end

  def capture(from_square, to_square)
    captured = @pieces[to_square]
    @pieces[to_square] = @pieces.delete(from_square)
    captured
  end

  def pieces_by_side(side)
    @pieces.select { |_, piece| piece.side == side }
  end

  def promoted_pieces
    @pieces.select { |_, piece| piece.enhanced? }
  end

  def terminal_pieces
    @pieces.select { |_, piece| piece.terminal? }
  end
end

# Usage
board = GameBoard.new
board.place("e1", Sashite::Pin.identifier(:K, :first, :normal, terminal: true))
board.place("e8", Sashite::Pin.identifier(:K, :second, :normal, terminal: true))
board.place("a7", Sashite::Pin.identifier(:P, :first, :normal))

# Promote pawn
board.promote("a7", :Q)
promoted = board.promoted_pieces
puts promoted.values.first.to_s  # => "+Q"
```

### Piece Analysis
```ruby
def analyze_pieces(pins)
  pieces = pins.map { |pin| Sashite::Pin.parse(pin) }

  {
    total: pieces.size,
    by_side: pieces.group_by(&:side),
    by_type: pieces.group_by(&:type),
    by_state: pieces.group_by(&:state),
    promoted: pieces.count(&:enhanced?),
    weakened: pieces.count(&:diminished?),
    terminal: pieces.count(&:terminal?)
  }
end

pins = %w[K^ Q +R B N P k^ q r +b n -p]
analysis = analyze_pieces(pins)
puts analysis[:by_side][:first].size  # => 6
puts analysis[:promoted]              # => 2
puts analysis[:terminal]              # => 2
```

### Move Validation Example
```ruby
def can_promote?(piece, target_rank)
  return false unless piece.normal?  # Already promoted pieces can't promote again

  case piece.type
  when :P  # Pawn
    (piece.first_player? && target_rank == 8) ||
    (piece.second_player? && target_rank == 1)
  when :R, :B, :S, :N, :L  # Shōgi pieces that can promote
    true
  else
    false
  end
end

pawn = Sashite::Pin.identifier(:P, :first, :normal)
puts can_promote?(pawn, 8)          # => true

promoted_pawn = pawn.enhance
puts can_promote?(promoted_pawn, 8) # => false (already promoted)
```

## Protocol Mapping

Following the [Game Protocol](https://sashite.dev/game-protocol/):

| Protocol Attribute | PIN Encoding | Examples | Notes |
|-------------------|--------------|----------|-------|
| **Piece Name** | ASCII letter choice | `K`/`k` = King, `P`/`p` = Pawn | Type is always stored as uppercase symbol (`:K`, `:P`) |
| **Piece Side** | Letter case in display | `K` = First player, `k` = Second player | Case is determined by side during rendering |
| **Piece State** | Optional prefix | `+K` = Enhanced, `-K` = Diminished, `K` = Normal | |
| **Terminal Status** | Optional suffix | `K^` = Terminal, `K` = Non-terminal | Identifies pieces critical to match continuation |

**Type Convention**: All piece types are internally represented as uppercase symbols (`:A` to `:Z`). The display case is determined by the `side` attribute: first player pieces display as uppercase, second player pieces as lowercase.

**Canonical principle**: Identical pieces must have identical PIN representations.

**Note**: PIN does not represent the **Style** attribute from the Game Protocol. For style-aware piece notation, see [Piece Name Notation (PNN)](https://sashite.dev/specs/pnn/).

## Properties

* **ASCII Compatible**: Maximum portability across systems
* **Rule-Agnostic**: Independent of specific game mechanics
* **Compact Format**: 1-3 characters per piece
* **Visual Distinction**: Clear player differentiation through case
* **Type Normalization**: Consistent uppercase type representation internally
* **Terminal Marker**: Explicit identification of pieces critical to match continuation
* **Protocol Compliant**: Direct implementation of Sashité piece attributes
* **Immutable**: All piece instances are frozen and transformations return new objects
* **Functional**: Pure functions with no side effects

## Implementation Notes

### Type Normalization Convention

PIN follows a strict type normalization convention:

1. **Internal Storage**: All piece types are stored as uppercase symbols (`:A` to `:Z`)
2. **Input Flexibility**: Both `"K"` and `"k"` are valid input during parsing
3. **Case Semantics**: Input case determines the `side` attribute, not the `type`
4. **Display Logic**: Output case is computed from `side` during rendering

This design ensures:
- Consistent internal representation regardless of input format
- Clear separation between piece identity (type) and ownership (side)
- Predictable behavior when comparing pieces of the same type

### Terminal Marker Convention

The terminal marker (`^`) identifies pieces whose presence, condition, or capacity for action determines whether the match can continue:

1. **Suffix Position**: Always appears as the last character (`K^`, `+K^`, `-k^`)
2. **Preservation**: Terminal status is preserved through all transformations
3. **Equality**: Two pieces are equal only if they have the same terminal status
4. **Independence**: Terminal status is independent of state (normal/enhanced/diminished)

### Example Flow

```ruby
# Input: "k" (lowercase)
# ↓ Parsing
# type: :K (normalized to uppercase)
# side: :second (inferred from lowercase input)
# ↓ Display
# letter: "k" (computed from type + side)
# PIN: "k" (final representation)
```

This ensures that `parse(pin).to_s == pin` for all valid PIN strings while maintaining internal consistency.

## System Constraints

- **Maximum 26 piece types** per game system (one per ASCII letter)
- **Exactly 2 players** (uppercase/lowercase distinction)
- **3 state levels** (enhanced, normal, diminished)
- **2 terminal levels** (terminal, non-terminal)

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) - Conceptual foundation for abstract strategy board games
- [PNN](https://sashite.dev/specs/pnn/) - Piece Name Notation (style-aware piece representation)
- [CELL](https://sashite.dev/specs/cell/) - Board position coordinates
- [HAND](https://sashite.dev/specs/hand/) - Reserve location notation
- [PMN](https://sashite.dev/specs/pmn/) - Portable Move Notation

## Documentation

- [Official PIN Specification v1.0.0](https://sashite.dev/specs/pin/1.0.0/)
- [PIN Examples Documentation](https://sashite.dev/specs/pin/1.0.0/examples/)
- [Game Protocol Foundation](https://sashite.dev/game-protocol/)
- [API Documentation](https://rubydoc.info/github/sashite/pin.rb/main)

## Development

```sh
# Clone the repository
git clone https://github.com/sashite/pin.rb.git
cd pin.rb

# Install dependencies
bundle install

# Run tests
ruby test.rb

# Generate documentation
yard doc
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Add tests for your changes
4. Ensure all tests pass (`ruby test.rb`)
5. Commit your changes (`git commit -am 'Add new feature'`)
6. Push to the branch (`git push origin feature/new-feature`)
7. Create a Pull Request

## License

Available as open source under the [MIT License](https://opensource.org/licenses/MIT).

## About

Maintained by [Sashité](https://sashite.com/) — promoting chess variants and sharing the beauty of board game cultures.
