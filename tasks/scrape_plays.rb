def get_player_on_ice(table)
  {
    :number => raw_int(table.css('td font').first.content),
    :position => table.css('td').last.content
  }
end

def get_players_on_ice(cell)
  players = []
  cell.css('table table').each do |table|
    players << get_player_on_ice(table)
  end
  players
end

def cell(row, cell_number)
  row.css("td:eq(#{cell_number})").first.content
end

def get_play_by_play(row, number)
  times = row.css('td:eq(4)').first.inner_html.split('<br>')
  strength = cell(row, 3)
  strength = '' if strength[0].ord == 160
  {
    :num => number,
    :strength => strength,
    :event => cell(row, 5),
    :description => str(cell(row, 6)),
    :start_time => times[0],
    :end_time => times[1],
    :away_players => get_players_on_ice(row.css('td:eq(7)')),
    :home_players => get_players_on_ice(row.css('td:eq(8)'))
  }
end

def get_play_by_plays(rows)
  plays = []
  number = 1
  rows.each do |row|
    next unless row.get_attribute(:class) == 'evenColor'
    plays << get_play_by_play(row, number)
    number += 1
  end
  plays
end

def scrape_plays(year)
  dir = "#{ROOT_FOLDER}/#{year}/plays"
  Dir.foreach(dir) do |filename|
    next if filename == '.' || filename == '..'
    doc = Nokogiri::HTML(open("#{dir}/#{filename}"))
    info = {
      :period_1 => get_play_by_plays(doc.css('body > table:eq(1) > tr')),
      :period_2 => get_play_by_plays(doc.css('body > table:eq(2) > tr')),
      :period_3 => get_play_by_plays(doc.css('body > table:eq(3) > tr'))
    }
    puts info.to_json
    break
  end
end

namespace :scrape do
  task :plays do
    scrape_plays(2013)
  end
end

