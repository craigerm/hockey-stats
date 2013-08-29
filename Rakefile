require 'rubygems'
require 'active_support/core_ext/numeric/time'
require 'nokogiri'
require 'open-uri'
require 'date'
require 'pry'
require './tasks/scrape'
# Total games per year: 1,230
# 30 teams

# 2012-2013 from Jan 19 2013 - June 24 2013
#http://www.nhl.com/ice/scores.htm?date=01/19/2013

# Selector for getting box score links for the score pages
# $('.sbGame > .gcLinks > div a[shape=rect]:contains("BOXSCORE")')

ROOT_FOLDER = './pages'
DELAY = 0.1 #seconds

SEASONS = {
  2013 => {:start => Date.new(2013, 1, 19), :end => Date.new(2013, 6, 24) },
  2012 => {:start => Date.new(2011, 10, 1), :end => Date.new(2012, 6, 11) },
  2011 => {:start => Date.new(2010, 10, 7), :end => Date.new(2011, 6, 15) },
  2010 => {:start => Date.new(2009, 10, 1), :end => Date.new(2010, 6, 9) },
  2009 => {:start => Date.new(2008, 10, 4), :end => Date.new(2009, 6, 12) }
}

# The season for processing
SEASON = ENV['season'] || #2013

@start_time= nil

def start
  @start_time = Time.now
end

def stop
  elapsed = Time.now - @start_time
  puts "Time: #{elapsed.round(0)}"
end

def get_scores(start_date, end_date)
  start
  counter = 0
  date = start_date
  while date <= end_date
    str_date = date.strftime('%m/%d/%Y')
    file_name = date.strftime('scores_%Y-%m-%d.htm')
    save_page('scores', file_name, "http://nhl.com/ice/scores.htm?date=#{str_date}")
    date = date + 1
    counter += 1
  end

  puts "total pages #{counter}"
  stop
end

#http://www.nhl.com/scores/htmlreports/20102011/ES020001.HTM
#/ice/boxscore.htm?id=2012020313
def get_event_summary(year)

  boxscores_path = "#{ROOT_FOLDER}/#{year}/boxscores.txt"
  game_ids = "#{ROOT_FOLDER}/#{year}/game_ids.txt"

  FileUtils.rm boxscores_path, :force => true
  FileUtils.rm game_ids, :force => true

  open(boxscores_path, 'w') do |file|
    open(game_ids, 'w') do |games|
      Dir.foreach "#{ROOT_FOLDER}/#{year}/scores" do |filename|
        next if filename == '.' || filename == '..'
        doc = Nokogiri::HTML(open("#{ROOT_FOLDER}/#{year}/scores/#{filename}"))
        doc.css('a[shape=rect]:contains("BOXSCORE")').each do |link|
          href = link.get_attribute(:href)
          boxid = href.split('?id=')[1]
          file.puts href
          games.puts boxid
        end
      end
    end
  end
end


def report_url(type, year, boxid)
  yearpart = "#{year - 1}#{year}"
  boxid.slice!(0, 4)
  "http://www.nhl.com/scores/htmlreports/#{yearpart}/#{type}#{boxid}.HTM"
end

def get_game_summaries(year)
  game_ids = "#{ROOT_FOLDER}/#{year}/game_ids.txt"
  IO.readlines(game_ids).each do |id|
    id.chomp!
    url = report_url('ES', year, id)
    filename = "#{id}.htm"
    save_page("#{year}/event_summaries", filename, url)
    break
  end
end

def get_plays(year)
  game_ids = "#{ROOT_FOLDER}/#{year}/game_ids.txt"
  IO.readlines(game_ids).each do |id|
    id.chomp!
    url = report_url('PL', year, id)
    filename = "#{id}.htm"
    save_page("#{year}/plays", filename, url)
    break
  end
end

def get_seasons
  return SEASONS unless SEASON
  return [SEASONS[SEASON]] if SEASON
  return SEASONS
end

# GENERIC SCRAPING
def save_page(folder, filename, url)
  FileUtils.mkdir_p "#{ROOT_FOLDER}/#{folder}"
  dest_filename = "#{ROOT_FOLDER}/#{folder}/#{filename}"
  puts "#{dest_filename} => #{url}"
  sleep DELAY
  open(url) do |file|
    open(dest_filename, 'wb') do |write|
      write.write(file.read)
    end
  end
end


def run(title, year, &block)
  puts "Grabbing #{title} ids for season #{year}"
  puts "======================================="
  start
  block.call
  stop
  puts "\n\n"
end

namespace :pages do

  task :scores do
    raise 'TURNED OFF!' # OFf just so we don't remove our existing pages
    get_seasons.each do |year,dates|
      run 'score pages', year do
        get_scores(dates[:start], dates[:end])
      end
    end
  end

  task :events do
    get_seasons.each do |year, date|
      run 'game ids', year do
        get_event_summary(year)
      end
    end
  end

  task :summaries do
    get_seasons.each do |year, date|
      next unless year == 2013
      run 'game summaries', year do
        get_game_summaries(year)
      end
    end
  end

  task :plays do
    get_seasons.each do |year, date|
      return unless year == 2013
      run 'play by plays', year do
        #get_plays(year)
      end
    end
  end
end
