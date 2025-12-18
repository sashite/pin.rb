# Sashite::Pin

[![Version](https://img.shields.io/github/v/tag/sashite/pin.rb?label=Version&logo=github)](https://github.com/sashite/pin.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/sashite/pin.rb/main)
![Ruby](https://github.com/sashite/pin.rb/actions/workflows/main.yml/badge.svg?branch=main)
[![License](https://img.shields.io/github/license/sashite/pin.rb?label=License&logo=github)](https://github.com/sashite/pin.rb/raw/main/LICENSE.md)

> **PIN** (Piece Identifier Notation) implementation for Ruby.

## What is PIN?

PIN (Piece Identifier Notation) provides an ASCII-based format for representing pieces in abstract strategy board games. PIN translates piece attributes from the [Game Protocol](https://sashite.dev/game-protocol/) into a compact, portable notation system.

This gem implements the [PIN Specification v1.0.0](https://sashite.dev/specs/pin/1.0.0/).

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

# Parse PIN strings
pin = Sashite::Pin.parse("K")
pin.type      # => :K
pin.side      # => :first
pin.state     # => :normal
pin.terminal  # => false

pin.to_s  # => "K"

# Parse with different attributes
king = Sashite::Pin.parse("K^")      # Terminal king
rook = Sashite::Pin.parse("+R")      # Enhanced rook
pawn = Sashite::Pin.parse("-p")      # Diminished second player pawn

# Create identifiers directly
pin = Sashite::Pin.new(:K, :first)
pin = Sashite::Pin.new(:R, :second, :enhanced)
pin = Sashite::Pin.new(:K, :first, :normal, terminal: true)

# Validation
Sashite::Pin.valid?("K")        # => true
Sashite::Pin.valid?("+R")       # => true
Sashite::Pin.valid?("K^")       # => true
Sashite::Pin.valid?("invalid")  # => false

# State transformations (return new instances)
enhanced = pin.enhance
enhanced.to_s  # => "+K"

diminished = pin.diminish
diminished.to_s  # => "-K"

normalized = enhanced.normalize
normalized.to_s  # => "K"

# Side transformation
flipped = pin.flip
flipped.to_s  # => "k"

# Terminal transformations
terminal = pin.mark_terminal
terminal.to_s  # => "K^"

non_terminal = terminal.unmark_terminal
non_terminal.to_s  # => "K"

# Type transformation
queen = pin.with_type(:Q)
queen.to_s  # => "Q"

# State queries
pin.normal?     # => true
enhanced.enhanced?    # => true
diminished.diminished?  # => true

# Side queries
pin.first_player?   # => true
flipped.second_player?  # => true

# Terminal queries
terminal.terminal?  # => true

# Comparison
king1 = Sashite::Pin.parse("K")
king2 = Sashite::Pin.parse("k")

king1.same_type?(king2)  # => true
king1.same_side?(king2)  # => false
```

## Format Specification

### Structure

```
[<state-modifier>]<letter>[<terminal-marker>]
```

### Components

| Component | Values | Description |
|-----------|--------|-------------|
| Letter | `A-Z`, `a-z` | Piece type and side |
| State Modifier | `+`, `-`, (none) | Enhanced, diminished, or normal |
| Terminal Marker | `^`, (none) | Terminal piece or not |

### Side Convention

- **Uppercase** (`A-Z`): First player
- **Lowercase** (`a-z`): Second player

### Examples

| PIN | Side | State | Terminal | Description |
|-----|------|-------|----------|-------------|
| `K` | First | Normal | No | Standard king |
| `K^` | First | Normal | Yes | Terminal king |
| `+R` | First | Enhanced | No | Promoted rook |
| `-p` | Second | Diminished | No | Weakened pawn |
| `+K^` | First | Enhanced | Yes | Enhanced terminal king |

## API Reference

### Parsing and Validation

```ruby
Sashite::Pin.parse(pin_string)  # => Sashite::Pin | raises ArgumentError
Sashite::Pin.valid?(pin_string) # => boolean
```

### Creation

```ruby
Sashite::Pin.new(type, side)
Sashite::Pin.new(type, side, state)
Sashite::Pin.new(type, side, state, terminal: boolean)
```

### Conversion

```ruby
pin.to_s    # => String
pin.letter  # => String (case determined by side)
pin.prefix  # => String ("+" | "-" | "")
pin.suffix  # => String ("^" | "")
```

### Transformations

All transformations return new `Sashite::Pin` instances:

```ruby
# State
pin.enhance     # => Sashite::Pin with :enhanced state
pin.diminish    # => Sashite::Pin with :diminished state
pin.normalize   # => Sashite::Pin with :normal state

# Side
pin.flip        # => Sashite::Pin with opposite side

# Terminal
pin.mark_terminal    # => Sashite::Pin with terminal: true
pin.unmark_terminal  # => Sashite::Pin with terminal: false

# Attribute changes
pin.with_type(new_type)       # => Sashite::Pin with different type
pin.with_side(new_side)       # => Sashite::Pin with different side
pin.with_state(new_state)     # => Sashite::Pin with different state
pin.with_terminal(boolean)    # => Sashite::Pin with specified terminal status
```

### Queries

```ruby
# State
pin.normal?
pin.enhanced?
pin.diminished?

# Side
pin.first_player?
pin.second_player?

# Terminal
pin.terminal?

# Comparison
pin.same_type?(other)
pin.same_side?(other)
pin.same_state?(other)
pin.same_terminal?(other)
```

## Data Structure

```ruby
Sashite::Pin
  #type     => :A..:Z           # Piece type (always uppercase symbol)
  #side     => :first | :second # Player side
  #state    => :normal | :enhanced | :diminished
  #terminal => true | false
```

## Protocol Mapping

Following the [Game Protocol](https://sashite.dev/game-protocol/):

| Protocol Attribute | PIN Encoding |
|-------------------|--------------|
| Piece Name | ASCII letter choice |
| Piece Side | Letter case |
| Piece State | Optional prefix (`+`/`-`) |
| Terminal Status | Optional suffix (`^`) |

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [PNN](https://sashite.dev/specs/pnn/) — Piece Name Notation
- [PIN Specification](https://sashite.dev/specs/pin/1.0.0/) — Official specification

## License

Available as open source under the [MIT License](https://opensource.org/licenses/MIT).

## About

Maintained by [Sashité](https://sashite.com/) — promoting chess variants and sharing the beauty of board game cultures.
