# $language = "python"
# $interface = "1.0"

# BSC_TDM_Distribuition.py
#
# Description:
#   This script will run all the commands required for the Toll BSC TDM
#   Distribuition and save the in a logfile, the list of BSC should be 
#   placed in the same folder of the output logfile
#
import os
import subprocess

LOG_DIRECTORY = os.path.join(os.path.expanduser('~'), 'Documents/Logs')

LOG_FILE_TEMPLATE = os.path.join(LOG_DIRECTORY, "Printout_BSC.txt")

BSCListPath = os.path.join(LOG_DIRECTORY, "BSCList.txt")

file = open(BSCListPath, mode = 'r')
BSC = file.read().split('\n')
del BSC[len(BSC)-1]

SCRIPT_TAB = crt.GetScriptTab()

# Defined a lista of commands will be taken from the node(s)

COMMANDS = ['CACLP;', 'NTCOP:SNT=ALL;', 'RRTPP:TRAPOOL=ALL;', 
#    'EXSCP:NAME=ALL;', 'RACIP:DETY=RALT;', 'RACIP:DETY=RBLT;', 
 #   'RACIP:DETY=RTLTT;', 'RACIP:DETY=RTLTB;', 'RACIP:DETY=RALT2;', 
  #  'RACIP:DETY=RBLT2;', 'RACIP:DETY=RTLTT2;', 'RACIP:DETY=RTLTB2;',
   # 'RXMOP:MOTY=RXOTG;', 'STDEP:DEV=RALT-0&&-20000;', 
    #'STDEP:DEV=RALT2-0&&-20000;', 'exit;'
	'exit;']

#TGS = []
 
#for (index, TG) in enumerate(list(range(1000))):
#    TGS.append('RXMOP:MO=RXOTG-' + str(TG) + ';')

#COMMANDS = COMMANDS + TGS
#COMMANDS += ['exit;']

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
def main():

    # Instruct WaitForString and ReadString to ignore escape sequences when
    # detecting and capturing data received from the remote (this doesn't
    # affect the way the data is displayed to the screen, only how it is handled
    # by the WaitForString, WaitForStrings, and ReadString methods associated
    # with the Screen object.
    SCRIPT_TAB.Screen.IgnoreEscape = True
    SCRIPT_TAB.Screen.Synchronous = True

    # Get the shell prompt so that we can know what to look for when
    # determining if the command is completed. Won't work if the prompt
    # is dynamic (e.g. changes according to current working folder, etc)
    rowIndex = SCRIPT_TAB.Screen.CurrentRow
    colIndex = SCRIPT_TAB.Screen.CurrentColumn - 1

    prompt = SCRIPT_TAB.Screen.Get(rowIndex, 0, rowIndex, colIndex)
    prompt = prompt.strip()
 
    for (index, BSCID) in enumerate(BSC):
        
        SCRIPT_TAB.Screen.Send('eaw ' + BSCID + '\r')

        for (index, command) in enumerate(COMMANDS):
            command = command.strip()

            # Set up the log file for this specific command
            logFileName = LOG_FILE_TEMPLATE.replace('BSC', BSCID)
		
            # Send the command text to the remote
            SCRIPT_TAB.Screen.Send(command + '\r')

            # Wait for the command to be echo'd back to us.
            SCRIPT_TAB.Screen.WaitForString('\r', 1)            
            SCRIPT_TAB.Screen.WaitForString('<', 1)         
            #SCRIPT_TAB.Screen.WaitForString('\n', 1)

            # Use the ReadString() method to get the text displayed while
            # the command was runnning.  Note also that the ReadString()
            # method captures escape sequences sent from the remote machine
            # as well as displayed text.  As mentioned earlier in comments
            # above, if you want to suppress escape sequences from being
            # captured, set the Screen.IgnoreEscape property = True.

            result = SCRIPT_TAB.Screen.ReadString(prompt)
            result = result.strip()
            
            #result.append(result)
		
        filep = open(logFileName, 'wb+')

        # If you don't want the command logged along with the results, comment
        # out the very next line
        filep.write("Results of command: " + command + os.linesep)
        
        # Write out the results of the command to our log file
        filep.write(result + os.linesep)
		
        # Close the log file
        filep.close()

main()