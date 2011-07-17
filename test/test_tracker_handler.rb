#!/usr/bin/env ruby

require 'test/unit'

require_relative '../lib/tracker_handler.rb'
require_relative '../lib/torrent_file.rb'

class TestTrackerHandler < Test::Unit::TestCase
  @@torrent = TorrentFile.open Dir['test/extra/*.torrent'][0]
  @@tracker_handler = TrackerHandler.new @@torrent, :tracker_timeout => 1,
        :use_announce_list_on_initial_connection => false
  def test_initialize
    assert_nothing_raised(Exception) do
      tracker_handler = TrackerHandler.new @@torrent, :tracker_timeout => 1,
        :use_announce_list_on_initial_connection => false
    end
  end
  
  def test_establish_connection
    assert_nothing_raised(Exception) do
      @@tracker_handler.establish_connections
    end
  end
  
  def test_request
    assert_raise(ArgumentError) { @@tracker_handler.request }
  end
end
