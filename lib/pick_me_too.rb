# frozen_string_literal: true

##
# An "urn" from which you can pick things with specified frequencies.
#
#   require 'pick_me_too'
#
#   wandering_monsters = PickMeToo.new({goblin: 10, bugbear: 2, orc: 5, spider: 3, troll: 1})
#   10.times.map { wandering_monsters.pick }
#   # => [:goblin, :orc, :bugbear, :orc, :goblin, :bugbear, :goblin, :goblin, :orc, :goblin]
#
#   irrational = PickMeToo.new({e: Math::E, pi: Math::PI})
#   to.times.map { irrational.pick }
#   # => [:e, :e, :e, :pi, :e, :e, :e, :pi, :pi, :e]
#
# Items once picked are "placed back in the urn", so if you pick a cat this doesn't reduce the
# probability the next thing you pick is also a cat, and the urn will never be picked empty. (And of course
# this is all a metaphor.)
class PickMeToo
  VERSION = '1.1.1'

  class Error < StandardError; end

  ##
  # "Fill" the urn.
  #
  # The required frequencies parameter must be something that is effectively a list of pairs:
  # things to pick paired with their frequency. The "frequency" is just any positive number.
  #
  # The optional rnd parameter is a Proc that when called returns a number, ideally in the interval
  # [0, 1]. This parameter allows you to provided a seeded random number generator, so the choices
  # occur in a predictable sequence, which is useful for testing.
  #
  # This constructor method will raise a `PickMeToo::Error` if
  # - there are no pairs in the frequency list
  # - any of the frequencies is non-positive
  # - any of the items in the list isn't something followed by a number
  def initialize(frequencies, rnd = -> { rand })
    @rnd = rnd
    frequencies = prepare(Array(frequencies))
    @objects = frequencies.map(&:first)
    if @objects.length == 1
      @picker = ->(_p) { 0 }
    else
      root = balanced_binary_tree(frequencies)
      # compile everything into a nested ternary expression
      @picker = eval "->(p) { #{ternarize(root, 0)} }"
    end
  end

  ##
  # Pick an item from the urn.
  def pick
    @objects[@picker.call(@rnd.call)]
  end

  ##
  # Replace the random number generator.
  #
  # If the optional argument is omitted, the replacement is just
  #
  #   -> { rand }
  #
  # This is useful if you want to switch from a seeded random number generator
  # to something more truly random.
  def randomize!(rnd = -> { rand })
    @rnd = rnd
  end

  private

  # sanity check and normalization of frequencies
  def prepare(frequencies)
    raise Error, 'no frequencies given' unless frequencies.any?
    unless frequencies.all? { |f| f.is_a?(Array) && f.length == 2 && f[1].is_a?(Numeric) }
      raise Error, 'all frequencies must be two-member arrays the second member of which is Numeric'
    end

    good, bad = frequencies.partition { |*, n| n.positive? }
    raise Error, "the following have non-positive frequencies: #{bad.inspect}" if bad.any?

    total = good.map(&:last).sum.to_f
    # sort by size of probability interval -- optimization step
    good.sort_by(&:last).reverse.map { |o, n| [o, n / total] }
  end

  # treat the frequencies as a heap
  # returns the root of this binary tree
  def balanced_binary_tree(frequencies)
    frequencies = frequencies.each_with_index.map { |(*, i), idx| { interval: i, index: idx } }
    frequencies.each do |obj|
      left_idx = obj[:index] * 2 + 1
      next unless (left = frequencies[left_idx])

      obj[:left] = left
      right_idx = left_idx + 1
      if (right = frequencies[right_idx])
        obj[:right] = right
      end
    end
    frequencies[0]
  end

  # what is the sum of all intervals under this node?
  def sum(obj)
    return 0 unless obj

    obj[:sum] ||= begin
      left = sum(obj[:left])
      right = sum(obj[:right])
      left + right + obj[:interval]
    end
  end

  # reduce the probability tree to nested ternary expressions
  def ternarize(node, acc)
    left = sum(node[:left])
    return node[:index] if left == 0 # this is a leaf

    right = if (r = node[:right])
              increment = acc + left + node[:interval]
              "(p < #{increment} ? #{node[:index]} : #{ternarize(r, increment)})"
            else
              node[:index]
    end
    "(p < #{left + acc} ? #{ternarize(node[:left], acc)} : #{right})"
  end
end
