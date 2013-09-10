def raw_int(str)
  str.split(',').join('').to_i
end

def str(str)
  str.strip.upcase.encode(
    Encoding.find('ASCII'), { 
      :undef => :replace, 
      :replace => ' '
    }
  )
end

def percentage(str)
  raw_int(str) / 100.0
end

def raw_date(str)
  DateTime.parse(str).strftime('%Y-%m-%d')
end

def get_int(row, selector)
  raw_int(row.css(selector).first.content)
end

def get_string(row, selector)
  str(row.css(selector).first.content)
end

def get_percentage(row, selector)
  percentage(row.css(selector).first.content)
end

def get_game_time(s)
  s = str(s).gsub(';','').split(' ')
  "#{s[-2]} #{s[-1]}"
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
  info[:start_time] = get_game_time(parts[0])
  info[:end_time] = get_game_time(parts[1])
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

def get_player_stats(row)
  {
    :number => get_int(row, 'td:eq(1)'),
    :position => row.css('td:eq(2)').first.content,
    :name => row.css('td:eq(3)').first.content,
    :stats => {
      :goals => get_int(row, 'td:eq(4)'),
      :assists  => get_int(row, 'td:eq(5)'),
      :points  => get_int(row, 'td:eq(6)'),
      :plus_minus => get_int(row, 'td:eq(7)'),
      :num_penalties => get_int(row, 'td:eq(8)'),
      :penalty_minutes => get_int(row, 'td:eq(9)'),
      :shifts => {
        :total_ice_time => get_string(row, 'td:eq(10)'),
        :count => get_int(row, 'td:eq(11)'),
        :average_ice_time => get_string(row, 'td:eq(12)'),
        :pp_time => get_string(row, 'td:eq(13)'),
        :sh_time => get_string(row, 'td:eq(14)'),
        :ev_time => get_string(row, 'td:eq(15)')
      },
      :shots => get_int(row, 'td:eq(16)'),
      :block_attempts => get_int(row, 'td:eq(17)'),
      :missed_shots => get_int(row, 'td:eq(18)'),
      :hits_given => get_int(row, 'td:eq(19)'),
      :giveaways => get_int(row, 'td:eq(20)'),
      :takeaways => get_int(row, 'td:eq(21)'),
      :shots_blocked => get_int(row, 'td:eq(22)'),
      :faceoffs => {
        :won => get_int(row, 'td:eq(23)'),
        :lost => get_int(row, 'td:eq(24)'),
        :percentage => get_percentage(row, 'td:eq(25)')
      }
    }
  }
end

def get_player_rows(doc)
  container = doc.css('body > xmlfile > table > tr:eq(8) table')
  rows = container.css('tr')
  home = []
  away = []

  team = away

  rows.each_with_index do |row, index|

    unless index > 1
      next
    end

    classes = row.get_attribute(:class)
    if classes == 'evenColor' || classes == 'oddColor'
      team << get_player_stats(row)
    else
      team = home
    end
  end

  {:home_stats => home, :away_stats => away}
end

def get_team_summary(table)
  {
    :faceoffs => {
      :even_strength => {
        :won => 500,
        :lost => 500,
        :percentage => 0.51
      }
    }
  }
end

def get_team_summaries(doc, info)
  tables = doc.css('body > xmlfile > table > tr:eq(4) table')
  {
    :away_totals => get_team_summary(tables[3])
  }
end

def get_faceoff_stats(str)
  parts = str.gsub('-', '/').split('/')
  won = raw_int(parts[0])
  total = raw_int(parts[1])
  percent = percentage(parts[2])
  {
    :won => won,
    :lost => total - won,
    :percentage => percent
  }
end

def get_shot_stats(str)
  p = str.split('-')
  scored = p.length == 2 ? raw_int(p[0]) : 0
  total = p.length == 2 ? raw_int(p[1]) : 0
  {
    :scored => scored,
    :missed => total - scored,
    :total => total
  }
end

def get_team_totals(row, faceoff_cells, shot_cells)
  {
    :goals => get_int(row, 'td:eq(2)'),
    :assists => get_int(row, 'td:eq(3)'),
    :points => get_int(row, 'td:eq(4)'),
    :plus_minus => get_int(row, 'td:eq(5)'),
    :num_penalties => get_int(row, 'td:eq(6)'),
    :penalty_minutes => get_int(row, 'td:eq(7)'),
    :shots => {
      :total => get_shot_stats(shot_cells.css('table:eq(1) tr:eq(2) td')[3].content),
      :even_strength => get_shot_stats(shot_cells.css('table:eq(1) tr:eq(2) td').first.content),
      :power_play => get_shot_stats(shot_cells.css('table:eq(1) tr:eq(2) td')[1].content),
      :short_handed => get_shot_stats(shot_cells.css('table:eq(1) tr:eq(2) td')[2].content),
      :five_vs_five => get_shot_stats(shot_cells.css('table:eq(1) tr:eq(2) td')[2].content),
      :five_vs_four => nil,
      :four_vs_five => nil,
      :four_vs_four => nil,
      :four_vs_three => nil,
      :three_vs_five => nil,
      :three_vs_four => nil,
      :three_vs_three => nil
    },
    :block_attempts => get_int(row, 'td:eq(15)'),
    :missed_shots => get_int(row, 'td:eq(16)'),
    :hits => get_int(row, 'td:eq(17)'),
    :giveaways => get_int(row, 'td:eq(18)'),
    :takeaways => get_int(row, 'td:eq(19)'),
    :shots_blocked => get_int(row, 'td:eq(20)'),
    :faceoffs => {
      :even_strength => get_faceoff_stats(faceoff_cells[0].content),
      :power_play => get_faceoff_stats(faceoff_cells[1].content),
      :short_handed => get_faceoff_stats(faceoff_cells[2].content),
      :total => {
        :won => get_int(row, 'td:eq(21)'),
        :lost => get_int(row, 'td:eq(22)'),
        :percentage => get_percentage(row, 'td:eq(23)')
      }
    }
  }
end

# TODO: Add team shot totals and game duration
def add_team_totals(doc, info)
  shot_cells = doc.css('body > xmlfile > table > tr:eq(3) > td > table > tr:eq(2) > td > table >tr > td')
  faceoff_cells = doc.css('body > xmlfile > table > tr:eq(5) > td > table > tr:eq(2) table tr:eq(2) td')
  rows = doc.css('body > xmlfile > table > tr:eq(8) table tr.bold')
  info[:away_totals] = get_team_totals(rows[0], faceoff_cells[0..3], shot_cells[0])
  info[:home_totals] = get_team_totals(rows[1], faceoff_cells[4..7], shot_cells[1])
  info
end


def add_player_stats(doc, info)
  stats = get_player_rows(doc)
  info.merge!(stats)
end

def scrape_summaries(year)
  dir = "#{ROOT_FOLDER}/#{year}/event_summaries" 
  Dir.foreach(dir) do |filename|
    next if filename == '.' || filename == '..'
    #puts "FILE #{filename}"
    doc = Nokogiri::HTML(open("#{dir}/#{filename}"))
    info = {}
    add_header_info(doc, info)
    add_player_stats(doc, info)
    add_team_totals(doc, info)

    folder = "./raw/#{year}/games"
    data_filename = filename.split('.')[0] + '.json'
    FileUtils.mkdir_p folder
    open("#{folder}/#{data_filename}", 'wb') do |write|
      write.write(info.to_json)
    end

    puts info.to_json

    break
  end
end

namespace :scrape do
  task :games do
    scrape_summaries(2013)
  end
end

