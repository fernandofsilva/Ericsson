# -*- coding: utf-8 -*-
"""
Created on Sun Aug 13 08:16:17 2017

@author: SecureCRT
"""

# $language = "python"
# $interface = "1.0"

# This script demonstrates how to capture line by line output from a
# command sent to a server. It then saves each line of output to a file.
# This script shows how the 'WaitForStrings' command can be used to wait
# for multiple possible outputs.

import os

def main():

	crt.Screen.Synchronous = True

	# Open a file for writing.
	#
	filename = os.path.join(os.environ['TEMP'], 'output.txt')
	fp = open(filename, "wb+")

	# Send the initial command then throw out the first linefeed that we
	# see by waiting for it.
	#
	crt.Screen.Send("./a.out\n")
	crt.Screen.WaitForString("\n")

	# Create an array of strings to wait for.
	#
	promptStr = "linux$"
	waitStrs = ["\n", promptStr]

	row = 1

	while True:

		# Wait for the linefeed at the end of each line, or the shell
		# prompt that indicates we're done.
		#	
		result = crt.Screen.WaitForStrings( waitStrs )

		# If we saw the prompt, we're done.
		if result == 2:
			break

		# The result was 1 (we got a linefeed, indicating that we
		# received another line of of output). Fetch current row number
		# of the cursor and read the first 20 characters from the screen
		# on that row. 
		# 
		# This shows how the 'Get' function can be used to read
		# line-oriented output from a command, Subtract 1 from the
		# currentRow to since the linefeed moved currentRow down by one.
		# 
		screenrow = crt.Screen.CurrentRow - 1
		readline = crt.Screen.Get(screenrow, 1, screenrow, 20)

		# NOTE: We read 20 characters from the screen 'readline' may
		# contain trailing whitespace if the data was less than 20
		# characters wide.

		# Write the line out with an appended end-of-line sequence
		fp.write(readline + os.linesep)

	crt.Screen.Synchronous = False


main()