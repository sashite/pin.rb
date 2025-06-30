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
piece = Sashite::Pin.parse("K")          # => #<Pin::Piece type=:K side=:first state=:normal>
piece.to_s                               # => "K"
piece.type                               # => :K
piece.side                               # => :first
piece.state                              # => :normal

# Create pieces directly
piece = Sashite::Pin.piece(:K, :first, :normal)    # => #<Pin::Piece type=:K side=:first state=:normal>
piece = Sashite::Pin::Piece.new(:R, :second, :enhanced)  # => #<Pin::Piece type=:R side=:second state=:enhanced>

# Validate PIN strings
Sashite::Pin.valid?("K")                 # => true
Sashite::Pin.valid?("+R")                # => true
Sashite::Pin.valid?("invalid")           # => false

# State manipulation (returns new immutable instances)
enhanced = piece.enhance                 # => #<Pin::Piece type=:K side=:first state=:enhanced>
enhanced.to_s                            # => "+K"
diminished = piece.diminish              # => #<Pin::Piece type=:K side=:first state=:diminished>
diminished.to_s                          # => "-K"

# Side manipulation
flipped = piece.flip                     # => #<Pin::Piece type=:K side=:second state=:normal>
flipped.to_s                             # => "k"

# Type manipulation
queen = piece.with_type(:Q)              # => #<Pin::Piece type=:Q side=:first state=:normal>
queen.to_s                               # => "Q"

# State queries
piece.normal?                            # => true
enhanced.enhanced?                       # => true
diminished.diminished?                   # => true

# Side queries
piece.first_player?                      # => true
flipped.second_player?                   # => true

# Attribute access
piece.letter                             # => "K"
enhanced.prefix                          # => "+"
piece.prefix                             # => ""

# Type and side comparison
king1 = Sashite::Pin.parse("K")
king2 = Sashite::Pin.parse("k")
queen = Sashite::Pin.parse("Q")

king1.same_type?(king2)                  # => true (both kings)
king1.same_side?(queen)                  # => true (both first player)
king1.same_type?(queen)                  # => false (different types)

# Functional transformations can be chained
pawn = Sashite::Pin.parse("P")
enemy_promoted = pawn.flip.enhance       # => "+p" (second player promoted pawn)
```

## Format Specification

### Structure
```
[<state>]<letter>
```

### Components

- **Letter** (`A-Z`, `a-z`): Represents piece type and side
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
king = Sashite::Pin.piece(:K, :first, :normal)    # => white king
king.first_player?                                # => true
king.type                                         # => :K

# State modifiers for special conditions
castling_king = king.enhance                      # => castling-eligible king
castling_king.to_s                                # => "+K"

vulnerable_pawn = Sashite::Pin.piece(:P, :first, :diminished)  # => en passant vulnerable
vulnerable_pawn.to_s                              # => "-P"

# All piece types
piece_types = [:K, :Q, :R, :B, :N, :P]
white_pieces = piece_types.map { |type| Sashite::Pin.piece(type, :first, :normal) }
black_pieces = white_pieces.map(&:flip)           # Convert to black pieces
```

### Japanese Chess (Shōgi)
```ruby
# Basic pieces
rook = Sashite::Pin.piece(:R, :first, :normal)    # => white rook
bishop = Sashite::Pin.piece(:B, :first, :normal)  # => white bishop

# Promoted pieces (enhanced state)
dragon_king = rook.enhance                        # => promoted rook (Dragon King)
dragon_king.to_s                                  # => "+R"

dragon_horse = bishop.enhance                     # => promoted bishop (Dragon Horse)
dragon_horse.to_s                                 # => "+B"

# Promoted pawn
pawn = Sashite::Pin.piece(:P, :first, :normal)
tokin = pawn.enhance                              # => promoted pawn (Tokin)
tokin.to_s                                        # => "+P"

# All promotable pieces can use the same pattern
promotable_types = [:R, :B, :S, :N, :L, :P]
promotable = promotable_types.map { |type| Sashite::Pin.piece(type, :first, :normal) }
promoted = promotable.map(&:enhance)
```

### Thai Chess (Makruk)
```ruby
# Basic pieces
met = Sashite::Pin.piece(:M, :first, :normal)     # => white Met (queen)
pawn = Sashite::Pin.piece(:P, :first, :normal)    # => white Bia (pawn)

# Promoted pawns
bia_kaew = pawn.enhance                           # => promoted pawn (Bia Kaew)
bia_kaew.to_s                                     # => "+P"

# Makruk pieces
makruk_types = [:K, :M, :R, :B, :N, :P]
makruk_pieces = makruk_types.map { |type| Sashite::Pin.piece(type, :first, :normal) }
```

### Chinese Chess (Xiangqi)
```ruby
# Pieces with positional states
general = Sashite::Pin.piece(:G, :first, :normal) # => red general
flying_general = general.enhance                  # => flying general (special state)
flying_general.to_s                               # => "+G"

# Soldiers that crossed the river
soldier = Sashite::Pin.piece(:P, :first, :normal)
crossed_soldier = soldier.enhance                 # => soldier with enhanced movement
crossed_soldier.to_s                              # => "+P"
```

## API Reference

### Main Module Methods

- `Sashite::Pin.valid?(pin_string)` - Check if string is valid PIN notation
- `Sashite::Pin.parse(pin_string)` - Parse PIN string into Piece object
- `Sashite::Pin.piece(type, side, state = :normal)` - Create piece instance directly

### Piece Class

#### Creation and Parsing
- `Sashite::Pin::Piece.new(type, side, state = :normal)` - Create piece instance
- `Sashite::Pin::Piece.parse(pin_string)` - Parse PIN string (same as module method)

#### Attribute Access
- `#type` - Get piece type (symbol :A to :Z)
- `#side` - Get player side (:first or :second)
- `#state` - Get state (:normal, :enhanced, or :diminished)
- `#letter` - Get letter representation (string)
- `#prefix` - Get state prefix (string: "+", "-", or "")
- `#to_s` - Convert to PIN string representation

#### State Queries
- `#normal?` - Check if normal state (no modifiers)
- `#enhanced?` - Check if enhanced state
- `#diminished?` - Check if diminished state

#### Side Queries
- `#first_player?` - Check if first player piece
- `#second_player?` - Check if second player piece

#### State Transformations (immutable - return new instances)
- `#enhance` - Create enhanced version
- `#unenhance` - Remove enhanced state
- `#diminish` - Create diminished version
- `#undiminish` - Remove diminished state
- `#normalize` - Remove all state modifiers
- `#flip` - Switch player (change side)

#### Attribute Transformations (immutable - return new instances)
- `#with_type(new_type)` - Create piece with different type
- `#with_side(new_side)` - Create piece with different side
- `#with_state(new_state)` - Create piece with different state

#### Comparison Methods
- `#same_type?(other)` - Check if same piece type
- `#same_side?(other)` - Check if same side
- `#same_state?(other)` - Check if same state
- `#==(other)` - Full equality comparison

### Constants
- `Sashite::Pin::PIN_REGEX` - Regular expression for PIN validation

## Advanced Usage

### Immutable Transformations
```ruby
# All transformations return new instances
original = Sashite::Pin.piece(:K, :first, :normal)
enhanced = original.enhance
diminished = original.diminish

# Original piece is never modified
puts original.to_s    # => "K"
puts enhanced.to_s    # => "+K"
puts diminished.to_s  # => "-K"

# Transformations can be chained
result = original.flip.enhance.with_type(:Q)
puts result.to_s      # => "+q"
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
end

# Usage
board = GameBoard.new
board.place("e1", Sashite::Pin.piece(:K, :first, :normal))
board.place("e8", Sashite::Pin.piece(:K, :second, :normal))
board.place("a7", Sashite::Pin.piece(:P, :first, :normal))

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
    weakened: pieces.count(&:diminished?)
  }
end

pins = %w[K Q +R B N P k q r +b n -p]
analysis = analyze_pieces(pins)
puts analysis[:by_side][:first].size  # => 6
puts analysis[:promoted]              # => 2
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

pawn = Sashite::Pin.piece(:P, :first, :normal)
puts can_promote?(pawn, 8)          # => true

promoted_pawn = pawn.enhance
puts can_promote?(promoted_pawn, 8) # => false (already promoted)
```

## Protocol Mapping

Following the [Game Protocol](https://sashite.dev/game-protocol/):

| Protocol Attribute | PIN Encoding | Examples |
|-------------------|--------------|----------|
| **Type** | Symbol choice | `:K`/`:k` = King, `:P`/`:p` = Pawn |
| **Side** | Symbol value | `:first` = First player, `:second` = Second player |
| **State** | Symbol value | `:enhanced` = Enhanced, `:diminished` = Diminished, `:normal` = Normal |

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
