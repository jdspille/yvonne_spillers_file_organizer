require 'fileutils'
require 'colorize'
require 'date'
require 'pdf-reader'

class Client
	attr_accessor :firstName, :lastName, :folderLoc
end

#Generates list of clients into an array of Clients
def genClientList
	clientList = Array.new #make list of clients 
	Dir.glob("../../Clients/*").each do |plo|
		temp = Client.new
		temp.folderLoc = plo + "/" #file loc is in the GLOB
		ubufn = plo[plo.rindex('/')+1,200] #create unbuffered name, with cut dir data
		if plo.index(',') == nil then #if there's a comma meaning First/Last Name	
			#No Comma
			temp.lastName = ubufn #last name is USUALLY the only thing specified if there's no comma
		else
			#Yes Comma
			temp.lastName = ubufn[0,ubufn.index(',')] #last name is till comma
			temp.firstName = ubufn[ubufn.index(',')+1, 100] #first name is after comma 
		end
		clientList << temp
	end
return clientList
end
#GLOBAL VARIABLES



################

#Uses list of clients, compares them to names of files in pwd, moves files to appropriate file locations
def moveAllClients
	clientList = genClientList
	Dir.glob("*.pdf").each do |fil|
	
		if fil.index(' ') then
			#if there IS a space
			fCli = fil[0, fil.index(' ')]	#gets last name of client
			clientList.each do |cli|
				if fCli == cli.lastName then
					#if the last name matches a client's last name
					FileUtils.mv("#{fil}", "#{cli.folderLoc}", :force => true) #move the file to the appropriate folder
					break
				end
			end
		else
			#if there ISN'T a space
			puts "File improperly formatted."
		end
	end
end

def moveAFile (fileToMove) #@fileToMove taken in format "Spillers 0.0.0 Depo.pdf"
	clientList = genClientList
	daSpace = fileToMove.index(' ')
	if daSpace != nil then
		#There is a space!
		clientList.each do |cli|
			if fileToMove[0, daSpace].downcase == cli.LastName.downcase then
				FileUtils.mv("#{fileToMove}","#{cli.folderLoc}", :force => true)
				puts "File Moved!".green
				break
			end
		end
	else
		puts "Cannot Move File | File Improperly Formatted".red
	end
end

def renameAFile (fileToRename) #@fileToRename taken in format "*.pdf"
	clientList = genClientList
	person = Client.new
	monthlist = Date::MONTHNAMES[1,100]
	type = "Fake"
	cfound = false
	mfound = false
	tfound = false
	reader = PDF::Reader.new(fileToRename)
	reader.pages.each do |page| #for every page in the pdf
		page.text.each_line do |line|
			scroll = line.downcase
			#scan for |Last Name|, |Date|, then |Type|, in that order
			#scan for last name
			if cfound == false
				clientList.each do |cli|
					if scroll.include?cli.lastName.downcase
						person = cli
						cfound = true
						puts "---->Found Client #{person.lastName}".yellow
						break
					end
				end
			end	
			#scan for Date
			if mfound == false
				monthlist.each do |mon|
					if scroll.include?mon.downcase
						begin
							longDate = /\w+ \d{,2},* \d{4}/.match(scroll).to_s
							date = DateTime.parse(longDate).strftime("20%y.%m.%d")
							puts "-----> Date Found : #{date}"
							mfound = true
							break
						rescue
							begin
							longDate = /\/\d{,2}\/\d{,2}\/\d{4}/.match(scroll).to_s
							date = DateTime.parse(longDate).strftime("20%y.%m.%d")
							puts "-----> Date Found : #{date}"
							mfound = true
							break
							rescue
								puts "----->Thought I found a date, just an awkward platonic coffee date :p".red
							end
						end
					end
				end
			end
			#scan for Type
			if tfound == false
				typesOf.each do |ptr|
					if scroll.include?ptr.downcase
                  				type=ptr[ptr.index(ptr),ptr.length].lstrip.chomp #cut away nonsense
						type=type.gsub('\n','').gsub('\t','').gsub(/[^0-9A-Za-z ]/,"").gsub(/ +/, " ")
						type=type.split(/(\W)/).map(&:capitalize).join #put to sentence case
						type=type[0..50].chomp
						puts "-----> Found Type #{type}".yellow	
						tfound = true
						break
					end
			endz
			end
		end
	end
if cfound then
	newFileName = "#{person.lastName} #{date} #{type}.pdf"
	File.rename(fileToRename, newFileName)
	puts "File Renamed!".green
	return newFileName	
else
	puts "File not Recognized!".red
end
end
end
	i=0
	Dir.glob("*.pdf").each do |fil|
		puts "=============================".white
		puts "Scanning: '#{fil}'"
		#toMove = renameAFile(fil)
		#if toMove!=nil
			moveAFile(fil) #renames file to appropriate syntax, then moves that file to appropriate location
		#end
		i+=1
		puts "=============================".white
	end