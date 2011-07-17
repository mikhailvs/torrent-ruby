#!/usr/bin/env ruby

require 'net/http'
require 'digest/sha1'
require 'uri'
require 'timeout'

# Class for handling things related to trackers. It serves as a common place to perform
# actions with all the trackers defined in a .torrent metainfo file's dictionary.

class TrackerHandler
  attr_reader :connected_trackers, :disconnected_trackers
  def initialize torrent, options = {:tracker_timeout => 10, # Default is 10, maybe too big?
                                     :use_announce_list_on_initial_connection => true,
                                     :port => 6881}
    @torrent_file = torrent
    @options = options
    
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
    # there is no particular reason for having it, but this class will connect
    # to every tracker it can find otherwise. However, if you set this to false,
    # the constructor will only connect to the tracker that is the value for the
    # "announce" key in the metainfo file dictionary, and you can still connect to
    # the other trackers with the establish_connections method.
    # Note: The connection to the tracker at "announce" may fail, so at some point
    # establish_connection ought to be called.
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
  
  # Establish connections to the trackers defined in "announce-list".
  def establish_connections
    for tracker in @trackers
      # TODO handle UDP trackers.
      next unless tracker[:scheme] == 'http'
      begin
        timeout(@options[:tracker_timeout]) do
          @connected_trackers << {:tracker => tracker,
            :connection => Net::HTTP.start(tracker[:host], tracker[:port])}
        end
      # Connection refused or timed out or whatever.
      rescue => error
        @disconnected_trackers << {:tracker => tracker, :error => error}
      end
    end
  end
  
  # Make http request to the tracker and get results.
  def request params = {}
    # All parameters defined in the specification are required except for ip, numwant,
    # key and trackerid.
    required_params = [:uploaded, :downloaded, :left, :compact, :no_peer_id, :event, :index]
    diff = required_params - params.keys
    if diff.empty?
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
    # Make, and return the body of, the request.
    @connected_trackers[:connection].request(Net::HTTP::Get.new(request_string)).body
  end
  
private
  # Generate a peer_id for the GET request. It can be arbitrary but has to be 20 bytes
  # and url-encode.
  def generate_peer_id
    URI.encode Digest::SHA1.digest(Time.now.hash.to_s).force_encoding('binary')
  end
end
