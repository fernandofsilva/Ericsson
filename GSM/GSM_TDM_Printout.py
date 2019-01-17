#%%
# Default file path
filepath = "/home/esssfff/Documents/Logs_gsm/BSCRJ37_Logs_RJITG08.log"

with open(filepath, "r") as f:
    log = f.read()

#%%
# Import regular expression module
import re

# Split the filepath variable and get the site name
id = re.split(r"/|_|\.", filepath)
bsc_name = id[-4]
site_name = id[-2]

#%%
def FindTGBlock(log):
    """
    Argument:
    string -- str object contain the text to look for the RXAPP:MO=XXXX; and
    separate in blocks
    
    Returns:
    tgs -- list contain the blocks for each tg
    """
    
    # Initialize the list
    tgs = []
    
    # Define the pattern and search for TGs in the RXAPP log
    pattern = re.compile(r"(?s)(RXAPP:MO=RXOTG-\d+)(.*?)(END)")

    # Look the pattern in the str object and get 
    matches = pattern.finditer(log)

    # Split the text and separete the blocks in the list
    for match in matches:
        start, end = match.span()
        start = start + 67 # Added 67 chracters to excluded the header 
                           # of the command
        tgs.append(log[start:end])

    return tgs

def FindTGNumber(block_list):
    """
    Argument:
    List -- List of blocks of rxapp
    
    Returns:
    tg_list -- list of tgs numbers
    """
    
    # Initialize the list
    tg_list = []
    
    # Define the pattern and search for TGs in the RXAPP blocks
    pattern = re.compile(r"(RXOTG-)(\d+)")

    # Look the pattern in the str object and return the match
    for block in block_list:
        match = pattern.search(block) # Look for a match according the pattern
        
        tg = int(match.group(2))      # In the match call the method group
                                      # to the return the number matched
        
        tg_list.append(tg)            # Append it to a list

    return tg_list

def FindDevDCP(block_list):
    """
    Argument:
    List -- List of blocks of rxapp
    
    Returns:
    type_list -- list of lists contain the Devices Type RBLT = 1, RBLT2 = 2 
    dev_list  -- list of lists contain the Devices numbers 
    dcp_list  -- list of lists contain the DCP numbers to each TG
    """
    
    # Initialize the lists
    type_list = []
    dev_list  = []
    dcp_list  = []
    
    # Define the pattern and search for TGs in the RXAPP blocks
    pattern = re.compile(r"(RBLT2?)-(\d+)(.*?)(\d+)")

    # Look the pattern in the str object and return the match
    for block in block_list:
        match = pattern.findall(block) # Look for a match according the pattern
        
        type = [ 1 if x[0] == "RBLT" else 2 for x in match ]  # In the match 
        dev  = [int(x[1]) for x in match]                     # subset the
        dcp  = [int(x[3]) for x in match]                     # tuple and get 
                                                              # the specific
                                                              # value

        type_list.append(type)        # Append it to a list
        dev_list.append(dev)
        dcp_list.append(dcp)

    return type_list, dev_list, dcp_list

def FindTRX(log):
    """
    Argument:
    str object contain the text to look for the RXMOP:MO=RXOTRX
    
    Returns:
    tg_list   -- list contain the TG of each TRX 
    trx_list  -- list contain the TRXs of each TG
    cell_list -- list contain the cell of each TRX
    """
    
    # Initialize the lists
    tg_list   = []
    trx_list  = []
    cell_list = []
    
    # Define the pattern and search for TGs in the RXAPP blocks
    pattern = re.compile(r"(RXOTRX-)(\d+)-(\d+)(.*?)([\w|\d]{}\d)".format(site_name[2:]))

    # Look the pattern in the str object and return the match
    match = pattern.findall(log)       # Look for a match according the pattern
        
    tg    = [int(x[1]) for x in match] # In the match subset the tuple and get
    trx  = [int(x[2]) for x in match]  # the specific value
    cell = [x[4] for x in match]

    tg_list.append(tg)                 # Append it to a list
    trx_list.append(trx)
    cell_list.append(cell)

    return tg_list[0], trx_list[0], cell_list[0]

# Extract the RXAPP:MO=RXOTG?; commands from the log
rxapp_blocks = FindTGBlock(log)

# For each block of RXAPP extract the TG, Dev Type, Dev Number and DCP
tg = FindTGNumber(rxapp_blocks)
type, dev, dcp = FindDevDCP(rxapp_blocks)

# Function for extract the containt of RXMOP:MO=RXOTRX?;
tg_list, trx_list, cell_list = FindTRX(log)

#%%
import numpy as np

tg_list = np.array((tg_list))
trx_list = np.array((trx_list))
cell_list = np.array((cell_list))

rxotrx = np.column_stack([tg_list, trx_list, cell_list])

print(rxotrx.dtype)

#%%

for i in range(0, 20):
    x = np.random.randint(low=1, high=60, size=(6,))
    print(np.sort(x))
#%%
