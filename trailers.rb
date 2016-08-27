#!/usr/bin/env ruby

require 'httparty'
require 'json'

class Trailer

  def initialize(web_url)
    @web_url = web_url
  end

  def name
    @web_url.split('/').last
  end

  def movie_id
    @movie_id ||= (
      response = HTTParty.get(@web_url)
      if response.code == 200
        # Get the ID of this movie
        # e.g. <meta name="apple-itunes-app" content="app-id=471966214, app-argument=movietrailers://movie/detail/17942">
        response.body.scan(%r|movietrailers://movie/detail/(\d+)|).flatten.first
      else
        STDERR.puts 'Failed to get movie ID'
      end
    )
  end

  def data
    @data ||= (
      url = "http://trailers.apple.com/trailers/feeds/data/#{movie_id}.json"
      response = HTTParty.get(url)
      if response.code == 200
        JSON.parse(response.body)
      else
        STDERR.puts 'Failed to get JSON for trailer'
      end
    )
  end

  # There can be a bunch of "clips", get the one labeled "Trailer"
  def trailer
    data['clips'].detect { |c| c['title'] == 'Trailer' }
  end

  def video_1080p_url
    trailer['versions']['enus']['sizes']['hd1080']['srcAlt']
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

    if File.exist?("trailers/#{trailer.name}.mp4")
      puts "Skipping #{trailer.name} -- already have it"
      next
    end

    puts "Downloading trailer for #{trailer.name} ... "

    `curl --progress-bar -H "Referer: trailers.apple.com" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.57 Safari/537.36" '#{trailer.video_1080p_url}' > trailers/#{trailer.name}.mp4`

    puts "\n"

  rescue Exception => ex
    puts "Cannot get #{url}:\n#{ex}\n\n"
  end

end
