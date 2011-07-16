#!/usr/bin/env ruby

require 'net/http'

class Tracker
  attr_accessor :host, :torrent_file

  def initialize info = {}
    @http = Net::HTTP.start info[:host] if info[:host]
    @torrent_file = info[:torrent_file] if info[:torrent_file]
  end

  def info_hash
  end

  def peer_id
  end

  def port
  end

  def uploaded
  end

  def downloaded
  end

  def left
  end

  def compact
  end
  
  def no_peer_id
  end

  def event
  end

  def ip
  end

  def numwant
  end

  def key
  end

  def trackerid
  end
end
