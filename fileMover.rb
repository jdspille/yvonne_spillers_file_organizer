require 'fileutils'
class Client
	attr_accessor :firstName, :lastName, :folderLoc
end

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
