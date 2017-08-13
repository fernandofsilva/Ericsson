# -*- coding: utf-8 -*-
"""
Created on Sun Aug 13 08:13:20 2017

@author: SecureCRT
"""

# $language = "python"
# $interface = "1.0"

def main():
	# Send the unix "date" command and wait for the prompt that
	# indicating that it completed. In general we want to be in
	# synchronous mode before doing send/wait operations.
	#
	crt.Screen.Synchronous = True
	crt.Screen.Send("date\r")

	promptString = "linux$"
	crt.Screen.WaitForString(promptString)

	# When we get here the cursor should be one line below the output of
	# the 'date' command. Subtract one line and use that value to read a
	# chunk of text (1 row, 40 characters) from the screen.
	# 
	screenrow = crt.Screen.CurrentRow - 1
	result = crt.Screen.Get(screenrow, 1, screenrow, 40)

	# Get() reads a fixed size of the screen. So you may need to use a
	# regular expression function or the str.split() method to do some
	# simple parsing if necessary. Just print it out here.
	#
	crt.Dialog.MessageBox(result)
	crt.Screen.Synchronous = False

main()