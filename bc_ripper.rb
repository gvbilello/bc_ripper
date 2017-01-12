require 'rubygems'
require 'open-uri'
require 'fileutils'
require 'nokogiri'
require 'json'
# require 'pry'
# require 'pry-byebug'

# get artist name and album title

# get url of Bandcamp Page
puts "BC_Ripper"
puts "Beta version 0.1"
puts "---------------"
puts "Enter the url of the page you'd like to rip songs from:"
url = gets.chomp


# parse url with Nokogiri to get correct JS script containing tracks
source = Nokogiri::HTML(open(url))
scripts = source.xpath("//script")
index = nil
scripts.each do |script|
	if script.children.to_s.include?("var TralbumData")
		index = scripts.index(script)
		puts "TralbumData found in script with index: #{scripts.index(script)}"
	end
end


# get artist and album info
metas = source.xpath("//meta")
title = String.new

metas.each do |meta|
	if meta.attributes
		if meta.attributes["name"]
			if meta.attributes["name"].value
				if meta.attributes["name"].value == "title"
					title = meta.attributes["content"].value.tr!('/', '')
				end
			end
		end
	end
end

title_array = title.split(", by ")
album = title_array[0]
artist = title_array[1]

# create array of tracks mp3 urls
album_script = scripts[index].children.to_s

# get trackinfo array from JS and save it as a Ruby string
track_info = album_script.scan(/trackinfo:.*/)[0]

# remove 'trackinfo: ' from the start of string
track_info.sub!(/trackinfo: /,"")

# remove the comma (,) from the end of string
track_info[-1] = ""

# parse the string as a JSON object, turning it into a Ruby array of hashes
track_data = JSON.parse(track_info)

tracks = Array.new

# make array of tracks into array of hashes as such:
# ["track number", "track title", "track download link"]
track_data.each do |track|
	track_hash = Hash.new
	track.each do |key, value|
		if key == "title"
			track_hash[:title] = track[key]
			track_hash[:title].tr!('/', '')
		elsif key == "track_num"
			track_hash[:track_num] = track[key]
		elsif key == "file"
			track_hash[:download_link] = track[key]["mp3-128"]
		end
	end
	tracks << track_hash
end

# creating artist/album folder
FileUtils::mkdir_p "#{artist}/#{album}"

# download all tracks and save locally
puts "Downloading #{album}, by #{artist}..."
tracks.each do |track|
	puts "Downloading track #{track[:track_num]}, #{track[:title]}..."
	download = open("http:#{track[:download_link]}")
	IO.copy_stream(download, "#{artist}/#{album}/#{artist} - #{album} - #{track[:track_num]} - #{track[:title]}.mp3")
end

puts "All tracks successfully downloaded!"
