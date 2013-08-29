require 'rubygems'
require 'active_support/core_ext/numeric/time'
require 'nokogiri'
require 'open-uri'
require 'date'
require 'pry'
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

def get_seasons
  return SEASONS unless SEASON
  return [SEASONS[SEASON]] if SEASON
  return SEASONS
end

def clean_folder(folder)
  FileUtils.rm_rf("#{ROOT_FOLDER}/#{folder}/.", secure: true)
end

# GENERIC SCRAPING
def save_page(folder, filename, url)
  dest_filename = "#{ROOT_FOLDER}/#{folder}/#{filename}"
  #puts "#{dest_filename} => #{url}"
  sleep DELAY
  open(url) do |file|
    open(dest_filename, 'wb') do |write|
      write.write(file.read)
    end
  end
end

namespace :pages do
  task :scores do
    get_seasons.each do |year,dates|
      next if year == 2012 || year == 2013
      puts "Grabbing score pages for season #{year}"
      puts "======================================="
      get_scores(dates[:start], dates[:end])
      puts "\n\n"
    end
  end
end
