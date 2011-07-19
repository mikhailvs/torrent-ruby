#!/usr/bin/env ruby

require 'socket'

require_relative 'tracker_handler'
require_relative 'torrent_file'

class Peer
  attr_reader :am_choking, :am_interested, :peer_choking,
              :peer_interested, :connected
  
  def initialize params = {:connect => true}
    @host = params[:host] if params[:host]
    @port = params[:port] if params[:port]
    @peer_id = params[:peer_id] if params[:peer_id]
    @socket = TCPSocker.open @host, @port
  end
  
  def connect
    
  end
end

file = TorrentFile.open '/home/mikhail/Downloads/Doctor_Who_(2005)_-_Complete_Season_5_(Xvid_MP3).5649103.TPB.torrent'

tracker_handler = TrackerHandler.new file, :tracker_timeout => 10

response = tracker_handler.request :uploaded => 0, :downloaded => 0, :left => 5, :compact => 0,
                                   :no_peer_id => 0, :event => 'started', :index => 3
peers = response[:body].bdecode['peers']
puts response[:code]

count = 0
puts peers.unpack('C*').length
