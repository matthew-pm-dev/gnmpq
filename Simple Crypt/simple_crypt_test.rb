#! usr/local/bin/ruby
## App that generates a simple encrypted password string for use with telnet app

require 'io/console'

=begin
begin
	puts "Generates a key to be used in place of your password for plain-text input files"
	print "Password (will be hidden): "
	e = [STDIN.noecho(&:gets).chomp].pack("u").chomp
	puts "\n\nEncrypted password string: #{e} copied to clipboard."
	system("echo #{e}| clip")
rescue
	puts "\n\nSomething went wrong"
	exit
end
=end

begin
	puts "Generates encrypted string to be used in place of your password for plain-text input files"
	puts "All inputs will be hidden"
	print "\nPassword to be encrypted: "; pw = STDIN.noecho(&:gets).chomp
	print "\nMaster password: "; key = STDIN.noecho(&:gets).chomp

	val = 1; key.chars.each {|e|val=(val+e.ord)/2}
	encr_pw = (pw.chars.map(&:ord).map{|e|e+val}.collect{|n|n.to_s.chars.collect{|c|(c<<'1').to_i}.push(rand(3..6)).map(&:chr).join}).unshift('"').join.gsub(/.$/,'"')
	
	puts "\n\nEncrypted password string:\n#{encr_pw}\nCopied to clipboard."
	system("echo #{encr_pw}| clip")
rescue
	puts "\n\nSomething went wrong"
	exit
end