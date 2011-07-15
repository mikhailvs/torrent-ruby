#!/usr/bin/env ruby

require 'test/unit'
require '../lib/bencode.rb'

class TestString < Test::Unit::TestCase
  def test_bencode
    assert_equal '4:spam', 'spam'.bencode
    assert_equal '5: spam', ' spam'.bencode
    assert_equal '5:spam ', 'spam '.bencode
    assert_equal '2:  ', '  '.bencode
    assert_equal '19:the quick brown fox', 'the quick brown fox'.bencode
    assert_equal '0:', ''.bencode
  end

  def test_bdecode
    assert_raise(ArgumentError) { 'hello'.bdecode }
    assert_raise(ArgumentError) { ' '.bdecode }
    assert_equal [1, 2, 3], 'li1ei2ei3ee'.bdecode
    assert_equal [{'a' => 1, 'b' => '2', 'c' => ['3']}, 'four'],
      'd1:ai1e1:b1:21:cl1:3ee4:four'.bdecode
    assert_equal [{'a' => 1, 'b' => '2', 'c' => ['3']}, 'four'],
      'ld1:ai1e1:b1:21:cl1:3ee4:foure'.bdecode
  end

  def test_decode_str
    assert_equal '', '0:'.bdecode
    assert_equal ' ', '1: '.bdecode
    assert_equal ' a ', '3: a '.bdecode
    assert_equal 'the quick brown fox', '19:the quick brown fox'.bdecode
    assert_equal 'spam', '4:spam'.bdecode
    assert_equal 'budapest', '8:budapest'.bdecode
  end

  def test_decode_int
    assert_equal 1, 'i1e'.bdecode
    assert_equal 0, 'i0e'.bdecode
    assert_equal 123456789876543212345678987654321,
      'i123456789876543212345678987654321e'.bdecode
  end

  def test_decode_list
    assert_equal [1, 2, 3], 'li1ei2ei3ee'.bdecode
    assert_equal [[[[1]]], [[2]], [3], 4], 'lllli1eeeelli2eeeli3eei4ee'.bdecode
    assert_equal [], 'le'.bdecode
    assert_equal ['one', 'two', 3, 4, 'five'], 'l3:one3:twoi3ei4e4:fivee'.bdecode
    assert_equal [{'a' => 'animal', 'b' => 'banana'}, 'canadian'],
      'ld1:a6:animal1:b6:bananae8:canadiane'.bdecode
  end

  def test_decode_dict
    assert_raise(ArgumentError) { 'di2ei3ee'.bdecode }
    assert_equal ({'b' => 'budapest'}), 'd1:b8:budapeste'.bdecode
    assert_equal ({'1' => 2, '3' => 4}), 'd1:1i2e1:3i4ee'.bdecode
    assert_equal ({'one' => [1, 2, 3], 'two' => {'three' => [[[4]], [5], 6]}}),
      'd3:oneli1ei2ei3ee3:twod5:threellli4eeeli5eei6eeee'.bdecode
  end
end

class TestFixnum < Test::Unit::TestCase
  def test_bencode
    assert_equal 'i1e', 1.bencode
    assert_equal 'i1234e', 1234.bencode
  end
end

class TestBignum < Test::Unit::TestCase
  def test_bencode
    assert_equal 'i123456789876543212345678987654321e', 123456789876543212345678987654321.bencode
  end
end

class TestArray < Test::Unit::TestCase
  def test_bencode 
    assert_equal 'ld1:a6:animal1:b6:bananae8:canadiane',
      [{'a' => 'animal', 'b' => 'banana'}, 'canadian'].bencode
    assert_equal 'l1:a1:b1:c1:1i2ei3ee', ['a', 'b', 'c', '1', 2, 3].bencode
  end
end

class TestHash < Test::Unit::TestCase
  def test_bencode
    assert_equal 'd1:a1:be', ({'a' => 'b'}).bencode
    assert_equal 'd1:ad1:ad1:a1:beee', ({'a' => {'a' => {'a' => 'b'}}}).bencode
  end
end
