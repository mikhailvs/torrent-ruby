class Peer
	attr_reader :ip, :port

	def initialize ip, port
		@ip = ip
		@port = port
	end
end