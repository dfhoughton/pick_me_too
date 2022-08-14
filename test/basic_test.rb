# frozen_string_literal: true

require 'minitest/autorun'

require 'pick_me_too'
require 'byebug'

# :stopdoc:

class BasicTest < Minitest::Test
  def test_basic
    rnd = Random.new 1
    picker = PickMeToo.new([['cat', 2], ['dog', 1]], -> { rnd.rand })
    counter = Hash.new(0)
    3000.times { counter[picker.pick] += 1 }
    assert_equal 2, (counter['cat'] / 1000.0).round, 'right number of cats'
    assert_equal 1, (counter['dog'] / 1000.0).round, 'right number of dogs'
  end

  def test_hash
    rnd = Random.new 1
    picker = PickMeToo.new({'cat' => 2, 'dog' => 1}, -> { rnd.rand })
    counter = Hash.new(0)
    3000.times { counter[picker.pick] += 1 }
    assert_equal 2, (counter['cat'] / 1000.0).round, 'right number of cats'
    assert_equal 1, (counter['dog'] / 1000.0).round, 'right number of dogs'
  end

  def test_bigger
    rnd = Random.new 1
    frequencies = [['cat', 1], ['dog', 2], ['horse', 3], ['camel', 4], ['lizard', 5], ['fish', 6]]
    picker = PickMeToo.new(frequencies, -> { rnd.rand })
    counter = Hash.new(0)
    (frequencies.map(&:last).sum * 1000).times { counter[picker.pick] += 1 }
    frequencies.each do |key, n|
      assert_equal n, (counter[key] / 1000.0).round, "right number of #{key}"
    end
  end

  def test_degenerate
    rnd = Random.new 1
    picker = PickMeToo.new([['cat', 2]], -> { rnd.rand })
    counter = Hash.new(0)
    3000.times { counter[picker.pick] += 1 }
    assert_equal 3.0, counter['cat'] / 1000.0, 'right number of cats'
  end

  def test_no_frequencies_error
    assert_raises(PickMeToo::Error, 'no frequencies given') do
      PickMeToo.new([])
    end
  end

  def test_any_negative_frequency
    assert_raises(PickMeToo::Error, "the following have non-positive frequencies: #{[['bar', -1]].inspect}") do
      PickMeToo.new([['foo', 1], ['bar', -1]])
    end
  end

  def test_all_tuples
    assert_raises(PickMeToo::Error,
                  'all frequencies must be two-member arrays the second member of which is Numeric') do
      PickMeToo.new([['foo', nil, 1]])
    end
  end

  def test_frequency_required
    assert_raises(PickMeToo::Error,
                  'all frequencies must be two-member arrays the second member of which is Numeric') do
      PickMeToo.new([['foo', nil]])
    end
  end
end
