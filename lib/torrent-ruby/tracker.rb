class Tracker
	attr_reader :url, :scheme, :port, :path, :host

	def initialize url, info_hash, peer_id
		@url = url.to_s
		@scheme = url.scheme
		@port = url.port
		@path = url.path
		@host = url.host
		@info_hash = info_hash
		@peer_id = peer_id
	end

	# Establish connections to this tracker
	def connect tracker_timeout = 10
    # TODO handle UDP trackers.
    success = false
    if ['http', 'https'].include?(@scheme)
      timeout(tracker_timeout) do
        @connection = Net::HTTP.start(@host, @port)
        @connection.use_ssl = true if @scheme == 'https'
        success = true
      end
    else
    	raise Exception, 'Only HTTP trackers are currently supported.'
    end
    success
	end

	def get_peers numwant = 50
    # NOTE: I think the bencoder is broken or something because when compact is not set, exception are thrown
    # it needs to be investigated at some point
    response = request(
      info_hash: @info_hash,
      compact: 1,
      peer_id: @peer_id,
      numwant: numwant
    )

    # dictionary mode
    if response['peers'].is_a?(Array)
      puts response['peers']
      @peers = response['peers'].collect { |p| Peer.new(p['ip'], p['port']) }
    else # binary mode
      @peers = parse_binary_peers(response['peers'])
    end
  end

  # Make http request to the tracker and get results.
	def request params = {}
    # If there's nothing to connect to. Catch this exception.
    # raise Exception, "No trackers connected." if @connected_trackers.empty?  

    # All parameters defined in the specification are required except for ip, numwant,
    # key and trackerid.
    required_params = [:info_hash, :peer_id]
    diff = required_params - params.keys
    
    if diff.empty?
    	self.connect unless @connection

    	raise Exception, 'Could not connect to tracker' if @connection.nil?

      request_string = "#{@path}?" + params.collect { |k, v| "#{k}=#{v}" }.join('&')
    else
      raise ArgumentError, "Required values for keys: #{diff.join(', ')} not provided"
    end

    # Make, and return the body of, the request.
    response = @connection.request(Net::HTTP::Get.new(request_string))

    response.body.bdecode
	end

  # Scrape tracker if the tracker supports it (determined as described in
  # http://wiki.theory.org/BitTorrentSpecification#Tracker_.27scrape.27_Convention).
  def scrape info_hashes = []
    info_hash_string = ''
    info_hashes.each { |hash| info_hash_string << "info_hash=#{hash}&" }

    # if the last element of the path is announce, then scrape is supported
    if @path.index('/announce') == @path.rindex('/')
    	self.connect unless @connection
    	raise Exception, 'Could not connect to tracker' if @connection.nil?

      scrape_path = @path.gsub(/(.*?)announce(.*?)/, '\1scrape\2')
      @connection.request(Net::HTTP::Get.new("#{scrape_path}?#{info_hash_string}")).body.bdecode
    end
  end

  # parse the binary list of peers into a more manageable format
  def parse_binary_peers peerslist
    bytes = peerslist.unpack('C*')
    peers = []
    endianness = [1].pack('I') == [1].pack('N') ? :big : :little

    until bytes.empty?
      if endianness == :big
        peers << Peer.new(bytes[0..3].join('.'), bytes[4] << 8 | bytes[5])
      else
        # IP is in the first 4 bytes, port is in last 2.
        peers << Peer.new(bytes[0..3].reverse.join('.'), bytes[5] << 8 | bytes[4])
      end
      bytes = bytes[6..-1]
    end
    peers
  end
end