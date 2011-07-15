#!/usr/bin/env ruby

require_relative 'bencode.rb'

# Class for easily handling .torrent files.

class TorrentFile
  # Create a TorrentFile object with/without the dictionary.
  def initialize contents = {}
    @contents = contents
    @bencoded_contents = @contents.bencode
  end
  
  # Change contents of TorrentFile.
  def create contents = {}
    @contents = contents
  end
  
  # Get the Hash representation of the TorrentFile's dictionary.
  def to_h
    @contents
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
