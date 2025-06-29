# Pin.rb

[![Version](https://img.shields.io/github/v/tag/sashite/pin.rb?label=Version&logo=github)](https://github.com/sashite/pin.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/sashite/pin.rb/main)
![Ruby](https://github.com/sashite/pin.rb/actions/workflows/main.yml/badge.svg?branch=main)
[![License](https://img.shields.io/github/license/sashite/pin.rb?label=License&logo=github)](https://github.com/sashite/pin.rb/raw/main/LICENSE.md)

> **PIN** (Piece Identifier Notation) implementation for the Ruby language.

## What is PIN?

PIN (Piece Identifier Notation) provides an ASCII-based format for representing pieces in abstract strategy board games. PIN translates piece attributes from the [Game Protocol](https://sashite.dev/game-protocol/) into a compact, portable notation system.

This gem implements the [PIN Specification v1.0.0](https://sashite.dev/specs/pin/1.0.0/), providing a modern Ruby interface with immutable piece objects and functional programming principles.

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

# Parse PIN strings into piece objects
piece = Sashite::Pin.parse("K")          # => #<Pin::Piece letter="K" type="K" player=first>
piece.to_s                               # => "K"
piece.first_player?                      # => true
piece.type                               # => "K"
piece.side                               # => :first

# Validate PIN strings
Sashite::Pin.valid?("K")                 # => true
Sashite::Pin.valid?("+R")                # => true
Sashite::Pin.valid?("invalid")           # => false

# State manipulation (returns new immutable instances)
enhanced = piece.enhance                 # => #<Pin::Piece letter="K" type="K" player=first enhanced=true>
enhanced.to_s                            # => "+K"
diminished = piece.diminish              # => #<Pin::Piece letter="K" type="K" player=first diminished=true>
diminished.to_s                          # => "-K"

# Player manipulation
flipped = piece.flip                     # => #<Pin::Piece letter="k" type="K" player=second>
flipped.to_s                             # => "k"

# State queries
piece.normal?                            # => true
enhanced.enhanced?                       # => true
diminished.diminished?                   # => true

# Type and player comparison
king1 = Sashite::Pin.parse("K")
king2 = Sashite::Pin.parse("k")
queen = Sashite::Pin.parse("Q")

king1.same_type?(king2)                  # => true (both kings)
king1.same_player?(queen)                # => true (both first player)
king1.same_type?(queen)                  # => false (different types)

# Functional transformations can be chained
pawn = Sashite::Pin.parse("P")
enemy_promoted = pawn.flip.enhance       # => "+p" (black promoted pawn)
```

## Format Specification

### Structure
```
[<state>]<letter>
```

### Components

- **Letter** (`A-Z`, `a-z`): Represents piece type and player
  - Uppercase: First player pieces
  - Lowercase: Second player pieces
- **State** (optional prefix):
  - `+`: Enhanced state (promoted, upgraded, empowered)
  - `-`: Diminished state (weakened, restricted, temporary)
  - No prefix: Normal state

### Regular Expression
```ruby
/\A[-+]?[A-Za-z]\z/
```

### Examples
- `K` - First player king (normal state)
- `k` - Second player king (normal state)
- `+R` - First player rook (enhanced state)
- `-p` - Second player pawn (diminished state)

## Game Examples

### Western Chess
```ruby
# Standard pieces
king = Sashite::Pin.parse("K")        # => white king
king.first_player?                    # => true
king.type                             # => "K"

# State modifiers for special conditions
castling_king = king.enhance          # => castling-eligible king
castling_king.to_s                    # => "+K"

vulnerable_pawn = Sashite::Pin.parse("P").diminish  # => en passant vulnerable
vulnerable_pawn.to_s                  # => "-P"

# All piece types
pieces = %w[K Q R B N P].map { |type| Sashite::Pin.parse(type) }
black_pieces = pieces.map(&:flip)     # Convert to black pieces
```

### Japanese Chess (Shōgi)
```ruby
# Basic pieces
rook = Sashite::Pin.parse("R")        # => white rook
bishop = Sashite::Pin.parse("B")      # => white bishop

# Promoted pieces (enhanced state)
dragon_king = rook.enhance            # => promoted rook (Dragon King)
dragon_king.to_s                      # => "+R"

dragon_horse = bishop.enhance         # => promoted bishop (Dragon Horse)
dragon_horse.to_s                     # => "+B"

# Promoted pawn
pawn = Sashite::Pin.parse("P")
tokin = pawn.enhance                  # => promoted pawn (Tokin)
tokin.to_s                            # => "+P"

# All promotable pieces can use the same pattern
promotable = %w[R B S N L P].map { |type| Sashite::Pin.parse(type) }
promoted = promotable.map(&:enhance)
```

### Thai Chess (Makruk)
```ruby
# Basic pieces
met = Sashite::Pin.parse("M")         # => white Met (queen)
pawn = Sashite::Pin.parse("P")        # => white Bia (pawn)

# Promoted pawns
bia_kaew = pawn.enhance               # => promoted pawn (Bia Kaew)
bia_kaew.to_s                         # => "+P"

# Makruk pieces
makruk_pieces = %w[K M R B N P].map { |type| Sashite::Pin.parse(type) }
```

### Chinese Chess (Xiangqi)
```ruby
# Pieces with positional states
general = Sashite::Pin.parse("G")     # => red general
flying_general = general.enhance      # => flying general (special state)
flying_general.to_s                   # => "+G"

# Soldiers that crossed the river
soldier = Sashite::Pin.parse("P")
crossed_soldier = soldier.enhance     # => soldier with enhanced movement
crossed_soldier.to_s                  # => "+P"
```

## API Reference

### Main Module Methods

- `Sashite::Pin.valid?(pin_string)` - Check if string is valid PIN notation
- `Sashite::Pin.parse(pin_string)` - Parse PIN string into Piece object

### Piece Class

#### Creation and Parsing
- `Sashite::Pin::Piece.new(letter, enhanced: false, diminished: false)` - Create piece instance
- `Sashite::Pin::Piece.parse(pin_string)` - Parse PIN string (same as module method)

#### String Representation
- `#to_s` - Convert to PIN string representation
- `#letter` - Get the letter (type + side)
- `#type` - Get piece type (uppercase letter)
- `#side` - Get player side (`:first` or `:second`)
- `#state` - Get state (`:normal`, `:enhanced`, or `:diminished`)

#### State Queries
- `#normal?` - Check if normal state (no modifiers)
- `#enhanced?` - Check if enhanced state
- `#diminished?` - Check if diminished state

#### Player Queries
- `#first_player?` - Check if first player piece
- `#second_player?` - Check if second player piece

#### State Transformations (immutable - return new instances)
- `#enhance` - Create enhanced version
- `#unenhance` - Remove enhanced state
- `#diminish` - Create diminished version
- `#undiminish` - Remove diminished state
- `#normalize` - Remove all state modifiers
- `#flip` - Switch player (change case)

#### Comparison Methods
- `#same_type?(other)` - Check if same piece type
- `#same_player?(other)` - Check if same player
- `#==(other)` - Full equality comparison

### Constants
- `Sashite::Pin::PIN_REGEX` - Regular expression for PIN validation

## Advanced Usage

### Immutable Transformations
```ruby
# All transformations return new instances
original = Sashite::Pin.parse("K")
enhanced = original.enhance
diminished = original.diminish

# Original piece is never modified
puts original.to_s    # => "K"
puts enhanced.to_s    # => "+K"
puts diminished.to_s  # => "-K"

# Transformations can be chained
result = original.flip.enhance.flip.diminish
puts result.to_s      # => "-K"
```

### Game State Management
```ruby
class GameBoard
  def initialize
    @pieces = {}
  end

  def place(square, pin_string)
    @pieces[square] = Sashite::Pin.parse(pin_string)
  end

  def promote(square)
    piece = @pieces[square]
    return nil unless piece&.normal?  # Can only promote normal pieces

    @pieces[square] = piece.enhance
  end

  def capture(from_square, to_square)
    captured = @pieces[to_square]
    @pieces[to_square] = @pieces.delete(from_square)
    captured
  end

  def pieces_by_player(first_player: true)
    @pieces.select { |_, piece| piece.first_player? == first_player }
  end

  def promoted_pieces
    @pieces.select { |_, piece| piece.enhanced? }
  end
end

# Usage
board = GameBoard.new
board.place("e1", "K")
board.place("e8", "k")
board.place("a7", "P")

# Promote pawn
board.promote("a7")
promoted = board.promoted_pieces
puts promoted.values.first.to_s  # => "+P"
```

### Piece Analysis
```ruby
def analyze_pieces(pin_strings)
  pieces = pin_strings.map { |pin| Sashite::Pin.parse(pin) }

  {
    total: pieces.size,
    by_player: pieces.group_by(&:side),
    by_type: pieces.group_by(&:type),
    by_state: pieces.group_by(&:state),
    promoted: pieces.count(&:enhanced?),
    weakened: pieces.count(&:diminished?)
  }
end

pins = %w[K Q +R B N P k q r +b n -p]
analysis = analyze_pieces(pins)
puts analysis[:by_player][:first].size  # => 6
puts analysis[:promoted]                # => 2
```

### Move Validation Example
```ruby
def can_promote?(piece, target_rank)
  return false unless piece.normal?  # Already promoted pieces can't promote again

  case piece.type
  when "P"  # Pawn
    (piece.first_player? && target_rank == 8) ||
    (piece.second_player? && target_rank == 1)
  when "R", "B", "S", "N", "L"  # Shōgi pieces that can promote
    true
  else
    false
  end
end

pawn = Sashite::Pin.parse("P")
puts can_promote?(pawn, 8)          # => true

promoted_pawn = pawn.enhance
puts can_promote?(promoted_pawn, 8) # => false (already promoted)
```

## Protocol Mapping

Following the [Game Protocol](https://sashite.dev/game-protocol/):

| Protocol Attribute | PIN Encoding | Examples |
|-------------------|--------------|----------|
| **Type** | ASCII letter choice | `K`/`k` = King, `P`/`p` = Pawn |
| **Side** | Letter case | `K` = First player, `k` = Second player |
| **State** | Optional prefix | `+K` = Enhanced, `-K` = Diminished, `K` = Normal |

**Note**: PIN does not represent the **Style** attribute from the Game Protocol. For style-aware piece notation, see [Piece Name Notation (PNN)](https://sashite.dev/specs/pnn/).

## Properties

* **ASCII Compatible**: Maximum portability across systems
* **Rule-Agnostic**: Independent of specific game mechanics
* **Compact Format**: 1-2 characters per piece
* **Visual Distinction**: Clear player differentiation through case
* **Protocol Compliant**: Direct implementation of Sashité piece attributes
* **Immutable**: All piece instances are frozen and transformations return new objects
* **Functional**: Pure functions with no side effects

## System Constraints

- **Maximum 26 piece types** per game system (one per ASCII letter)
- **Exactly 2 players** (uppercase/lowercase distinction)
- **3 state levels** (enhanced, normal, diminished)

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
