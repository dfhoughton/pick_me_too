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
  VERSION = '0.0.0'

  class Error < StandardError; end

  ##
  # "Fill" the urn.
  #
  # The required frequencies parameter must be something that is effectivly a list of pairs:
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
      frequencies = frequencies.map(&:last)
      balanced_binary_tree = bifurcate(frequencies.dup)
      probability_tree = probabilities(frequencies, balanced_binary_tree)
      # compile everything into a nested ternary expression
      @picker = eval "->(p) { #{ternerize(probability_tree)} }"
    end
  end

  ##
  # Pick an item from the urn.
  def pick
    @objects[@picker.call(@rnd.call)]
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
    good.map { |o, n| [o, n / total] }
  end

  # reduce the probability tree to nested ternary expressions
  def ternerize(ptree)
    p, left, right = ptree.values_at :p, :left, :right
    left = left.is_a?(Numeric) ? left : ternerize(left)
    right = right.is_a?(Numeric) ? right : ternerize(right)
    "(p > #{p} ? #{right} : #{left})"
  end

  def probabilities(frequencies, tree)
    tree = sum_probabilities(tree, 0)
    replace_frequencies_with_indices(tree, frequencies.each_with_index.to_a)
    tree
  end

  def replace_frequencies_with_indices(tree, frequencies)
    left, right = tree.values_at :left, :right
    if left.is_a?(Numeric)
      i = frequencies.index { |v,| v == left }
      *, i = frequencies.slice!(i)
      tree[:left] = i
    else
      replace_frequencies_with_indices(left, frequencies)
    end
    if right.is_a?(Numeric)
      i = frequencies.index { |v,| v == right }
      *, i = frequencies.slice!(i)
      tree[:right] = i
    else
      replace_frequencies_with_indices(right, frequencies)
    end
  end

  # convert the frequency numbers to probabilities
  def sum_probabilities(tree, base)
    left, right = tree
    p = left.flatten.sum + base
    left = left.length == 1 ? left.first : sum_probabilities(left, base)
    right = right.length == 1 ? right.first : sum_probabilities(right, p)
    { p: p, left: left, right: right }
  end

  # distribute the frequencies so their as balanced as possible
  # the better to reduce expected length of the binary search
  def bifurcate(nums)
    return nums if nums.length < 2

    max = total = 0
    max_index = -1
    # make one loop find all these things
    nums.each_with_index do |n, i|
      total += n
      if n > max
        max = n
        max_index = i
      end
    end
    half = total / 2.0
    right = [nums.slice!(max_index)]
    if max >= half
      [bifurcate(nums), right]
    else
      gap = half - max
      while rv = fit_gap(gap, nums)
        removed, remaining_gap = rv
        right << removed
        break unless gap = remaining_gap
      end
      [bifurcate(nums), bifurcate(right)]
    end
  end

  # look for the frequency best suited to balance the two branches
  def fit_gap(gap, nums)
    best_index = 0
    best_fit = (gap - nums[0]).abs
    nums.each_with_index.drop(1).each do |n, i|
      fit = (gap - n).abs
      if fit < best_fit
        best_index = i
        best_fit = fit
      end
    end
    if nums[best_index] < gap * 2
      n = nums.slice!(best_index)
      [n, n < gap ? gap - n : nil]
    end
  end
end
