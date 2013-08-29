require 'rubygems'
require 'active_support/core_ext/numeric/time'
require 'nokogiri'
require 'open-uri'
require 'date'
require 'pry'
require './tasks/scrape'

# Total games per year: 1,230
# 30 teams

ROOT_FOLDER = './pages'

# Delay for pulling data
DELAY = 0.1

# The season start and end date including playoffs
SEASONS = {
  2013 => {:start => Date.new(2013, 1, 19), :end => Date.new(2013, 6, 24) },
  2012 => {:start => Date.new(2011, 10, 1), :end => Date.new(2012, 6, 11) },
  2011 => {:start => Date.new(2010, 10, 7), :end => Date.new(2011, 6, 15) },
  2010 => {:start => Date.new(2009, 10, 1), :end => Date.new(2010, 6, 9) },
  2009 => {:start => Date.new(2008, 10, 4), :end => Date.new(2009, 6, 12) }
}

# The season for processing
SEASON = ENV['season']

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


def run(title, &block)
  get_seasons.each do |year, dates|
    puts "Grabbing #{title} ids for season #{year}"
    puts "======================================="
    start
    block.call(year, dates)
    stop
    puts "\n\n"
  end
end

namespace :pages do

  task :scores do
    run 'score pages' do
      get_scores(dates[:start], dates[:end])
    end
  end

  task :events do
    run 'game ids' do
      get_event_summary(year)
    end
  end

  task :summaries do
    next unless year == 2013
    run 'game summaries' do
      get_game_summaries(year)
    end
  end

  task :plays do
    next unless year == 2013
    run 'play by plays' do |year, dates|
      get_plays(year)
    end
  end
end
