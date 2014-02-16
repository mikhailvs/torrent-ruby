require 'socket'
require 'timeout'

module UTP
	class Packet
		attr_accessor :type, :version, :extension, :connection_id, :timestamp, :timestamp_difference, :wnd_size, :seq_nr, :ack_nr, :data

		PACKET_TYPES = [:data, :fin, :state, :reset, :syn]
		PACKING_FMT = 'CCS>L>L>L>S>S>'

		def initialize params = {}
			if params[:raw]
				# unpack all the header values into an array
				vals = params[:raw][0..19].unpack(PACKING_FMT)

				# type is in the first 4 bits of the first 8-bit number
				@type = PACKET_TYPES[vals[0] >> 4]

				# version is in the last 4 bits of the first 8-bit number
				@version = vals[0] & 0xf
				@extension = vals[1]
				@connection_id = vals[2]
				@timestamp = vals[3]
				@timestamp_difference = vals[4]
				@wnd_size = vals[5]
				@seq_nr = vals[6]
				@ack_nr = vals[7]

				# everything after the header is data
				@data = parm[:raw][20..-1]
			else
				# setup the default field values here
				fields = { type: :syn, version: 1, extension: 0, timestamp_difference: 0, connection_id: (rand * 65534).round, seq_nr: 1, ack_nr: 0, data: '' }

				# set the corresponding instance variables
				fields.merge(params).each { |k, v| instance_variable_set("@#{k}", v) }
			end
		end

		def bytes
			[
				PACKET_TYPES.index(@type) << 4 | @version,
				@extension,
				@connection_id,
				@timestamp || (Time.now.to_f * 1000000).to_i,
				@timestamp_difference,
				@wnd_size,
				@seq_nr,
				@ack_nr
			].pack(PACKING_FMT) + @data
		end
	end

	class NotConnectedError < RuntimeError; end
	class TimeoutError < RuntimeError; end

	class ServerSocket
		def initialize host, port
			@sock = UDPSocket.new
			@sock.bind(host, port)

			@timeout = 10
			@recv_buf_size = 65535

			@wnd_size = 0
			@state = :idle
		end

		def accept &blk
			response_pkt = Packet.new(raw: @sock.recvfrom(@recv_buf_size))
			@state = :connected

			# since this is a server socket, we want to make sure that the connection id for this 
			@connection_id = response_pkt.connection_id unless @connection_id

			@last_ack_nr = response_pkt.ack_nr

			response_pkt.data
		end
	end

	class ClientSocket
		attr_accessor :state, :timeout, :recv_buf_size, :last_seq_nr, :last_ack_nr, :connection_id, :last_timestamp

		def initialize host, port
			@sock = UDPSocket.new
			@sock.connect(host, port)

			@timeout = 10
			@recv_buf_size = 65535
			@wnd_size = 0

			syn_pkt = Packet.new(wnd_size: @wnd_size)

			# setup socket state
			@connection_id = syn_pkt.connection_id
			@last_seq_nr = syn_pkt.seq_nr

			@sock.send(syn_pkt.bytes, 0)

			@state = :syn_sent
			response = timeout(@timeout) { @sock.recvfrom(@recv_buf_size) } rescue nil

			if response
				@state = :connected

				response_pkt = Packet.new(raw: response)
				last_ack_nr = response_pkt.seq_nr

				last_timestamp = response_pkt.timestamp
			else
				raise TimeoutError, 'Timed out while waiting for peer'
			end
		end

		def send data
			pkt = Packet.new(
				type: :data,
				connection_id: @connection_id,
				seq_nr: @last_seq_nr += 1,
				ack_nr: @last_ack_nr,
				wnd_size: @wnd_size,
				data: data
			)

			@sock.send(pkt.bytes, 0)
		end
	end

	class Socket

		SOCKET_STATES = [:idle, :syn_sent, :connected, :connected_full, :got_fin, :destroy_delay, :fin_sent, :reset, :destroy]

		def initialize host, port
		end

		def connect host, port
		end

		def send data
			# raise NotConnectedError, 'Cannot send data when not connected' unless [:connected, :connected_full].include?(@state)
		end
	end

	# s = Socket.new('127.0.0.1', 9348)

	# s.connect(nil, nil)

	s = Packet.new(wnd_size: 5, timestamp: 55555555, ack_nr: 94, seq_nr: 55)
	puts s.inspect

	t = Packet.new(raw: s.bytes)
	puts t.inspect
end