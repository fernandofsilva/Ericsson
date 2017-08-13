# -*- coding: utf-8 -*-
"""
Created on Sun Aug 13 08:10:39 2017

@author: SecureCRT
"""

# $language = "python"
# $interface = "1.0"

# Use CRT's script object Rows and Columns properties to send settings
# for the LINES and COLUMNS environment variables when these variables
# aren't being set properly by the remote system.

def main():
	lines = crt.Screen.Rows
	cols = crt.Screen.Columns

	# send bourne shell/korn shell command
	#
	# crt.Screen.Send("export LINES=" + str(lines) + " COLUMNS=" + str(cols) + '\r')

	# send csh shell command
	#
	crt.Screen.Send("setenv LINES " + str(lines) + "; setenv COLUMNS " + str(cols) + '\r')


main()