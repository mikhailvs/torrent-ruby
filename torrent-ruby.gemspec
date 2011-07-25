Gem::Specification.new do |s|
  s.name = 'torrent-ruby'
  s.version = '0.1.4'
  s.date =  '2011-07-24'
  s.authors = ["Mikhail Slyusarev"]
  s.email = 'slyusarevmikhail@gmail.com'
  s.summary = 'torrent-ruby is a library for easily handling ' +
              'bencoding/bdecoding data, .torrent files and ' +
              'communication with bittorrent trackers.'
  s.homepage = 'http://mikhailvs.github.com/torrent-ruby/'
  s.description = 'torrent-ruby is a library for easily handling ' +
                  'bencoding/bdecoding data, .torrent files and ' +
                  'communication with bittorrent trackers.'
  s.files = ['LICENSE', 'README', 'Rakefile', 'lib/bencode.rb',
             'lib/torrent_file.rb', 'lib/tracker_handler.rb',
             'test/test_bencode.rb', 'test/test_torrent_file.rb',
             'test/test_tracker_handler.rb',
             'test/extra/archlinux-2010.05-core-dual.iso.torrent',
             'test/extra/Fedora-15-i386-DVD.torrent',
             'test/extra/FreeBSD-8.2-RELEASE-amd64-all.torrent',
             'test/extra/ubuntu-10.04.2-alternate-amd64.iso.torrent']
  s.licenses = ['GPL v3']
end
