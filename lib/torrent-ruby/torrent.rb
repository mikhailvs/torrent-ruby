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

# Class for easily handling .torrent files.

class Torrent
  attr_reader :trackers, :peers, :info_hash

  # Create a TorrentFile object with/without the dictionary.
  def initialize contents = {}
    @contents = contents
    @bencoded_contents = @contents.bencode unless @contents.nil?

    @info_hash = CGI::escape(Digest::SHA1.digest(@contents['info'].bencode).force_encoding('binary'))

    @peer_id = generate_peer_id

    @trackers = [Tracker.new(URI.parse(@contents['announce']), @info_hash, @peer_id)]

    (@contents['announc-list'] || []).each do |list|
      list.each { |tracker| @trackers << Tracker.new(URI.parse(tracker), @info_hash, @peer_id) }
    end
  end

  # begin downloading the torrent
  def start_download
  end
  
  # Change contents of TorrentFile.
  def create contents = {}
    @contents = contents
    @bencoded_contents = @contents.bencode unless @contents.nil?
  end
  
  # Get the Hash representation of the TorrentFile's dictionary.
  def to_h
    @contents
  end

  # Get the bencoded dictionary from the TorrentFile.
  def bencoded
    @bencoded_contents
  end
  
  # Create from a file (object or filename).
  def self.open f
    f = File.open(f, 'rb') unless f.class.method_defined?(:read)
    @bencoded_contents = f.read.strip
    @contents = @bencoded_contents.bdecode
    Torrent.new @contents
  end
  
  # Save TorrentFile to file with name 'f'.
  def save f
    File.open(f, 'wb') { |file| file.write @bencoded_contents }
    @contents
  end

private
  # Generate a peer_id for the GET request. It can be arbitrary but has to be 20 bytes
  # and url-encode.
  def generate_peer_id
    CGI::escape(Digest::SHA1.digest(Time.now.hash.to_s).force_encoding('binary'))
  end
end
