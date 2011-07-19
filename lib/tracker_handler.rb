#!/usr/bin/env ruby

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
    
    # Set up connections for trackers.
    # establish_connections
  end
  
  # Establish connections to the trackers defined in "announce-list".
  # Returns a range of the indexes it made.
  def establish_connections index
    # TODO handle UDP trackers.
    if @trackers[index][:scheme] == 'http'
      begin
        timeout(@options[:tracker_timeout]) do
          @connected_trackers << {:tracker => @trackers[index],
            :connection => Net::HTTP.start(@trackers[index][:host], @trackers[index][:port])}
        end
      # Connection refused or timed out or whatever.
      rescue => error
        @disconnected_trackers << {:tracker => @trackers[index], :error => error, :failed => 1}
      end
    end
    @connected_trackers.length - 1
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
    log = Logger.new 'tracker_handler.request.log'
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
        connection = @connected_trackers[establish_connections params[:index]]
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
                       "event=#{params[:event]}&"             +
                       "ip=#{params[:ip]}&"                   +
                       "numwant=#{params[:numwant]}&"         +
                       "key=#{params[:key]}&"                 +
                       "trackerid=#{params[:trackerid]}"
    else
      raise ArgumentError, "Required values for keys: #{diff.to_s} not provided"
    end
    # Make, and return the body of, the request.
    connection[:connection].request(Net::HTTP::Get.new request_string).body
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
  
private
  # Generate a peer_id for the GET request. It can be arbitrary but has to be 20 bytes
  # and url-encode.
  def generate_peer_id
    URI.encode Digest::SHA1.digest(Time.now.hash.to_s).force_encoding('binary')
  end
end
