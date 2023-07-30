#! usr/local/bin/ruby
## sim_cry.rb
##
## Simple Crypt Utility plain-text password encryptor - v1.0
##
## Weak encryption algorithm designed primarily to mask passwords in plain-text config file
## => This encryption is algorythmically complex enough to be secure without access to algorithm
## => This encryption is NOT secure against brute-force attacks
##
## Takes in a password-string and a master key
## Applies a six-step mathematical cipher to password-string
## Ciper is uniquely generated based on key value
## Outputs encrypted string to clipboard
##
## Author: Matthew Malyk

require 'io/console'

begin
	puts "Generates encrypted string to be used in place of your password for plain-text input files"
	puts "All inputs will be hidden"

	key = nil; rekey = ''
	until key == rekey && key != ''
		puts "\nKeys do not match.  Please try again." unless key == nil
		print "\nEnter Master Key: "; key = STDIN.noecho(&:gets).chomp
		print "\nRe-enter Master Key: "; rekey = STDIN.noecho(&:gets).chomp
	end

	loop do
		pw = nil; repw = ''
		until pw == repw && pw != ''
			puts "\n\n    Passwords do not match.  Please try again." unless pw == nil
			print "\n\n**Leave blank to encrypt Master Key**"
			print "\n Password to be encrypted: "; pw = STDIN.noecho(&:gets).chomp
			if pw == '' then break
			else print "\n Re-enter password to be encrypted: "; repw = STDIN.noecho(&:gets).chomp
			end
		end

		usr = nil; ref = nil
		if pw == '' then pw = key
		else
			print "\n\n  Enter username: "; usr = gets.chomp
			print "  Enter reference name: "; ref = gets.chomp
		end

		val = 1; key.chars.each {|e|val=(val+e.ord)/2}
		encr_pw = (pw.chars.map(&:ord).map{|e|e+val}.collect{|n|n.to_s.chars.collect{|c|(c<<'1').to_i}.push(rand(3..6)).map(&:chr).join}).unshift('"').join.gsub(/.$/,'"')
		
		puts "\n\nPassword successfully encrypted!\n\n    Output string copied to clipboard."
		if usr == nil then system("echo MASTERKEY : #{encr_pw}| clip")
		else system("echo #{usr} // #{encr_pw} // #{ref} | clip")
		end
		sleep(2)
		print "\n\nEncrypt another password with the same key? [Y]/n: "
		if gets.chomp == 'n'
			puts "\n\nExiting.."
			sleep(5)
			exit
		end
	end


rescue
	puts "\n\nSomething went wrong!"
	puts "Terminating application for security.."
	sleep(5)
end