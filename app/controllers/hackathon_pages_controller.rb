require 'rubygems'
require 'open-uri'
require 'json'
require 'csv'

# Controller for Hackathon Page Routes
class HackathonPagesController < ApplicationController
  def parse_csv
    @states = {}
    CSV.foreach('./app/assets/csvs/states.csv', col_sep: ';') do |row|
      @states[row[0].downcase] ||= []
      @states[row[0].downcase] << row[1].downcase

      @states[row[1].downcase] ||= []
      @states[row[1].downcase] << row[0].downcase
    end

    @abbreviations = {}
    CSV.foreach('./app/assets/csvs/abbrev.csv') do |row|
      @abbreviations[row[0].downcase] = row[1].downcase
    end
  end

  def format_date(initial, final)
    start_date = DateTime.rfc3339(initial)
    end_date = DateTime.rfc3339(final)

    s = start_date.mday
    decor = [['st'][s - 1], ['nd'][s - 2], ['rd'][s - 3]].join
    start_decoration = decor.empty? ? 'th' : decor

    e = end_date.mday
    decor = [['st'][e - 1], ['nd'][e - 2], ['rd'][e - 3]].join
    end_decoration = decor.empty? ? 'th' : decor

    if e - s > 0
      start_date.strftime("%B #{s}#{start_decoration}-#{e }#{end_decoration},
                          %Y")
    else
      start_date.strftime("%B #{s}#{start_decoration}, %Y")
    end
  end

  def format_url(url)
    /^http/.match(url) ? url  : "http://#{url}"
  end

  def connect
    hackerleague = open('https://www.hackerleague.org/api/v1/hackathons.json')
    JSON.parse(hackerleague.read)
  end

  def get_hackathons(search)
    @hackathons = []
    return if search.nil?

    search = @abbreviations[search] if search.length > 2
    @neighbors = @states[search]

    response = session[:HLresponse]
    response.each do |hackathon, _|
      location = hackathon['location']
      state = location['state']

      next if state.nil?
      puts "Search: #{search}"
      puts "Hackathon's Original State: #{state}"
      state = @abbreviations[state.downcase] if state.length != 2
      puts "Hackathon's Modified State: #{state}"

      next if state.blank?

      if search != state.downcase
        if !@neighbors.nil?
          is_neighbor = false
          @neighbors.each { |x| is_neighbor = true if x == state.downcase }
          next if is_neighbor == false
        else
          next
        end
      end

      next if 'complete' == hackathon['state']
      date = format_date hackathon['start_time'], hackathon['end_time']
      hackathon['date'] = date
      hackathon['external_url'] = format_url(hackathon['external_url'])
      @hackathons << hackathon
    end
  end

  def home
    session[:HLresponse] ||= connect
  end

  def hackathons
    session[:search] = params[:input] unless params[:input].nil?
    parse_csv
    get_hackathons(session[:search].downcase)
  end
end
