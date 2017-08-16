require 'pdf-reader'
require 'colorize' 
require 'date'
typf=0
monf=0
clif=0
clientList = File.readlines('./clients.csv')
calendar = ["fakeuary", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
typesOf = ["Contempt Hearing", "MEDIATION ORDER", "WAIVER OF", "MEDIATOR'S REPORT TO", "PROBATION RELEASE", "CONTEMPT", "Worksheet - ", "New Client Intake", "INCOME WITHHOLDING","MODIFY CHILD SUPPORT", "PRODUCTION OF DOCUMENTS","Property Settlement Agreement", "QUALIFIED DOMESTIC RELATIONS ORDER", "ACKNOWLEDGEMENT","APPEARANCE", "DISSOLUTION", "NOTICE", "TEMPORARY RESTRAINING", "DEPOSITION","ORDER OF THE", "MOTION", "PROVISIONAL ORDERS", "STIPULATION", "SUBPOENA", "AFFIDAVIT", "CONTINUANCE", "SETTLEMENT", "WAIVER OF FINAL HEARING"]
##Load Clients into List
clientList.each do |cli|
	cli.replace(cli[/[^,]+/])
end
puts "Clients Loaded!".green
numRec = 0

Dir["../Sharp*.pdf"].each do |doc| #for every file
	puts doc #show current file editing, remove on final revision!
	#set variables
	last = "fake"
	date = "fake"
	type = "fake"
	continue = 'Y'
	count = 0
	curPage=0
	cfound=false
	mfound=false
	tfound=false

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
		    puts "-----> Found Client #{cli}".yellow
			clif+=1							
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
						puts "-----------> Date not recognized".yellow
						puts "-----------> Trying XX/XX/XXXX".blue
						longDate = /\/\d{,2}\/\d{,2}\/\d{4}/.match(ptr).to_s
						date = DateTime.parse(longDate).strftime("20%y.%m.%d")
						mfound = true
					rescue
						puts "No Date Found".red
					end
				end
				puts "-----> Found Month #{mon}".yellow
				puts "-----------> #{date}".yellow
				monf+=1
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
				puts "-----> Found Type #{type}".yellow						
				typf+=1
				break
			end
                end
              end
      end
		end
		if last == "fake" || date == "fake" || type == "fake" then
			puts "NOT ALL INFO FOUND : : skipping....".red
		else
    	fullName = last << " " << date << " " << type
	puts "Parsed Input: #{fullName}".green
    	#print "is this correct?"
    	#continue = gets.chomp
    	#if continue == 'N' || continue == 'n' then
			#		puts "skipping...."
			#else
	File.rename(doc, "../" + fullName + ".pdf")
	numRec+= 1
			#end
		end
		puts "\n======================================================================================\n".light_black
end
print "| #{numRec}".white
print " Files Recognized Using Spillers's OCR Tool! |\n\n".cyan
puts "#{clif} Clients, #{monf} dates, #{typf} types"
