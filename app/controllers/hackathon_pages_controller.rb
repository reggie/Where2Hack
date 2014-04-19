require "rubygems"
require "open-uri"
require "json"
require "csv"

class HackathonPagesController < ApplicationController
   
  def parseCSVs
	 	@states = {}
 		CSV.foreach("./app/assets/csvs/states.csv", { col_sep: ';'}) do |row|
 			@states[row[0].downcase] ||= []
 			@states[row[0].downcase] << row[1].downcase

 			@states[row[1].downcase] ||= []
 			@states[row[1].downcase] << row[0].downcase
 		end
 
 		@abbreviations = {}
 		CSV.foreach("./app/assets/csvs/abbrev.csv") do |row|
 			@abbreviations[row[0].downcase] = row[1].downcase
 		end
 	end

	def formatDate initial, final
		startDate = DateTime.rfc3339(initial)	
		endDate = DateTime.rfc3339(final)

		s = startDate.mday
		startDecoration = ( decor = [["st"][s - 1], ["nd"][s - 2], ["rd"][s - 3]].join).empty? ? "th" : decor

		e = endDate.mday
		endDecoration = ( decor = [["st"][e - 1], ["nd"][e - 2], ["rd"][e - 3]].join).empty? ? "th" : decor
		if (e - s > 0)
			startDate.strftime("%B #{s}#{startDecoration}-#{e}#{endDecoration}, %Y")
		else	
			startDate.strftime("%B #{s}#{startDecoration}, %Y")
		end
	end

	def formatURL url
		/^http/.match(url) ? url  : "http://#{url}"
	end

	def connect
  	hackerleague = open("http://hackerleague.org/api/v1/hackathons.json")
  	response = JSON.parse(hackerleague.read)
		return response
	end

	def getHackathons search
		
		puts search
	 	@hackathons = []
		if search.nil?
			return
		end	
		search = @abbreviations[search] if search.length > 2
 		@neighbors = @states[search]
		
		puts session
		response = session[:HLresponse]
	 	response.each do |key, value| 
 		location = key["location"]
 		state = location["state"]

		if !state.nil?
  		state = @abbreviations[state.downcase] if state.length != 2  
	 	end

		if state.nil? 
			next
		end

 		if search != state 
			if !@neighbors.nil?
	 			isNeighbor = false
 				@neighbors.each { |x| isNeighbor = true if x == state}
 				next if isNeighbor == false
			else
				next
			end
 		end 
 		next if "complete" == key["state"]
		date = formatDate key["start_time"], key["end_time"]
		key["date"] = date
		key["external_url"] = formatURL key["external_url"]
 		@hackathons << key
 		end
 	end

  def home
		session[:HLresponse] ||= connect		
  end

  def hackathons
		if !params[:input].nil?
			session[:search] = params[:input]
		end
		parseCSVs
		getHackathons session[:search].downcase
  end
end
