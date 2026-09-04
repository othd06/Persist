
# Persist

Persist is a library focussing on functional programming in Nim.

Nim is already very functional adjacent with features such as:
  - An effect system
  - The `func` keyword
  - Closures
  - First class functions
  - `case` based pattern matching
  - ADT case objects
  - Uniform Function Call Syntax (`value.some_function().some_other_function().a_third_function()`)

So this library focusses on the pain points to make Nim truly multi-paradigm.

In particular, the library contains persistent data structure implementations for Maps/Tables with the `HMTs` module, Sets with the `PSets` module, and Lists/Vectors/Seqs with the `TSeqs` module. Additionally, the `TCOs` and `TCOsFast` modules provide two implementations of [Tail Call Optimisation](https://en.wikipedia.org/wiki/Tail_call#) and, for those that want to do pure functional programming, including composing side-effects in a purely functional style, there are the `IO` and `IOFast` modules implementing the IO monad.

Note: Where there are distinct Fast and non-Fast versions of modules, it is advised to use the non-Fast versions for safety as the Fast versions achieve that speed by doing less safety checking (basically, read the implementations, if you understand what's going on, pick for your use case, otherwise tend away from Fast and/or test thoroughly)

## Documentation
  - [HMTs](https://othd06.github.io/Persist/HMTs)
  - [IO](https://othd06.github.io/Persist/IO)
  - [IOFast](https://othd06.github.io/Persist/IOFast)
  - [PSets](https://othd06.github.io/Persist/PSets)
  - [TCOs](https://othd06.github.io/Persist/TCOs)
  - [TCOsFast](https://othd06.github.io/Persist/TCOsFast)
  - [TSeqs](https://othd06.github.io/Persist/TSeqs)

