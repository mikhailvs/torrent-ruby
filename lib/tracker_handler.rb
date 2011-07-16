#!/usr/bin/env ruby

require 'net/http'
require 'digest/sha1'
require 'uri'

class TrackerHandler
  attr_accessor :host, :torrent_file
  
  def initialize info = {}
    @http = Net::HTTP.start info[:host] if info[:host]
    @torrent_file = info[:torrent_file] if info[:torrent_file]
    @trackers = [@torrent_file.to_h['announce']]
    @torrent_file.to_h['announce-list'].each do |list|
      list.each do |tracker|
        @trackers << tracker
      end
    end
    puts @trackers.inspect
  end
  
  def request
    
  end
end

require_relative 'torrent_file.rb'

t = TorrentFile.open '/home/mikhail/Downloads/Doctor Who 2005 Season 1 The Ultimate Guide [PDTV XviD ENG][TNTVillage] [h33t].torrent'

s = Tracker.new :torrent_file => t

=begin
tracker_url = URI.parse t.to_h['announce-list'][0][0]

tracker_host = tracker_url.host
tracker_port = tracker_url.port
tracker_path = tracker_url.path

info = t.to_h['info'].bencode
info_hash = URI.encode Digest::SHA1.digest(info).force_encoding('binary')

puts tracker_host, tracker_port
http = Net::HTTP.start tracker_host, tracker_port

request = Net::HTTP::Get.new "#{tracker_path}?info_hash=#{info_hash}&peer_id=#{info_hash}&port=42309&uploaded=1&downloaded=5&left=&compact=1&event=started"
r = http.request request

puts r.body
=end
