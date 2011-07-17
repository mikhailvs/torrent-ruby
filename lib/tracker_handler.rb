#!/usr/bin/env ruby

require 'net/http'
require 'digest/sha1'
require 'uri'
require 'timeout'

require_relative 'torrent_file.rb'

class TrackerHandler
  attr_reader :connected_trackers, :disconnected_trackers
  def initialize torrent, options = {:tracker_timeout => 10,
                                     :use_announce_list_on_initial_connection => true,
                                     :port => 6881}
    @torrent_file = torrent
    @options = options
    @connected_trackers = []
    @disconnected_trackers = []
    
    # Set up .torrent file information for GET requests
    info = @torrent_file.to_h['info'].bencode
    @info_hash = URI.encode Digest::SHA1.digest(info).force_encoding('binary')
    @peer_id = generate_peer_id
    
    # Set up hash of tracker for the torrent (from announce and announce-list).
    @trackers = []
    torrent_hash = @torrent_file.to_h
    announce_uri = URI.parse torrent_hash['announce']
    @trackers << {:url => announce_uri.to_s, :scheme => announce_uri.scheme,
                  :port => announce_uri.port, :path => announce_uri.path,
                  :host => announce_uri.host}
    if @options[:use_announce_list_on_initial_connection]
      torrent_hash['announce-list'].each do |list|
        list.each do |tracker|
          tracker_uri = URI.parse tracker
          @trackers << {:url => tracker_uri.to_s, :scheme => tracker_uri.scheme,
                        :port => tracker_uri.port, :path => tracker_uri.path,
                        :host => tracker_uri.host}
        end
      end
    end
    
    # Set up connections for trackers.
    establish_connections
  end
  
  def establish_connections
    for tracker in @trackers
      # TODO handle UDP trackers.
      next unless tracker[:scheme] == 'http'
      begin
        timeout(@options[:tracker_timeout]) do
          @connected_trackers << {:tracker => tracker,
            :connection => Net::HTTP.start(tracker[:host], tracker[:port])}
        end
      rescue Errno::ECONNREFUSED => error
        @disconnected_trackers << {:tracker => tracker, :error => error}
      rescue Timeout::Error => error
        @disconnected_trackers << {:tracker => tracker, :error => error}
      end
    end
  end
  
  def request params = {}
    required_params = [:uploaded, :downloaded, :left, :compact, :no_peer_id, :event, :index]
    diff = required_params - params.keys
    if diff == []
      request_string = "#{tracker[:path]}?"                 +
                       "info_hash=#{@info_hash}&"           +
                       "peer_id=#{@peer_id}&"               +
                       "port=#{@options[:port]}&"           +
                       "uploaded=#{params[:uploaded]}&"     +
                       "downloaded=#{params[:downloaded]}&" +
                       "left=#{params[:left]}&"             +
                       "compact=#{params[:compact]}&"       +
                       "no_peer_id=#{params[:no_peer_id]}&" +
                       "event=#{params[:event]}&"           +
                       "ip=#{params[:ip]}&"                 +
                       "numwant=#{params[:numwant]}&"       +
                       "key=#{params[:key]}&"               +
                       "trackerid=#{params[:trackerid]}"
    else
      raise ArgumentError, "Required values for keys: #{diff.to_s} not provided"
    end
    tracker_request = Net::HTTP::Get.new request_string
    @connected_trackers[:connection].request tracker_request
  end
  
private
  def generate_peer_id
    URI.encode Digest::SHA1.digest(Time.now.hash.to_s).force_encoding('binary')
  end
end


t = TorrentFile.open '/home/mikhail/Downloads/Source_Code_(2011)_DVDRip_XviD-MAX.6525961.TPB.torrent'

s = TrackerHandler.new t

puts s.connected_trackers.inspect
puts s.disconnected_trackers.inspect

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
