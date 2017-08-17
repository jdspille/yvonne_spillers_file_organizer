require 'fileutils'
require 'date'
require 'pdf-reader'

##############CLIENT GENERATION###################
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
	clientList.each do |cli|
			if cli.folderLoc == nil || cli.folderLoc == " "
					clientList.delete(cli)
			end
	end
return clientList
end


##############SCANNER##############################
def scanFile (doc) #return true on sucess, false on failure
  calendar = ["fakeuary", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
  typesOf = ["Contempt Hearing", "MEDIATION ORDER", "WAIVER OF", "MEDIATOR'S REPORT TO", "PROBATION RELEASE", "CONTEMPT", "Worksheet - ", "New Client Intake", "INCOME WITHHOLDING","MODIFY CHILD SUPPORT", "PRODUCTION OF DOCUMENTS","Property Settlement Agreement", "QUALIFIED DOMESTIC RELATIONS ORDER", "ACKNOWLEDGEMENT","APPEARANCE", "DISSOLUTION", "NOTICE", "TEMPORARY RESTRAINING", "DEPOSITION","ORDER OF THE", "MOTION", "PROVISIONAL ORDERS", "STIPULATION", "SUBPOENA", "AFFIDAVIT", "CONTINUANCE", "SETTLEMENT", "WAIVER OF FINAL HEARING"]
	#set variables
	count = 0
	curPage=0
	cfound=false
	mfound=false
	tfound=false
  clientList = genClientList
	reader = PDF::Reader.new(doc) #create a scraper for new PDF

	reader.pages.each do |page| #for every page
			##Document Scanning##
			page.text.each_line do |ptr| #for every line in #page

					##LOOK FOR NAME
		       if !cfound then #only scan if unknown
                clientList.each do |cli| #check if client name
			if ptr.downcase.include?cli.downcase then
                    last = cli.chomp
                    cfound=true
			break
                  end
                end
              end
							##LOOK FOR DATE
              if !mfound then #only scan if unknown
                calendar.each do |mon| #check if date
			if ptr.include?mon then
				begin
					longDate = /\w+ \d{,2},* \d{4}/.match(ptr).to_s
					date = DateTime.parse(longDate).strftime("20%y.%m.%d")
					mfound=true
				rescue
					begin
						longDate = /\/\d{,2}\/\d{,2}\/\d{4}/.match(ptr).to_s
						date = DateTime.parse(longDate).strftime("20%y.%m.%d")
						mfound = true
					rescue
					end
				end
				break
                  end
                end
              end
							##LOOK FOR TYPE
              if !tfound then #only scan if unknown
                typesOf.each do |typ|
            			if ptr.include?typ then
                    type=ptr[ptr.index(typ),ptr.length].lstrip.chomp #cut away nonsense
            				type=type.gsub('\n','').gsub('\t','').gsub(/[^0-9A-Za-z ]/,"").gsub(/ +/, " ")
            				type=type.split(/(\W)/).map(&:capitalize).join #put to sentence case
            				tfound = true
            				type=type[0..50].chomp
            				break
            			end
                end
              end
      end
		end
		if last == nil then
      return false
		else
        fullName = "#{last} #{date} #{type}"
	      File.rename(doc, "../" + fullName + ".pdf")
        return true
		end
end

#############MOVER################################
##return true on sucess, false on failure
def moveFile (clientList, fileToMove) #@fileToMove taken in format "Spillers 0.0.0 Depo.pdf"
	clientList = genClientList
	daSpace = fileToMove.index(' ')
	if daSpace != nil then
		#There is a space!
		clientList.each do |cli|
			if fileToMove[0, daSpace].downcase == cli.LastName.downcase then
				FileUtils.mv("#{fileToMove}","#{cli.folderLoc}", :force => true)
				return true
				break
			end
		end
	else
		return false
	end
end
#############END################################
Shoes.app do
   stack margin: 0.1 do
     @titlepop = title "Starting Up"
     @verbose = edit_box width: 200, height: 100
     @p = progress width: 1.0
     scannable = 0
     totalToProcess = 0
     progression = 0


     Dir["../*.pdf"].each do |a| #returns number of docs to be processed
       if a.include("Sharp")
         scannable = scannable + 1
       end
       totalToProcess = totalToProcess + 1
     end

     ##SCAN
    @titlepop.text = "Scanning Documents..."
     Dir["../Sharp*.pdf"].each do |doc| #for every scanned, unnamed file
       winner = scanFile(doc)? "+" : "-"
       @verbose.text = "#{winner} : #{doc}\n" + @verbose.text
       @p.fraction = progression / (totalToProcess+scannable)
       progression = progression + 1
     end
     ##MOVE
    @titlepop.text = "Moving Documents..."
    Dir["../*.pdf"].each do |doc| #for every scanned, unnamed file
      winner = moveFile(doc)? "+" : "-"
      @verbose.text = "#{winner} : #{doc}\n" + @verbose.text
      @p.fraction = progression / (totalToProcess+scannable)
      progression = progression + 1
    end
    alert("Complete!")
 end
end
