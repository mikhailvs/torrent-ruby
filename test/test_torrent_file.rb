#!/usr/bin/env ruby

require 'test/unit'
require 'fileutils'
require 'digest/sha2'
require_relative '../lib/torrent_file.rb'

class TestTorrentFile < Test::Unit::TestCase
  @@contents = {'info' => 'very important', 'announce' => 'http://t.com',
              'announce list' => [['one', 'two']],
              'creation date' => 'today', 'comment' => 'like i said',
              'created by' => 'me', 'encoding' => 'utf-8'}
  def test_initialize
    file = TorrentFile.new @@contents
    assert_equal @@contents, file.to_h
  end

  def test_create
    file = TorrentFile.new
    file.create @@contents
    assert_equal @@contents, file.to_h
  end

  def test_bencoded
    file = TorrentFile.new @@contents
    assert_equal 'd4:info14:very important8:announce12:http://t.com13:announce listll3:one3:twoee13:creation date5:today7:comment11:like i said10:created by2:me8:encoding5:utf-8e', file.bencoded
  end

  def test_to_h
    file = TorrentFile.new @@contents
    assert_equal @@contents, file.to_h
  end

  def test_open
    Dir['test/extra/*.torrent'].each do |torrent|
      file = TorrentFile.open torrent
      _file = File.open torrent, 'rb'
      hash = file.to_h
      assert_equal _file.read, hash.bencode
    end
  end

  def test_save
    created_files = []
    Dir['test/extra/*.torrent'].each do |torrent|
      file = TorrentFile.open torrent
      filename = "test_#{File.basename torrent}"
      file.save filename
      assert_equal Digest::SHA2.file(torrent), Digest::SHA2.file(filename)
      created_files << filename
    end
    created_files.each { |file| FileUtils.rm file }
  end
end
