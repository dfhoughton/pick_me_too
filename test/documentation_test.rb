# frozen_string_literal: true

require 'minitest/autorun'

require 'pick_me_too'
require 'byebug'

# :stopdoc:

class BasicTest < Minitest::Test
  def test_synopsis
    rng = Random.new 1
    picker = PickMeToo.new([['prevention', 1], ['cure', 16]], -> { rng.rand })
    counter = Hash.new 0
    32.times { counter[picker.pick] += 1 }
    assert_equal({ 'cure' => 31, 'prevention' => 1 }, counter)
  end

  def test_synopsis_hash
    rng = Random.new 1
    picker = PickMeToo.new({ foo: 1, bar: 2, baz: 0.5 }, -> { rng.rand })
    counter = Hash.new 0
    32.times { counter[picker.pick] += 1 }
    assert_equal({ bar: 22, foo: 5, baz: 5 }, counter)
  end
end
