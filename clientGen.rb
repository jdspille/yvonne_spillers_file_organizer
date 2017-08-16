#!/usr/bin/ruby
class Client
	attr_accessor :firstName, :lastName, :email, :phone, :altPhone, :altName, :address,:folderLoc
	def print
		printf("%-20.20s, %-20.20s | %-20.20s | %-20.20s | %-20.20s\n", lastName, firstName, email, phone, address, folderLoc )
	end
	def printHead
		printf("%-20s, %-20.20s | %-20.20s | %-20.20s | %-20.20s | %-20.20s\n", "Last Name", "First Name", "Email", "Phone", "Address", "Folder Location")
	end
end

clientList = Array.new
counter = 0
file = File.new("l.csv","r")  
	while(line = file.gets)
		if line != nil
			puts "Loading new client..."
			temp = Client.new
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
clientList.each do |cli|
	cli.print
end
