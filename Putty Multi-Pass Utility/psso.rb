#! usr/local/bin/ruby
## psso.rb
##
## Putty Multi-Password Single Sign-On Utility v1.0
##
## Tries a master list of credentials on a specified IP address via SSH and Telnet
## Initiates a putty session to the device if valid credentials are found
##
## Will take IP address as parameter if provided
##
## Author: Matthew Malyk

require 'net/ssh' ## requires net/ssh 2.9.3.beta1
require 'net/telnet'
require 'timeout'
require 'io/console'

##
##
## attempt to initiate SSH or telnet connection
##
## return:
## => success: credentials used as hash
## => failure: reason as string
##
##
def test_login(addr, login, flag)

	if flag == 'SSH'
		Net::SSH.start(addr, login[:user], :password => login[:pw], :timeout => 10, :number_of_password_prompts => 0)
	elsif flag == 'telnet'
		s = Net::Telnet::new("Host" => addr, "Timeout" => 20, "Prompt" => /.*[#>?]$/)
		s.waitfor(/name/)
		s.cmd('String' => login[:user], 'Match' => /[Pp]ass/)
		s.cmd(login[:pw]) { |c| return if c.include?("%") }
	end

rescue Net::SSH::AuthenticationFailed; return
rescue Errno::ETIMEDOUT, Timeout::Error; return "Failed: Timeout"
rescue Errno::ECONNREFUSED; return "Failed: Connection Refused"
rescue Errno::EHOSTUNREACH; return "Failed: Host Unreachable"
rescue Net::SSH::Disconnect
	puts "\n System locked out, retrying in 30 seconds"
	sleep(30)
	print " Continuing #{addr} via #{flag}"
	return
rescue; return "Failed: Unknown Error"
else print " Success!"; return login
end

##
##
## decrypt password input from SIM-CRY encryption script
##
## return: password string
##
##
def decrypt(pw,key)
	begin
		s="";(3..6).each{|i|s<<i.chr};val=1;key.chars.each{|e|val=(val+e.ord)/2}
		return pw.gsub('"','').split(/[#{s}]/).collect{|b|b.chars}.collect{|c|((c.map(&:ord).map(&:to_s).map{|e|e.rjust(2,'0')}.collect{|n|n[0]}.join.to_i)-val).chr}.join
	rescue RangeError; return nil
	end
end

##
## END METHOD DEFINITIONS
##

F_IN = 'config.ini'
F_OUT = 'log.txt'
File.write(F_OUT,'')

## preamble
puts "Putty Single Sign-On Utility - PuTTY-SSO v1.1"
puts "Using password list: #{F_IN}"

## KEXINIT Packet Length Fix
Net::SSH::Transport::Algorithms::ALGORITHMS[:encryption] = %w(aes128-cbc 3des-cbc blowfish-cbc cast128-cbc
aes192-cbc aes256-cbc none arcfour128 arcfour256 arcfour
aes128-ctr aes192-ctr aes256-ctr cast128-ctr blowfish-ctr 3des-ctr)

##
##
## pull logins, masterkey, and puttypath from config.ini
##
## store login as hash { :user => username, :pw => password, :name => reference name }
##
##
encr_key = ''; putty_path = ''; logins = []
File.foreach(F_IN) do |l|
	next unless l
	next if l[0] == '#'
	if l.include?(" // ")
		ls = l.chomp.split(" // ")
		logins << { :user => ls[0], :pw => ls[1], :name => ls[2] }
	elsif l.include?('MASTERKEY')
		encr_key = l.chomp.split(' : ').last
	elsif l.include?('PUTTYPATH')
		putty_path = l.chomp.split(' : ').last
		putty_path.prepend('"') unless putty_path[0] == '"'
		putty_path << '"' unless putty_path[-1] == '"'
	end
end

##
##
## request IP address from user unless provided as parameter
##
##
addr = ARGV[0]
puts "\nAttempting to log in to #{addr} (supplied via parameter)" unless addr == nil
until (/^\d+\.\d+\.\d+\.\d+$/).match(addr) 
	print "  Invalid IP" unless addr == nil
	print "\nDevice IP address: "; addr = gets.chomp
end

##
##
## request master key from user and compare against stored key
##
## use correct key to decrypt all other passwords stored in config.ini
##
##
MAX_TRIES = 3
usr_key = ''; mkey = ''; i = 0
until usr_key == mkey && usr_key.length > 0
	if i == MAX_TRIES
		puts "\nToo many incorrect password attempts"
		exit
	else
		print "\n  Invlaid Master Key" unless usr_key == ''
		print "\nPuTTY-SSO Master Key: "; usr_key = STDIN.noecho(&:gets).chomp
		mkey = decrypt(encr_key,usr_key)
		i+=1
	end
end

logins.each do |login| 
	login[:pw] = decrypt(login[:pw],mkey)
	logins.delete(login) if login[:pw] == nil
end


##
##
## try every set of supplied credentials on specified device
##
## if ssh connection is refused, retry via telnet
##
## results are logged in F_OUT for reference
##
##
print "\n\nTrying password list against #{addr} via SSH"

result = nil; flag = 'SSH'
loop do

	logins.each do |login|
		print '.'
		result = test_login(addr, login, flag)
		break if result
	end

	result = "#{flag} connection established but all supplied credentials failed" unless result


	## switch flag to telnet and retry if device responds but refuses SSH
	if result.include?('Refused') && flag == 'SSH'
		puts "\n\n#{result}"
		print "\nRetrying #{addr} via Telnet"
		File.open(F_OUT,'a') { |f| f.write("#{addr} via #{flag} reports \"#{result}\"\n") }
		result = nil; flag = 'telnet'
	else break
	end

end

##
##
## display error message and exit if all login attempts are unsuccessful
##
##
unless result.is_a?(Hash)
	puts "\n\n#{result}"
	puts "\nResults output to log.txt"
	sleep(2)
	print "\nExiting - "
	File.open(F_OUT, 'a') { |f| f.write("#{addr} via #{flag} reports \"#{result}\"\n") }
	system("pause")
	exit
end

##
##
## display credential reference name and prepare to launch PuTTY if successful
##
##
print "\n\nCredentials: "
if result[:name] then puts result[:name]
else puts "#{result[:user]} // #{result[:pw]}"
end

puts "\nLaunching PuTTY..."
if flag == 'SSH'
	sleep(2)
elsif flag == 'telnet'
	puts "  Manual login required for telnet."
	sleep(3)
end
puts "Results output to log.txt"
puts "You may safely close this window"

##
##
## output result to log.txt
##
## launch PuTTY and connect to device with successful credentials if SSH worked
## telnet login must be entered manually
##
##
begin
	File.open(F_OUT,'a') { |f| f.write("Successfully logged into #{addr} via #{flag} with credentials #{result[:name] ? result[:name] : result[:user]}\n") }
	exec "#{putty_path} -ssh #{result[:user]}@#{addr} -pw #{result[:pw]}" if flag == 'SSH'
	exec "#{putty_path} -telnet #{result[:user]}@#{addr}" if flag == 'telnet'	
rescue
	puts "  Failed to launch PuTTY.  Ensure PUTTYPATH is set correctly in #{F_IN}"
	pause(2)
	print "  Exiting - "
	system("pause")
	exit
end
