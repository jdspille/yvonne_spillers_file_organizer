require 'fileutils'
require 'colorize'
require 'date'
require 'pdf-reader'


class Client
	attr_accessor :firstName, :lastName, :email, :phone, :altPhone, :altName, :address,:folderLoc
	def print
		printf("%-20.20s, %-20.20s | %-20.20s | %-20.20s | %-20.20s | %-20.20s\n", lastName, firstName, email, phone, address, folderLoc )
	end
	def printHead
		printf("%-20.20s, %-20.20s | %-20.20s | %-20.20s | %-20.20s | %-20.20s\n", "Last Name", "First Name", "Email", "Phone", "Address", "Folder Location")
	end
end





#loadClientData
def loadClientData
	clientList = Array.new
	counter = 0
	file = File.new("l.csv","r")
		while(line = file.gets)
			if line != nil
				puts "Loading new client..."
				temp = Client.new
				#text file parsing
				line.split(",").each do |data|
					puts "\tdata = #{data}"
							case counter
							when 0
									temp.lastName = data[1,100]
							when 1
								temp.firstName = data[0,data.index("\"")]
							when 2
								temp.phone = data
							when 3
								temp.email = data
							when 4
								temp.altName = data
							when 5
							temp.altPhone = data
							when 6..9
								temp.address = "#{temp.address} #{data}"
							else
								break
							end
				counter= counter + 1
				end
			counter = 0
			clientList.push(temp)
			end
		end
	file.close
	temp.printHead
	return clientList
end

#Generates list of clients into an array of Clients, importing data from loadClientData
def genClientList
	clientList = loadClientData #make list of clients
	Dir.glob("../../../Clients/*").each do |plo| #This assumes all clients are stored on 3 levels up, in folders listed as "LastName, FirstName"
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
		inList = clientList.find_index {|s| s.lastName == temp.lastName}
		if inList!=nil #update client info, unless the client isn't already in the list, in which case, add it. :D
			clientList[inList].folderLoc = temp.folderLoc
		else
			clientList.push(temp)
		end
	end
return clientList
end

#Uses list of clients, compares them to names of files in pwd, moves files to appropriate file locations
##Needs to be depreciated asap in favor of moveAFile
def moveAllClients (clientList)
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

def moveAFile (clientList, fileToMove) #@fileToMove taken in format "Spillers 0.0.0 Depo.pdf"
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

def renameAFile (clientList, fileToRename) #@fileToRename taken in format "*.pdf"
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


#Scans root, moves and scans all
def moveAndScanAll
	i=0
	Dir.glob("*.pdf").each do |fil|
		puts "=============#{i}================".white
		puts "Scanning: '#{fil}'"
		toMove = renameAFile(fil)
		if toMove!=nil
			moveAFile(fil) #renames file to appropriate syntax, then moves that file to appropriate location
		end
		i= i + 1
		puts "=============================".white
	end
end

ex = 1
clientList = genClientList
while ex != 0
	puts "[1] List all Clients"
	puts "[2] List all Files in Directory"
	puts "[3] Scan & Rename all Clients"
	puts "[4] Move all Recognized Clients"
	puts "[5] 3 & 4"
	puts "[6] Exit"
	puts "What would you like to do?"
	case gets.chomp.to_i
		when 1
			clientList[0].printHead
			clientList.each { |cli| cli.print
				gets }
		when 2
			Dir.glob(".pdf").each{|ppp| puts ppp }
		when 3
			puts "not implemented yet!"
		when 4
			puts "not implemented yet!"
		when 5
			moveandScanAll
		when 6
			ex=0
			puts "bye bye!"
	end
end
