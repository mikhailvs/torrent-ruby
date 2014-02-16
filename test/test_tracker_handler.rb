#!/usr/bin/env ruby

########################################################################
# Copyright 2011 Mikhail Slyusarev
#
# This file is part of torrent-ruby.
#
# torrent-ruby is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# torrent-ruby is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with torrent-ruby. If not, see <http://www.gnu.org/licenses/>.
########################################################################

require 'test/unit'

require_relative '../lib/tracker_handler.rb'
require_relative '../lib/torrent_file.rb'

class TestTrackerHandler < Test::Unit::TestCase
  @@torrent = TorrentFile.open(Dir['test/extra/*.torrent'][0])
  @@tracker_handler = TrackerHandler.new(@@torrent, tracker_timeout: 1, use_announce_list_on_initial_connection: false)
  def test_initialize
    assert_nothing_raised(Exception) do
      tracker_handler = TrackerHandler.new(@@torrent, tracker_timeout: 1, use_announce_list_on_initial_connection: false)
    end
  end
  
  def test_establish_connection
    assert_nothing_raised(Exception) do
      @@tracker_handler.establish_connection 0
    end
  end
  
  def test_request
    assert_raise(ArgumentError) { @@tracker_handler.request }
  end
end
