# -*- coding: utf-8 -*-
"""
Created on Sun Aug 13 08:08:13 2017

@author: SecureCRT
"""

# $language = "python"
# $interface = "1.0"

# This script shows how to read in a file, and it demonstrates how to
# perform some preprocessing on data (splitting the file data into 
# separate strings) before sending it to a server.

def main():
	# Open a file, read it in & send it one line at a time
	for line in open("c:\\temp\\printers.txt", "r"):
		# Split the line up. Each line should contain 3 space-separated parameters
		params = line.split()

		# params(0) holds parameter 1, params(1) holds parameter 2, etc.
		#
		# Send "mycommand" with the appended parameters from the file with
		# an appended CR.
		#
		crt.Screen.Send("mycommand " + params[0] + " " + params[1] + " " + params[2] + " " + '\r' )
		
		# Cause a 3-second pause between sends by waiting for something "unexpected"
		# with a timeout value.
		crt.Screen.WaitForString("something_unexpected", 3)

main()