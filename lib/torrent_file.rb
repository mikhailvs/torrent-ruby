#!/usr/bin/env ruby

require_relative 'bencode.rb'

class TorrentFile
  def initialize contents = {}
    @contents = contents
    @bencoded_contents = @contents.bencode
  end
  
  def create contents = {}
    @contents = contents
  end
  
  def to_h
    @contents
  end
  
  def self.open f
    f = File.open f, 'rb' unless f.class == File
    @bencoded_contents = f.read.strip
    @contents = @bencoded_contents.bdecode
    TorrentFile.new @contents
  end
  
  def save f
    File.open(f, 'wb') do |file|
      file.write @bencoded_contents
    end
    @contents
  end
end
