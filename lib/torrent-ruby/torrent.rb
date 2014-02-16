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
  attr_reader :trackers, :peers

  # Create a TorrentFile object with/without the dictionary.
  def initialize contents = {}
    @contents = contents
    @bencoded_contents = @contents.bencode unless @contents.nil?

    @info_hash = CGI::escape(Digest::SHA1.digest(@contents['info'].bencode).force_encoding('binary'))

    @peer_id = generate_peer_id
    @trackers = [Tracker.new(URI.parse(@contents['announce']))]

    (@contents['announc-list'] || []).each do |list|
      list.each { |tracker| @trackers << Tracker.new(URI.parse(tracker)) }
    end
  end

  # get the list of peers from the tracker
  def get_peers
    # NOTE: I think the bencoder is broken or something because when compact is not set, exception are thrown
    # it needs to be investigated at some point
    response = @trackers.first.request(
      info_hash: @info_hash,
      compact: 1,
      peer_id: @peer_id
    )

    # dictionary mode
    if response['peers'].is_a?(Array)
      puts response['peers']
      @peers = response['peers'].collect { |p| Peer.new(p['ip'], p['port']) }
    else # binary mode
      @peers = parse_binary_peers(response['peers'])
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

  # parse the binary list of peers into a more manageable format
  def parse_binary_peers peerslist
    bytes = peerslist.unpack('C*')
    peers = []
    endianness = [1].pack('I') == [1].pack('N') ? :big : :little

    until bytes.empty?
      if endianness == :big
        peers << Peer.new(bytes[0..3].join('.'), bytes[4] << 8 | bytes[5])
      else
        # IP is in the first 4 bytes, port is in last 2.
        peers << Peer.new(bytes[0..3].reverse.join('.'), bytes[5] << 8 | bytes[4])
      end
      bytes = bytes[6..-1]
    end
    peers
  end
end
