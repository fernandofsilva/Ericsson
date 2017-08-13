# -*- coding: utf-8 -*-
"""
Created on Sun Aug 13 08:09:24 2017

@author: SecureCRT
"""

# $language = "python"
# $interface = "1.0"

# A Python login script that waits for a login prompt then sends
# a 'setenv DISPLAY <ipaddress>:0.0' command to direct X-clients to a
# locally run Xserver.


def main():

	crt.Screen.WaitForString("myhost$ ")

	display = "setenv DISPLAY " + crt.Session.LocalAddress + ":0.0\r"
	crt.Screen.Send(display)
	

main()