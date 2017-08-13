# -*- coding: utf-8 -*-
"""
Created on Sun Aug 13 08:08:41 2017

@author: SecureCRT
"""

# $language = "python"
# $interface = "1.0"

# This script demonstrates one way to send a text file to a unix server
# This is equivalent to doing an "send ASCII" in a script.


def main():

	# Send a 'cat' command to direct everything we are about to send into a file.
	#
	crt.Screen.Send("cat > output.txt" + '\r')

	# The next line causes the script to wait until the 'cat' command has been 
	# sent (and executed) by the server. So that the data we're about to send
	# doesn't get sent until redirected 'cat' command is actually in effect.
	#
	crt.Screen.WaitForString("output.txt")

	# Send the file a line at a time.
	# Note: A IOError exception will be generated if 'myfile.txt' doesn't exist.
	#
	for line in open("c:\\temp\\myfile.txt", "r"):
		crt.Screen.Send(line)

	# send an EOF character to end output to terminate 'cat'
	#
	crt.Screen.Send("\004")


main()