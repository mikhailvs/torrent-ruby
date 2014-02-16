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

# Class for handling things related to trackers. It serves as a common place to perform
# actions with all the trackers defined in a .torrent metainfo file's dictionary.

class TrackerHandler
  attr_reader :connected_trackers, :disconnected_trackers, :peer_id, :trackers
  def initialize torrent, options = {}
    @torrent_file = torrent
    @options = { tracker_timeout: 10, use_announce_list_on_initial_connection: true, port: 6881 }.merge(options)
    
    # Trackers we were able to connect to successfully.
    @connected_trackers = []
    
    # Trackers that timed out or refused connection.
    @disconnected_trackers = []
    
    # Set up .torrent file information for GET requests
    info = @torrent_file.to_h['info'].bencode
    
    # This is what will be passed for the info_hash GET parameter.
    @info_hash = URI.encode Digest::SHA1.digest(info).force_encoding('binary')
    
    # This is what will be passed for the peer_id GET parameter.
    @peer_id = generate_peer_id
    
    # Set up hash of tracker info for the torrent (from announce and announce-list).
    @trackers = []
    torrent_hash = @torrent_file.to_h
    @trackers << Tracker.new(URI.parse(torrent_hash['announce']))
                  
    # Honor the parameter from @options. As far as the parameter itself goes,
    # there is no particular reason for having it, but you may not want to
    # connect to every single tracker from the constructor.
    if @options[:use_announce_list_on_initial_connection]
      (torrent_hash['announce-list'] || []).each do |list|
        list.each { |tracker| @trackers << Tracker.new(URI.parse(tracker)) }
      end
    end
  end

  # Static method for getting an array of hashes representing peers in a string from a
  # tracker using the binary model for peers.
  def self.from_binary_peers string
    bytes = string.unpack 'C*'
    peers = []
    until bytes.empty?
      # Host is big-endian.
      if [1].pack('I') == [1].pack('N')
        peers << { ip: bytes[0..3].join('.'), port: bytes[4] << 8 | bytes[5]}
      # Host is little-endian
      else
        # IP is in the first 4 bytes, port is in last 2.
        peers << { ip: bytes[0..3].reverse.join('.'), port: bytes[5] << 8 | bytes[4]}
      end
      bytes = bytes[6..-1]
    end
    peers
  end
end
