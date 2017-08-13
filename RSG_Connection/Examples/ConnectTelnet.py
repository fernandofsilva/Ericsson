# -*- coding: utf-8 -*-
"""
Created on Sun Aug 13 07:18:45 2017

@author: SecureCRT
"""

# $language = "Python"
# $interface = "1.0"

# Connect to a telnet server and automate the initial login sequence.
# Note that synchronous mode is enabled to prevent server output from
# potentially being missed.

def main():

	crt.Screen.Synchronous = True

	# connect to host on port 23 (the default telnet port)
	#
	crt.Session.Connect("/TELNET login.myhost.com 23")

	crt.Screen.WaitForString("ogin:")
	crt.Screen.Send("myusername\r")

	crt.Screen.WaitForString("assword:")
	crt.Screen.Send("mypassword\r")

	crt.Screen.Synchronous = False


main()