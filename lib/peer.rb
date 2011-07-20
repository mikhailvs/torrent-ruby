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

file = TorrentFile.open '../test/extra/ubuntu-10.04-netbook-i386.iso.torrent'

length = file.to_h['info']['length']

tracker_handler = TrackerHandler.new file, :tracker_timeout => 10

response = tracker_handler.request :uploaded => 1, :downloaded => 1, :left => length, :compact => 0,
                                   :no_peer_id => 1, :event => 'started', :index => 0

peers = response[:body].bdecode['peers']
puts response[:code]

count = 0
puts peers.unpack('C*').inspect
