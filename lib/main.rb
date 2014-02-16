require_relative 'torrent-ruby'

require 'socket'
require 'thread'

t = Torrent.open('archlinux.torrent')

# t.get_peers.each do |peer|
# 	puts "trying #{peer.inspect}"
# 	begin
# 		timeout(1) do
# 			sock = TCPSocket.new(peer.ip, peer.port)

# 			puts "success"
# 		end
# 	rescue Exception
# 		puts "failed"
# 	end
# end

mux = Mutex.new
threads = []

t.trackers.first.get_peers(500).each do |p|
	threads << Thread.start do
		begin
			timeout(5) do
				s = TCPSocket.new(p.ip, p.port)
				mux.synchronize { puts "#{p.inspect} connected!" }
			end
		rescue
		end
	end
end

threads.each { |t| t.join }