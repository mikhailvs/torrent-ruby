Gem::Specification.new do |s|
  s.name = 'torrent-ruby'
  s.version = '0.1.6'
  s.date =  '2014-02-15'
  s.authors = ["Mikhail Slyusarev"]
  
  s.email = 'slyusarevmikhail@gmail.com'

  s.summary = 'torrent-ruby is a library for easily handling bencoding/bdecoding data, .torrent files and communication with bittorrent trackers.'

  s.homepage = 'http://mikhailvs.github.com/torrent-ruby/'

  s.files = [
    'LICENSE',
    'README',
    'Rakefile',
    'lib/torrent-ruby/bencode.rb',
    'lib/torrent-ruby/torrent_file.rb',
    'lib/torrent-ruby/tracker_handler.rb',
    'lib/torrent-ruby.rb'
  ]
  s.licenses = ['GPL v3']
end
