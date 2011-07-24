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

require 'net/http'
require 'digest/sha1'
require 'uri'
require 'timeout'

# Class for handling things related to trackers. It serves as a common place to perform
# actions with all the trackers defined in a .torrent metainfo file's dictionary.

class TrackerHandler
  attr_reader :connected_trackers, :disconnected_trackers, :peer_id, :trackers
  def initialize torrent, options = {}
    @torrent_file = torrent
    @options = {:tracker_timeout => 10, :use_announce_list_on_initial_connection => true,
                :port => 6881}.merge(options)
    
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
    announce_uri = URI.parse torrent_hash['announce']
    @trackers << {:url => announce_uri.to_s, :scheme => announce_uri.scheme,
                  :port => announce_uri.port, :path => announce_uri.path,
                  :host => announce_uri.host}
                  
    # Honor the parameter from @options. As far as the parameter itself goes,
    # there is no particular reason for having it, but you may not want to
    # connect to every single constructor from the constructor.
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
  end
  
  # Establish connections to the trackers defined in "announce-list".
  # Returns a range of the indexes it made.
  def establish_connection index
    # TODO handle UDP trackers.
    success = false
    if @trackers[index][:scheme] == 'http'
      begin
        timeout(@options[:tracker_timeout]) do
          @connected_trackers << {:tracker => @trackers[index],
            :connection => Net::HTTP.start(@trackers[index][:host], @trackers[index][:port])}
          success = true
        end
      # Connection refused or timed out or whatever.
      rescue => error
        @disconnected_trackers << {:tracker => @trackers[index], :error => error, :failed => 1}
      end
    end
    success
  end
  
  # Retry a connection to trackers that failed. The range is for the trackers in
  # the @disconnected trackers array and defaults to include all of them.
  def retry_failed_connections range = 0..@disconnected_trackers.length - 1
    for tracker in @disconnected_trackers[range]
      begin
        timeout(@options[:tracker_timeout]) do
          @connected_trackers << {:tracker => tracker,
            :connection => Net::HTTP.start(tracker[:host], tracker[:port])}
          @disconnected_trackers.delete tracker
        end
      rescue => error
        # Failed another time.
        tracker[:failed] += 1
      end
    end
  end
  
  # Make http request to the tracker and get results.
  def request params = {}
    # If there's nothing to connect to. Catch this exception.
    # raise Exception, "No trackers connected." if @connected_trackers.empty?  

    # All parameters defined in the specification are required except for ip, numwant,
    # key and trackerid.
    required_params = [:uploaded, :downloaded, :left, :compact, :no_peer_id, :event, :index]
    diff = required_params - params.keys
    
    if diff.empty?
      connection = nil
      for tracker in @connected_trackers
        if tracker[:tracker] == @trackers[params[:index]]
          connection = tracker[:connection]
        end
      end
      
      if connection.nil?
        connection = establish_connection(params[:index]) ?
          @connected_trackers[-1] : raise(Exception, "Could not connect to tracker")
      end
      
      request_string = "#{@trackers[params[:index]][:path]}?" +
                       "info_hash=#{@info_hash}&"             +
                       "peer_id=#{@peer_id}&"                 +
                       "port=#{@options[:port]}&"             +
                       "uploaded=#{params[:uploaded]}&"       +
                       "downloaded=#{params[:downloaded]}&"   +
                       "left=#{params[:left]}&"               +
                       "compact=#{params[:compact]}&"         +
                       "no_peer_id=#{params[:no_peer_id]}&"   +
                       "event=#{params[:event]}"

      # Optional parameters need to be added separately because otherwise some trackers
      # will freak out.
      request_string += "&ip=#{params[:ip]}" if params.keys.include? :ip
      request_string += "&numwant=#{params[:numwant]}" if params.keys.include? :numwant
      request_string += "&key=#{params[:key]}" if params.keys.include? :key
      request_string += "&key=#{params[:trackerid]}" if params.keys.include? :trackerid
    else
      raise ArgumentError, "Required values for keys: #{diff.to_s} not provided"
    end
    raise Exception, "UDP tracker not supported or some other issue" if connection.nil?
    # Make, and return the body of, the request.
    response = connection[:connection].request(Net::HTTP::Get.new request_string)
    Hash[:body => response.body, :code => response.code]
  end
  
  # Scrape tracker if the tracker supports it (determined as described in
  # http://wiki.theory.org/BitTorrentSpecification#Tracker_.27scrape.27_Convention).
  def scrape index, info_hashes = []
    info_hash_string = ''
    info_hashes.each { |hash| info_hash_string << "info_hash=#{hash}&" }
    unless @connected_trackers[index][:tracker][:path] !~ /\/announce.+/
      str = @connected_trackers[index][:tracker][:path].gsub 'announce', 'scrape'
      @connected_trackers[index][:tracker][:connection].request(
        Net::HTTP.Get.new("#{str}?#{info_hash_string}")).body
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
        peers << {:ip => bytes[0..3].join('.'), :port => bytes[4] << 8 | bytes[5]}
      # Host is little-endian
      else
        # IP is in the first 4 bytes, port is in last 2.
        peers << {:ip => bytes[0..3].reverse.join('.'), :port => bytes[5] << 8 | bytes[4]}
      end
      bytes = bytes[6..-1]
    end
    peers
  end
  
private
  # Generate a peer_id for the GET request. It can be arbitrary but has to be 20 bytes
  # and url-encode.
  def generate_peer_id
    URI.encode Digest::SHA1.digest(Time.now.hash.to_s).force_encoding('binary')
  end
end
