#!/usr/bin/env ruby

require 'httparty'

class Trailer

  def initialize(web_url)
    @web_url = web_url
  end

  def name
    @web_url.split('/').last
  end

  def video_shell_url
    @video_shell_url ||= (
      secret_url = "#{@web_url}includes/trailer/large.html"
      response = HTTParty.get(secret_url)
      if response.code == 200
        shell_url = response.body.scan(/class="movieLink" href="(.*?)"/).flatten.first
        # e.g. http://movietrailers.apple.com/movies/independent/justinbiebersbelieve/believe-tlr1_480p.mov?width=848&amp;height=352
        shell_url.gsub(/\?.*$/, '')
      else
        nil
      end
    )
  end

  def video_480p_url
    video_shell_url.gsub('480p', 'h480p')
  end

  def video_720p_url
    video_shell_url.gsub('480p', 'h720p')
  end

end

puts ''
puts '__   __                 _____          _ _                   ____  _      '
puts '\ \ / /__  _   _ _ __  |_   _| __ __ _(_) | ___ _ __ ___    / ___|(_)_ __ '
puts ' \ V / _ \| | | | \'__|   | || \'__/ _` | | |/ _ \ \'__/ __|   \___ \| | \'__|'
puts '  | | (_) | |_| | |      | || | | (_| | | |  __/ |  \__ \_   ___) | | |   '
puts '  |_|\___/ \__,_|_|      |_||_|  \__,_|_|_|\___|_|  |___( ) |____/|_|_|   '
puts '                                                        |/                '
puts ''

response = HTTParty.get('http://trailers.apple.com/trailers/home/rss/newtrailers.rss')
urls = response.body.scan(/<item>.*?<link>(.*?)<\/link>.*?<\/item>/m).flatten

`mkdir -p trailers`

urls.each do |url|

  begin
    trailer = Trailer.new(url)
    print "Downloading trailer for #{trailer.name} ... "

    `curl --silent -H "Referer: trailers.apple.com" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.57 Safari/537.36" '#{trailer.video_720p_url}' > trailers/#{trailer.name}.mp4`

    puts "done!\n"

  rescue Exception => ex
    puts "Cannot get #{url}:\n#{ex}\n\n"
  end

end
