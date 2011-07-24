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

require_relative 'bencode.rb'

# Class for easily handling .torrent files.

class TorrentFile
  # Create a TorrentFile object with/without the dictionary.
  def initialize contents = {}
    @contents = contents
    @bencoded_contents = @contents.bencode unless @contents.nil?
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
    f = File.open f, 'rb' unless f.class == File
    @bencoded_contents = f.read.strip
    @contents = @bencoded_contents.bdecode
    TorrentFile.new @contents
  end
  
  # Save TorrentFile to file with name 'f'.
  def save f
    File.open(f, 'wb') do |file|
      file.write @bencoded_contents
    end
    @contents
  end
end
