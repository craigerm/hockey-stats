def raw_int(str)
  str.split(',').join('').to_i
end

def str(str)
  str.strip.upcase
end

def raw_date(str)
  DateTime.parse(str).strftime('%Y-%m-%d')
end

def add_venue_data(info, s)
  parts = s.split('@')
  venue =  parts[1]
  venue.slice!(0, 1)
  info[:venue] = str(venue)
  info[:attendence] = raw_int(parts[0].split('. ')[1])
end

def add_game_time(info, s)
  parts = s.split(' ')
  start_time = parts
  duration = 9999
  info[:start_time] =  nil
  info[:duration] = duration
end

def add_team_info(info, team_type, s)
  info["#{team_type}_team"] = str(s.split('<br>')[0])
end

def add_score_info(info, team_type, s)
  info["#{team_type}_score"] = raw_int(s)
end

def add_header_info(doc, info)
  venue_data = doc.css('#GameInfo tr:eq(5) > td').first.content
  add_venue_data(info, venue_data)
  add_game_time(info, doc.css('#GameInfo tr:eq(6) > td').first.content)
  add_team_info(info, :home, doc.css('#Home tr:eq(3) > td').first.inner_html)
  add_team_info(info, :away, doc.css('#Visitor tr:eq(3) > td').first.inner_html)
  add_score_info(info, :home, doc.css('#Home tr:eq(2) tr td:eq(2)').first.content)
  add_score_info(info, :away, doc.css('#Visitor tr:eq(2) tr td:eq(2)').first.content)
  info[:id] = doc.css('#GameInfo tr:eq(7) > td').first.content.split(' ')[1]
  info[:date] = raw_date(doc.css('#GameInfo tr:eq(4) > td').first.content)
end

def scrape_summaries(year)
  dir = "#{ROOT_FOLDER}/#{year}/event_summaries" 
  Dir.foreach(dir) do |filename|
    next if filename == '.' || filename == '..'
    puts "FILE #{filename}"
    doc = Nokogiri::HTML(open("#{dir}/#{filename}"))
    info = {}
    add_header_info(doc, info)

    puts "STR => #{info}"

    break
  end
end

namespace :scrape do
  task :games do
    scrape_summaries(2013)
  end
end

