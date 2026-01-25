# pin.rb

[![Version](https://img.shields.io/github/v/tag/sashite/pin.rb?label=Version&logo=github)](https://github.com/sashite/pin.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/sashite/pin.rb/main)
[![CI](https://github.com/sashite/pin.rb/actions/workflows/ruby.yml/badge.svg?branch=main)](https://github.com/sashite/pin.rb/actions)
[![License](https://img.shields.io/github/license/sashite/pin.rb)](https://github.com/sashite/pin.rb/blob/main/LICENSE)

> **PIN** (Piece Identifier Notation) implementation for Ruby.

## Overview

This library implements the [PIN Specification v1.0.0](https://sashite.dev/specs/pin/1.0.0/).

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

### Parsing (String → Identifier)

Convert a PIN string into an `Identifier` object.

```ruby
require "sashite/pin"

# Standard parsing (raises on error)
pin = Sashite::Pin.parse("K")
pin.abbr       # => :K
pin.side       # => :first
pin.state      # => :normal
pin.terminal?  # => false

# With state modifier
pin = Sashite::Pin.parse("+R")
pin.state  # => :enhanced

# With terminal marker
pin = Sashite::Pin.parse("K^")
pin.terminal?  # => true

# Combined
pin = Sashite::Pin.parse("+K^")
pin.state      # => :enhanced
pin.terminal?  # => true

# Invalid input raises ArgumentError
Sashite::Pin.parse("invalid")  # => raises ArgumentError
```

### Formatting (Identifier → String)

Convert an `Identifier` back to a PIN string.

```ruby
# From Identifier object
pin = Sashite::Pin::Identifier.new(:K, :first)
pin.to_s  # => "K"

# With attributes
pin = Sashite::Pin::Identifier.new(:R, :second, :enhanced)
pin.to_s  # => "+r"

pin = Sashite::Pin::Identifier.new(:K, :first, :normal, terminal: true)
pin.to_s  # => "K^"
```

### Validation

```ruby
# Boolean check
Sashite::Pin.valid?("K")        # => true
Sashite::Pin.valid?("+R")       # => true
Sashite::Pin.valid?("K^")       # => true
Sashite::Pin.valid?("invalid")  # => false
```

### Transformations

All transformations return new immutable instances.

```ruby
pin = Sashite::Pin.parse("K")

# State transformations
pin.enhance.to_s    # => "+K"
pin.diminish.to_s   # => "-K"
pin.normalize.to_s  # => "K"

# Side transformation
pin.flip.to_s  # => "k"

# Terminal transformations
pin.terminal.to_s      # => "K^"
pin.non_terminal.to_s  # => "K"

# Attribute changes
pin.with_abbr(:Q).to_s            # => "Q"
pin.with_side(:second).to_s       # => "k"
pin.with_state(:enhanced).to_s    # => "+K"
pin.with_terminal(true).to_s      # => "K^"
```

### Queries

```ruby
pin = Sashite::Pin.parse("+K^")

# State queries
pin.normal?      # => false
pin.enhanced?    # => true
pin.diminished?  # => false

# Side queries
pin.first_player?   # => true
pin.second_player?  # => false

# Terminal query
pin.terminal?  # => true

# Comparison queries
other = Sashite::Pin.parse("k")
pin.same_abbr?(other)      # => true
pin.same_side?(other)      # => false
pin.same_state?(other)     # => false
pin.same_terminal?(other)  # => false
```

## API Reference

### Types

```ruby
# Identifier represents a parsed PIN with all attributes.
class Sashite::Pin::Identifier
  # Creates an Identifier from attributes.
  # Raises ArgumentError if attributes are invalid.
  #
  # @param abbr [Symbol] Piece name abbreviation (:A to :Z)
  # @param side [Symbol] Piece side (:first or :second)
  # @param state [Symbol] Piece state (:normal, :enhanced, or :diminished)
  # @param terminal [Boolean] Terminal status
  # @return [Identifier]
  def initialize(abbr, side, state = :normal, terminal: false)

  # Returns the piece name abbreviation (always uppercase symbol).
  #
  # @return [Symbol]
  def abbr

  # Returns the piece side.
  #
  # @return [Symbol] :first or :second
  def side

  # Returns the piece state.
  #
  # @return [Symbol] :normal, :enhanced, or :diminished
  def state

  # Returns the terminal status.
  #
  # @return [Boolean]
  def terminal?

  # Returns the PIN string representation.
  #
  # @return [String]
  def to_s
end
```

### Constants

```ruby
Sashite::Pin::Constants::VALID_ABBRS       # => [:A, :B, ..., :Z]
Sashite::Pin::Constants::VALID_SIDES       # => [:first, :second]
Sashite::Pin::Constants::VALID_STATES      # => [:normal, :enhanced, :diminished]
Sashite::Pin::Constants::MAX_STRING_LENGTH # => 3
```

### Parsing

```ruby
# Parses a PIN string into an Identifier.
# Raises ArgumentError if the string is not valid.
#
# @param string [String] PIN string
# @return [Identifier]
# @raise [ArgumentError] if invalid
def Sashite::Pin.parse(string)
```

### Validation

```ruby
# Reports whether string is a valid PIN.
#
# @param string [String] PIN string
# @return [Boolean]
def Sashite::Pin.valid?(string)
```

### Transformations

All transformations return new `Sashite::Pin::Identifier` instances:

```ruby
# State transformations
def enhance     # => Identifier with :enhanced state
def diminish    # => Identifier with :diminished state
def normalize   # => Identifier with :normal state

# Side transformation
def flip        # => Identifier with opposite side

# Terminal transformations
def terminal      # => Identifier with terminal: true
def non_terminal  # => Identifier with terminal: false

# Attribute changes
def with_abbr(new_abbr)         # => Identifier with different abbreviation
def with_side(new_side)         # => Identifier with different side
def with_state(new_state)       # => Identifier with different state
def with_terminal(new_terminal) # => Identifier with specified terminal status
```

### Queries

```ruby
# State queries
def normal?      # => Boolean
def enhanced?    # => Boolean
def diminished?  # => Boolean

# Side queries
def first_player?   # => Boolean
def second_player?  # => Boolean

# Terminal query
def terminal?  # => Boolean

# Comparison queries
def same_abbr?(other)      # => Boolean
def same_side?(other)      # => Boolean
def same_state?(other)     # => Boolean
def same_terminal?(other)  # => Boolean
```

### Errors

All parsing and validation errors raise `ArgumentError` with descriptive messages:

| Message | Cause |
|---------|-------|
| `"empty input"` | String length is 0 |
| `"input exceeds 3 characters"` | String too long |
| `"must contain exactly one letter"` | Missing or multiple letters |
| `"invalid state modifier"` | Invalid prefix character |
| `"invalid terminal marker"` | Invalid suffix character |

## Design Principles

- **Bounded values**: Explicit validation of abbreviations, sides, and states
- **Object-oriented**: `Identifier` class enables methods and encapsulation
- **Ruby idioms**: `valid?` predicate, `to_s` conversion, `ArgumentError` for invalid input
- **Immutable identifiers**: Frozen instances prevent mutation
- **Transformation methods**: Return new instances for attribute changes
- **No dependencies**: Pure Ruby standard library only

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [PIN Specification](https://sashite.dev/specs/pin/1.0.0/) — Official specification
- [PIN Examples](https://sashite.dev/specs/pin/1.0.0/examples/) — Usage examples

## License

Available as open source under the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
