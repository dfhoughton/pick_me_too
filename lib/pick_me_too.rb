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
#   10.times.map { irrational.pick }
#   # => [:e, :e, :e, :pi, :e, :e, :e, :pi, :pi, :e]
#
# Items once picked are "placed back in the urn", so if you pick a cat this doesn't reduce the
# probability the next thing you pick is also a cat, and the urn will never be picked empty.
class PickMeToo
  VERSION = '1.1.2'

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
      root = optimize(frequencies)
      # compile everything into a nested ternary expression
      @picker = eval "->(p) { #{ternarize(root)} }"
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
    # sort by size of probability interval
    # in general we will want to consider wide intervals before narrow ones
    good.sort_by(&:last).reverse.map { |o, n| [o, n / total] }
  end

  # optimize the order of threshold comparisons to map a random number to an index in the array
  # of choices
  def optimize(frequencies)
    frequencies = frequencies.each_with_index.map { |(*, i), idx| { interval: i, index: idx } }
    root = build_branch(frequencies)
    add_thresholds(root, 0)
    root
  end

  def add_thresholds(node, acc)
    # acc represents the accumulated probability mass known to be before anything in the tree
    # currently under consideration
    if (l = node[:left])
      add_thresholds(l, acc)
      node[:left_threshold] = acc += l[:sum]
    end
    if (r = node[:right])
      acc = node[:right_threshold] = acc + node[:interval]
      add_thresholds(r, acc)
    end
  end

  def build_branch(frequencies)
    sum = frequencies.sum { |o| o[:interval] }
    node = frequencies.shift
    if frequencies.any?
      if node[:interval] * 3 >= sum
        # a binary search would be wasteful because the frequencies are so skewed
        node[:right] = build_branch(frequencies)
      else
        # build a binary-branching search tree
        left, right = frequencies.each_with_index.partition { |*, i| left_branch?(i + 1) }
        node[:left] = build_branch(left.map(&:first))
        node[:right] = build_branch(right.map(&:first)) if right.any?
      end
    end
    node[:sum] = sum
    node
  end

  # this implements the heap rule for matching a node to its parent
  # our binary-branching trees are heaps with wider intervals towards the root
  def left_branch?(index)
    if index == 1
      true
    elsif index < 1
      false
    else
      left_branch?((index - 1) / 2)
    end
  end

  # reduce the probability tree to nested ternary expressions
  def ternarize(node)
    l, r = node.values_at :left, :right
    if l && r
      "(p > #{node[:left_threshold]} ? (p > #{node[:right_threshold]} ? #{ternarize(r)} : #{node[:index]}) : #{ternarize(l)})"
    elsif l
      "(p > #{node[:left_threshold]} ? #{node[:index]} : #{ternarize(l)})"
    elsif r
      "(p > #{node[:right_threshold]} ? #{ternarize(r)} : #{node[:index]})"
    else
      node[:index]
    end
  end
end
