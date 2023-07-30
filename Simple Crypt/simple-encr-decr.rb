## Author Matthew Malyk
##
## Weak encryption algorithm designed primarily to mask passwords from plain-text
## => This encryption is algorythmically complex enough to be secure without access to algorithm
## => This encryption is NOT secure against brute-force attacks
##
## Methodology:
##
## Takes in a string to encrypt and a key to decrypt with
## Encryption Algorithm
## => 1. Calculate unique number based on decryption key
## => 2. Shift int value of each string character by number from (1)
## => 3. Split each result into digits, multiply by 10 and add 1
## => 4. Convert each of these numbers back into ascii characters
## => 5. Join resulting characters into a single string
## => 6. Separate each character-representing-block with a set of randomized characters
##
## To decrypt, reverse the algorithm.


if ARGV[0] == 'e'

	## encrypt

	pw = "This is the pass"
	key = "K786sgjh3cd879jh3!"

	val = 1; key.chars.each {|e|val=(val+e.ord)/2}
	encr_pw = (pw.chars.map(&:ord).map{|e|e+val}.collect{|n|n.to_s.chars.collect{|c|(c<<'1').to_i}.push(rand(3..6)).map(&:chr).join}).unshift('"').join.gsub(/.$/,'"')
	
	puts encr_pw
	File.write('keyfile.txt',encr_pw)

elsif ARGV[0] == 'd'

	## decrypt

	key = "K786sgjh3cd879jh3!"
	encr_pw = File.read('keyfile.txt')

	s = ""; (3..6).each { |i| s <<  i.chr }; val = 1; key.chars.each {|e|val=(val+e.ord)/2}
	decr_pw = encr_pw.gsub('"','').split(/[#{s}]/).collect{|b|b.chars}.collect{|c|((c.map(&:ord).map(&:to_s).map{|e|e.rjust(2,'0')}.collect{|n|n[0]}.join.to_i)-val).chr}.join

	print decr_pw

end
