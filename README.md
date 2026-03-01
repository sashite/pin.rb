# pin.rb

[![Version](https://img.shields.io/github/v/tag/sashite/pin.rb?label=Version&logo=github)](https://github.com/sashite/pin.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/sashite/pin.rb/main)
[![CI](https://github.com/sashite/pin.rb/actions/workflows/ruby.yml/badge.svg?branch=main)](https://github.com/sashite/pin.rb/actions)
[![License](https://img.shields.io/github/license/sashite/pin.rb)](https://github.com/sashite/pin.rb/blob/main/LICENSE)

> **PIN** (Piece Identifier Notation) implementation for Ruby.

## Overview

This library implements the [PIN Specification v1.0.0](https://sashite.dev/specs/pin/1.0.0/).

PIN is a compact, ASCII-only token format encoding a **Piece Identity**: the tuple (**Piece Name**, **Piece Side**, **Piece State**, **Terminal Status**). Case encodes side, an optional `+`/`-` prefix encodes state, and an optional `^` suffix marks terminal pieces.

### Implementation Constraints

| Constraint | Value | Rationale |
|------------|-------|-----------|
| Token length | 1–3 characters | `[+-]?[A-Za-z]\^?` per spec |
| Character space | 312 tokens | 26 abbreviations × 2 sides × 3 states × 2 terminal |
| Instance pool | 312 objects | All identifiers are pre-instantiated and frozen |

The closed domain of 312 possible values enables a flyweight architecture with zero allocation on the hot path.

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

# Returns a cached instance — no allocation
Sashite::Pin.parse("+K^").equal?(Sashite::Pin.parse("+K^"))  # => true

# Invalid input raises ArgumentError
Sashite::Pin.parse("invalid")  # => raises ArgumentError
```

### Safe Parsing (String → Identifier | nil)

Parse without raising exceptions. Returns `nil` on invalid input.

```ruby
# Valid input returns an Identifier
Sashite::Pin.safe_parse("K")     # => #<Sashite::Pin::Identifier K>
Sashite::Pin.safe_parse("+R^")   # => #<Sashite::Pin::Identifier +R^>

# Invalid input returns nil — no exception allocated
Sashite::Pin.safe_parse("")        # => nil
Sashite::Pin.safe_parse("invalid") # => nil
Sashite::Pin.safe_parse(nil)       # => nil
```

### Fetching by Components (Symbol, Symbol, ... → Identifier)

Retrieve a cached identifier directly by components, bypassing string parsing entirely.

```ruby
# Direct lookup — no string parsing, no allocation
Sashite::Pin.fetch(:K, :first)                              # => #<Sashite::Pin::Identifier K>
Sashite::Pin.fetch(:R, :second, :enhanced)                   # => #<Sashite::Pin::Identifier +r>
Sashite::Pin.fetch(:K, :first, :normal, terminal: true)      # => #<Sashite::Pin::Identifier K^>

# Same cached instance as parse
Sashite::Pin.fetch(:K, :first).equal?(Sashite::Pin.parse("K"))  # => true

# Invalid components raise ArgumentError
Sashite::Pin.fetch(:KK, :first)     # => raises ArgumentError
Sashite::Pin.fetch(:K, :third)      # => raises ArgumentError
```

### Formatting (Identifier → String)

Convert an `Identifier` back to a PIN string.

```ruby
pin = Sashite::Pin.parse("+K^")
pin.to_s  # => "+K^"

pin = Sashite::Pin.parse("r")
pin.to_s  # => "r"
```

### Validation

```ruby
# Boolean check (never raises)
# Uses an exception-free code path internally for performance.
Sashite::Pin.valid?("K")        # => true
Sashite::Pin.valid?("+R")       # => true
Sashite::Pin.valid?("K^")       # => true
Sashite::Pin.valid?("invalid")  # => false
Sashite::Pin.valid?(nil)        # => false
```

### Transformations

All transformations return cached instances from the flyweight pool — no new object is ever allocated.

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

# Transformations return cached instances
pin.enhance.equal?(Sashite::Pin.parse("+K"))  # => true
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

### Module Methods

```ruby
# Parses a PIN string into a cached Identifier.
# Returns a pre-instantiated, frozen instance.
# Raises ArgumentError if the string is not valid.
#
# @param string [String] PIN string
# @return [Identifier]
# @raise [ArgumentError] if invalid
def Sashite::Pin.parse(string)

# Parses a PIN string without raising.
# Returns a cached Identifier on success, nil on failure.
# Never allocates exception objects or captures backtraces.
#
# @param string [String] PIN string
# @return [Identifier, nil]
def Sashite::Pin.safe_parse(string)

# Retrieves a cached Identifier by components.
# Bypasses string parsing entirely — direct hash lookup.
# Raises ArgumentError if components are invalid.
#
# @param abbr [Symbol] Piece abbreviation (:A through :Z)
# @param side [Symbol] Piece side (:first or :second)
# @param state [Symbol] Piece state (:normal, :enhanced, or :diminished)
# @param terminal [Boolean] Terminal status
# @return [Identifier]
# @raise [ArgumentError] if invalid
def Sashite::Pin.fetch(abbr, side, state = :normal, terminal: false)

# Reports whether string is a valid PIN.
# Never raises; returns false for any invalid input.
# Uses an exception-free code path internally for performance.
#
# @param string [String] PIN string
# @return [Boolean]
def Sashite::Pin.valid?(string)
```

### Identifier

```ruby
# Identifier represents a parsed PIN with all attributes.
# All instances are frozen and pre-instantiated — never construct directly,
# use Sashite::Pin.parse, .safe_parse, or .fetch instead.
class Sashite::Pin::Identifier
  # Returns the piece name abbreviation (always uppercase symbol).
  #
  # @return [Symbol] :A through :Z
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

### Transformations

All transformations return cached `Sashite::Pin::Identifier` instances from the flyweight pool:

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

### Constants

```ruby
Sashite::Pin::Constants::VALID_ABBRS       # => [:A, :B, ..., :Z]
Sashite::Pin::Constants::VALID_SIDES       # => [:first, :second]
Sashite::Pin::Constants::VALID_STATES      # => [:normal, :enhanced, :diminished]
Sashite::Pin::Constants::MAX_STRING_LENGTH # => 3
```

### Errors

All errors raise `ArgumentError` with descriptive messages:

| Message | Cause |
|---------|-------|
| `"empty input"` | String length is 0 |
| `"input exceeds 3 characters"` | String too long |
| `"must contain exactly one letter"` | Missing or multiple letters |
| `"invalid state modifier"` | Invalid prefix character |
| `"invalid terminal marker"` | Invalid suffix character |

## Design Principles

- **Spec conformance**: Strict adherence to PIN v1.0.0
- **Flyweight identifiers**: All 312 possible instances are pre-built and frozen; parsing, fetching, and transformations return cached objects with zero allocation
- **Performance-oriented internals**: Exception-free validation path; exceptions only at the public API boundary
- **Ruby idioms**: `valid?` predicate, `to_s` conversion, `ArgumentError` for invalid input
- **Immutable identifiers**: All instances are frozen after creation
- **No dependencies**: Pure Ruby standard library only

### Performance Architecture

PIN has a closed domain of exactly 312 valid tokens (26 letters × 2 cases × 3 states × 2 terminal). The implementation exploits this constraint through three complementary strategies.

**Flyweight instance pool** — All 312 `Identifier` objects are pre-instantiated and frozen at load time. `parse`, `safe_parse`, `fetch`, and all transformation methods return these cached instances via hash lookup. No `Identifier` is ever allocated after the module loads. This makes PIN essentially free to call from EPIN, FEEN, or any other hot loop — every call is a hash lookup returning a pre-existing frozen object.

**Dual-path parsing** — Parsing is split into two layers to avoid using exceptions for control flow:

- **Validation layer** — `safe_parse` performs all validation and returns the cached `Identifier` on success, or `nil` on failure, without raising, without allocating exception objects, and without capturing backtraces.
- **Public API layer** — `parse` calls `safe_parse` internally. On failure, it raises `ArgumentError` exactly once, at the boundary. `valid?` calls `safe_parse` and returns a boolean directly, never raising.

**Zero-allocation transformations** — Every transformation method (`flip`, `enhance`, `diminish`, `terminal`, `with_abbr`, etc.) computes the target component values and performs a direct lookup into the instance pool. The result is always a cached object — transformations never allocate. Chaining like `pin.enhance.flip.terminal` performs three hash lookups and zero allocations.

**Direct component lookup** — `fetch` bypasses string parsing entirely. Given components `(:K, :first, :enhanced, terminal: true)`, it performs a single hash lookup into the instance pool. This is the fastest path for callers that already have structured data (e.g., EPIN's internal construction from parsed components).

This architecture ensures that PIN never becomes a bottleneck when called from higher-level parsers like EPIN or FEEN, where it may be invoked hundreds of times per position.

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [PIN Specification](https://sashite.dev/specs/pin/1.0.0/) — Official specification
- [PIN Examples](https://sashite.dev/specs/pin/1.0.0/examples/) — Usage examples

## License

Available as open source under the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
