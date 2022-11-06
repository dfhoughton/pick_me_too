# pick_me_too

Pick things randomly from a list of things with specified frequencies.

This is what is known as an [urn model](https://en.wikipedia.org/wiki/Urn_problem).

# Synopsis

```ruby
require 'pick_me_too'

# optionally make a seeded random number sequence
rng = Random.new 1

# make a picker that uses this
picker = PickMeToo.new([["prevention", 1], ["cure", 16]], -> { rng.rand })

counter = Hash.new 0
32.times { counter[picker.pick] += 1 }
counter
# => {"cure"=>31, "prevention"=>1}

# you can also use a hash to map items to frequencies
# frequencies don't need to be whole numbers
# items don't need to be strings

rng = Random.new 1
picker = PickMeToo.new({foo: 1, bar: 2, baz: 0.5}, -> { rng.rand })
counter = Hash.new 0
32.times { counter[picker.pick] += 1 }
counter
# => {:bar=>22, :foo=>5, :baz=>5}

# you don't need to provide your own random number sequence
picker = PickMeToo({a: 1, b: 2, c: 3})
# ...
```

# What is this for?

Suppose you are simulating some phenomenon, wandering monsters in a dungeon, say, weather on particular day, or
the vowel in a random syllable in a random word in a random language. These things are representable as a list
of frequencies:
- goblin, 10; orc: 5; centipede: 15; ...
- sunny: 10; rainy: 5; cloudy: 15; ...
- a: 10; u: 5; e: 15; ...

What you need is something that will randomly pick these things for you with the frequencies you specify.

One way to do this would be to make an array, fill it with the items according to the frequencies specified,
and then pick randomly from the array:

```ruby
  monsters = %i[goblin] * 10 + %i[orc] * 5 + %i[centipede] * 15
  monster = monsters[(monsters.length * rand).floor]
```

This is inefficient or impossible if the frequencies are huge or excessively precise. Say you want pi orcs in your list and e goblins.

`PickMeToo` requires just one item of each type. It converts the frequencies to probabilities and walks a tree of numeric comparisons to
choose an item given a random number. The tree of comparisons is optimized so, for example, if one item represents 50% or more of the
frequencies it will be selected with a single comparison.


# API

## `PickMeToo`

This is the "[urn](https://en.wikipedia.org/wiki/Urn_problem)" containing the items selected.

## `PickMeToo.new(frequences, [rnd])`

"Fill" the urn.

The required `frequencies` parameter must be something that is effectively a list of pairs:
things to pick paired with their frequency. The "frequency" is just any positive number.

The optional `rnd` parameter is a `Proc` that when called returns a number, ideally in the interval
[0, 1]. This parameter allows you to provided a seeded random number generator, so the choices
occur in a predictable sequence, which is useful for testing.

This constructor method will raise a `PickMeToo::Error` if
- there are no pairs in the frequency list
- any of the frequencies is non-positive
- any of the items in the list isn't something followed by a number

## `PickMeToo#pick()`

Draw an item from the urn.

## `PickMeToo#randomize!([rnd])`

Replace the random number generator.
If the optional argument is omitted, the replacement is just

```ruby
-> { rand }
```

This is useful if you want to switch from a seeded random number generator
to something more truly random.

# Installation

`pick_me_too` is available as a gem, so one installs it as one does gems.

# License

MIT. See the LICENSE file alongside this README.

# Acknowledgements

My son Jude helped me contemplate how to balance the probability tree.
