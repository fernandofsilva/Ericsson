#%%
# Load Libraries and functions
import pandas as pd
import sys

sys.path.append('/home/esssfff/Documents/Git/Ericsson/GSM/')

# Import Custom Functions
import GSM_TDM_Functions as cf

# Default file path
path = "/home/esssfff/Documents/"

# Read external files
input_data = pd.read_csv(path + 'precutCsvNodes_CLARO.csv',
                         skiprows=1,
                         names=['customer', 'region', 'nodename', 
                                'nodeController_dest'])

reparting_g_nodes  = pd.read_excel(path + 'Reparenting_G_Nodes.xlsx')

tg_planning = pd.read_excel(path + 'TG_Planning.xlsx')

# Reading MoView data
site_list = cf.ReadNetwork()

# Merge the two tables 
data = pd.merge(left=input_data, 
               right=site_list, 
               how='left',
               on=['nodename'])

# Fill with 'Not_Find' sites were not find in the Network
data = data.fillna('Not_Find')

# Split the table between sites DU and BB and Not_Find
diff = data.loc[((data['model'] != 'DU') | 
                 (data['nodeController_dest'] == data['nodeController_orig']))]
data = data.loc[((data['model'] == 'DU') & 
                 (data['nodeController_dest'] != data['nodeController_orig']))]

# Remove unused columns
diff = diff.drop(['customer', 'region', 'rsite'], axis=1)

# Get BSC List
bsc_list = data['nodeController_orig'].unique()

# Iterate over bsc_list and return rrscp
rrscp = pd.DataFrame()

for bsc in bsc_list:
       rrscp = rrscp.append(cf.GetRRSCP(bsc, 
                                        data, 
                                        reparting_g_nodes, 
                                        tg_planning))

# Append sites already migrated to BB
rrscp = rrscp.append(diff)

# Reorder dataframe
rrscp = rrscp[['nodeController_orig', 'nodeController_dest', 'nodename', 
               'scgr', 'sc', 'dev1', 'dcp', 'numdev', 'model', ]]

rrscp = rrscp.sort_values(['nodeController_orig', 'nodename', 'scgr'])

# Save file to csv
rrscp.to_csv(path + 'output.csv', 
             index=False, 
             sep=';',
             float_format='%.0f')d