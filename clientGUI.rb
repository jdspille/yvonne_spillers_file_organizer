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


clientList = genClientList
lastNames = Array.new
clientList.each do |cli|
	lastNames.push("#{cli.lastName}, #{cli.firstName}")
end
Shoes.app do

	flow do
		@title = para "Client List:"
		@nameList = list_box items: lastNames
	end

	#lastName, firstName, email, phone, address, folderLoc
	flow do
		para "Last Name:"
		@curLastName = edit_line
		button "Change"
	end
	flow do
		para "First Name:"
		@curFirstName = edit_line
		button "Change"
	end
	flow do
		para "Email:"
		@curEmail = edit_line
		button "Change"
	end
	flow do
		para "Phone:"
		@curPhone = edit_line
		button "Change"
	end
	flow do
		para "Address:"
		@curAddress = edit_line
		button "Change"
	end
	flow do
		para "Folder Location:"
		@curFolder = edit_line
		button "Change"
	end


	@nameList.change do |option|
		selectedName = option.text
		lastName = selectedName[0,selectedName.index(",")]
		inList = clientList.find {|s| s.lastName == lastName}
			@curLastName.text = inList.lastName
			@curFirstName.text = inList.firstName
			@curEmail.text = inList.email
			@curPhone.text = inList.phone
			@curAddress.text = inList.address
			@curFolder.text = inList.folderLoc
	end
end
