#%%
# Load Libraries and functions
from sqlalchemy import (create_engine, Table, Column, Integer, String, 
                        MetaData, select, or_, and_)

import pandas as pd
import numpy as np
import math

def ReadNetwork():
    """
    Argument:
    None -- Function call
    
    Returns:
    pandas dataframe -- network batch with all sites
    """
    
    # Create Engine
    engine = create_engine('mssql+pyodbc://mv_claro:claro@MoviewClaro')

    # Selection RXOTG data from RXMOP data base
    rxotg = Table('RXMOP', MetaData(),
                  Column('nodeLabel', String(10)), 
                  Column('RSITE', String(10)), 
                  Column('MOTY', String(10))
                  )
    stmt = select([rxotg]).where(or_(rxotg.columns.MOTY == 'RXOTG',
                                 rxotg.columns.MOTY == 'RXSTG')
                             ).distinct()
    results = engine.connect().execute(stmt).fetchall()

    # Convert to pandas DataFrame
    rxotg = pd.DataFrame(results)

    # Format Table
    rxotg.columns = ['nodeController_orig', 'rsite', 'model']
    rxotg = rxotg.replace({'RXOTG': 'DU', 'RXSTG': 'BB'})
    rxotg['nodename'] = (rxotg['nodeController_orig'].apply(lambda row: row[3:5])
                       + rxotg['rsite'].apply(lambda row: row[-5:]))
    
    # Remove duplicated values
    rxotg = rxotg.sort_values(
    by=['model', 'nodename']).drop_duplicates(
        subset=['nodename'], keep='first')
    
    return rxotg

def ReadRXAPP(bsc):
    """
    Argument:
    String -- String with the BSC name
    
    Returns:
    pandas dataframe -- dataframe with RXAPP:MOTY=RXOTG;
    """
    
    # Create Engine
    engine = create_engine('mssql+pyodbc://mv_claro:claro@MoviewClaro')

    # Selection RXOTG data from RXMOP data base
    rxapp = Table('RXAPP', MetaData(),
              Column('nodeLabel', String(10)),
              Column('TG', Integer), 
              Column('DEV', String(10)),
              Column('DCP', Integer)
              )
    stmt = select([rxapp]).where(rxapp.columns.nodeLabel == bsc).distinct()
    results = engine.connect().execute(stmt).fetchall()

    # Convert to pandas DataFrame
    rxapp = pd.DataFrame(results)

    # Add column names and drop unused columns
    rxapp.columns = ['nodeController', 'tg', 'dev', 'dcp']
    
    # Remove tgs without dev assigned
    rxapp = rxapp.dropna()
    
    # Converte columns to integer type
    rxapp[['tg', 'dcp']] = rxapp[['tg', 'dcp']].astype(int)
   
    return rxapp

def ReadRXOTRX(bsc):
    """
    Argument:
    String -- String with the BSC name
    
    Returns:
    pandas dataframe -- dataframe with RXMOP:MOTY=RXOTRX;
    """
    
    # Create Engine
    engine = create_engine('mssql+pyodbc://mv_claro:claro@MoviewClaro')

    # Selection RXOTG data from RXMOP data base
    rxotrx = Table('RXMOP', MetaData(),
              Column('nodeLabel', String(10)),
              Column('TG', Integer), 
              Column('TRX', Integer),
              Column('CELL', String(10)),
              Column('MOTY', String(10))
              )
    stmt = select([rxotrx]).where(and_(rxotrx.columns.MOTY == 'RXOTRX',
                                       rxotrx.columns.nodeLabel == bsc)
                                  ).distinct()
    results = engine.connect().execute(stmt).fetchall()

    # Convert to pandas DataFrame
    rxotrx = pd.DataFrame(results)

    # Add column names and drop unused columns
    rxotrx.columns = ['nodeController', 'tg', 'trx', 'cell', 'moty']
    rxotrx = rxotrx.drop(['nodeController', 'moty'], axis=1)
    
    # Converte columns to integer type
    rxotrx[['tg', 'trx']] = rxotrx[['tg', 'trx']].astype(int)
   
    return rxotrx

def ReadRXMOP(bsc):
    """
    Argument:
    String -- String with the BSC name
    
    Returns:
    pandas dataframe -- dataframe with RXMOP:MOTY=RXOTG;
    """
    
    # Create Engine
    engine = create_engine('mssql+pyodbc://mv_claro:claro@MoviewClaro')

    # Selection RXOTG data from RXMOP data base
    rxotg = Table('RXMOP', MetaData(),
                  Column('nodeLabel', String(10)), 
                  Column('RSITE', String(10)), 
                  Column('TG', Integer),
                  Column('MOTY', String(10))
                  )

    stmt = select([rxotg]).where(and_(rxotg.columns.MOTY == 'RXOTG',
                                 rxotg.columns.nodeLabel == bsc)
                             ).distinct()

    results = engine.connect().execute(stmt).fetchall()

    # Convert to pandas DataFrame
    site = pd.DataFrame(results)

    # Format Table
    site.columns = ['nodeController', 'rsite', 'tg', 'moty']
    site = site.drop('moty', axis=1)
    site[['tg']] = site[['tg']].astype(int)
    site = site.sort_values(by=['nodeController', 'tg'])

    return site

def DCPPort(DCP):

    """
    Argument:
    Number -- DCP number
    
    Returns:
    String -- String with DUG Port (A, B, C or D)
    """

    # Define the range to each port
    rangeA = list(range(1, 32))
    rangeB = list(range(33, 64))
    rangeC = list(range(287, 318))
    rangeD = list(range(319, 350))
    # Concatenate the list
    range_total = rangeA + rangeB + rangeC + rangeD

    # Check the DCP Number is inside the values
    assert DCP in range_total

    if DCP >= 1 and DCP <= 31:
        return 1
    elif DCP >= 33 and DCP <= 63:
        return 33
    elif DCP >= 287 and DCP <= 317:
        return 287
    else:
        return 319

def DevRange(DEV):

    """
    Argument:
    String -- String with the device, e.g. RBLT2-1570
    
    Returns:
    Tupple -- Tupple with Dev Type, Initial Dev, Dev Range
    """

    dev_type, dev_number = DEV.split('-')

    dev_ini = (((math.ceil(int(dev_number)/32)*32)-2)-30)
    dev_end = ((math.ceil(int(dev_number)/32)*32)-1)

    dev_range = dev_type + '-' + str(dev_ini) + '&&-' +str(dev_end)

    return dev_type, dev_ini, dev_range

def Summarise(rxapp):
    """
    Argument:
    pandas dataframe -- pandas dataframe contain rxapp from moview
    
    Returns:
    pandas dataframe -- original dataframe plus numdev column
    """

    summarise_count = rxapp.groupby(['tg_port'], as_index=False)['dev'].count()
    summarise_count.columns = ['tg_port', 'numdev']

    rxapp = pd.merge(left=rxapp, 
                     right=summarise_count, 
                     how='left',
                     on=['tg_port']
                     )
    rxapp = rxapp.sort_values(['tg', 'dcp'])
    
    return rxapp

def SuperChannel(rxapp):
    """
    Argument:
    list -- Pandas Series with the list of Tgs
    
    Returns:
    list -- Pandas Series with the SC to each Tg
    """

    rxapp = rxapp.sort_values(['tg', 'dev_type', 'dev_ini'])

    rxapp = rxapp.groupby(['tg'])['tg'].rank(method='first')
    rxapp = rxapp.map({4:3,
                       3:2,
                       2:1,
                       1:0})

    return rxapp

def Numdev(numdev_list):
    """
    Argument:
    list -- List of numdev to each tg
    
    Returns:
    list -- Ajusted numdev to each tg with the maximum of 31 TS
    """

    # Check if the numdev_list already contain 31 TS and return the original
    # list if it contains 31 TS
    if sum(numdev_list) == 31:
        return numdev_list
    
    # Loop over the list adding TS to each TG randomly until the list 
    # contain 31 TS
    while sum(numdev_list) < 31:
        rand = np.random.randint(low=0, high=len(numdev_list), size=1)[0]
        numdev_list[rand] += 1
    
    # Loop over the list removing TS to each TG randomly until the list 
    # contain 31 TS
    while sum(numdev_list) > 31:
        rand = np.random.randint(low=0, high=len(numdev_list), size=1)[0]
        if numdev_list[rand] == 8:
            continue
        numdev_list[rand] -= 1

    return numdev_list

def AjustedNumDev(rxapp):
    """
    Argument:
    Pandas Dataframe -- rxapp from moview
    
    Returns:
    Pandas Dataframe -- Ajusted numdev for rxapp table
    """
    # Get the list of dev_range to iterate
    dev_list = rxapp['dev_range'].unique()

    # Iterate over the dev_range list to each dev_range apply function 
    # in the numdev column to equlize numdev to the sum of 31 TS
    for dev_range in dev_list:
        rxapp.loc[rxapp['dev_range'] == dev_range, 'numdev'] = (
            Numdev(rxapp.loc[rxapp['dev_range'] == dev_range, 'numdev'].tolist()))
    return rxapp

def DCP(port_list, numdev_list):
    """
    Argument:
    List -- List of port and Numdev
    
    Returns:
    List -- Ajusted dcp list
    """

    dcp_list = []

    for index, dcp in enumerate(port_list):
        if index == 0:
            dcp_list.append(dcp)
        elif index == 1:
            dcp_list.append(numdev_list[0] 
                            + port_list[index])
        elif index == 2:
            dcp_list.append(numdev_list[0] 
                            + numdev_list[1] 
                            + port_list[index])

    return dcp_list

def AjustedDCP(rxapp):
    """
    Argument:
    Pandas Dataframe -- rxapp from moview
    
    Returns:
    Pandas Dataframe -- Ajusted DCP for rxapp table
    """
    # Get the list of dev_range to iterate
    dev_list = rxapp['dev_range'].unique()

    # Iterate over the dev_range list to each dev_range apply function 
    # in the numdev column to equlize numdev to the sum of 31 TS
    for dev_range in dev_list:
        rxapp.loc[rxapp['dev_range'] == dev_range, 'dcp'] = (
            DCP(rxapp.loc[rxapp['dev_range'] == dev_range, 'port'].tolist(),
                   rxapp.loc[rxapp['dev_range'] == dev_range, 'numdev'].tolist()
                                                             )
                  )
    return rxapp

def Dev1(dev_ini_list, numdev_list):
    """
    Argument:
    List -- List of dev_init and Numdev
    
    Returns:
    List -- Ajusted dev1 list
    """

    dcp_list = []

    for index, dev1 in enumerate(dev_ini_list):
        if index == 0:
            dcp_list.append(dev1 + 1)
        elif index == 1:
            dcp_list.append(numdev_list[0] 
                            + dev_ini_list[index] 
                            + 1)
        elif index == 2:
            dcp_list.append(numdev_list[0] 
                            + numdev_list[1] 
                            + dev_ini_list[index] 
                            + 1)

    return dcp_list

def AjustedDev1(rxapp):
    """
    Argument:
    Pandas Dataframe -- rxapp from moview
    
    Returns:
    Pandas Dataframe -- Ajusted Dev1 for rxapp table
    """
    # Get the list of dev_range to iterate
    dev_list = rxapp['dev_range'].unique()

    # Iterate over the dev_range list to each dev_range apply function 
    # in the numdev column to equlize numdev to the sum of 31 TS
    for dev_range in dev_list:
        rxapp.loc[rxapp['dev_range'] == dev_range, 'dev_ini'] = (
            Dev1(rxapp.loc[rxapp['dev_range'] == dev_range, 'dev_ini'].tolist(),
                 rxapp.loc[rxapp['dev_range'] == dev_range, 'numdev'].tolist()
                                                                )
                )
    return rxapp

def PacketTDM(bsc):
    """
    Argument:
    Pandas Dataframe -- rxapp from moview
    
    Returns:
    Pandas Dataframe -- rrscp table from rxapp
    """

    # Read the RXAPP from Moview
    rxapp = ReadRXAPP(bsc)

    # Add the PortId
    rxapp['port'] = rxapp['dcp'].apply(DCPPort)

    # Add Column TG_Port
    rxapp['tg_port'] = rxapp['tg'].map(str) + '_' + rxapp['port'].map(str)

    # Summarise and count the devices
    rxapp = Summarise(rxapp)

    # Remove duplicate values
    rxapp = rxapp.drop_duplicates(subset=['tg_port'])

    # Add Columns Dev_Type, Dev_Initial, Dev_Range
    rxapp[['dev_type', 'dev_ini', 'dev_range']] = rxapp['dev'].apply(DevRange).apply(pd.Series)

    # Add SC Column
    rxapp['sc'] = SuperChannel(rxapp)

    # Set Numdev less than 8 to 8
    rxapp['numdev'] = rxapp['numdev'].where(rxapp['numdev'] > 8, 8)

    # Ajusted the Numdev value to each TG
    rxapp = AjustedNumDev(rxapp)

    # Ajusted the DCP value to each TG
    rxapp = AjustedDCP(rxapp)

    # Ajusted the Dev1 value to each TG
    rxapp = AjustedDev1(rxapp)

    # Update dev column
    rxapp['dev'] = rxapp['dev_type'] + '-' + rxapp['dev_ini'].map(str)

    # Drop unused columns
    rxapp = rxapp.drop(['port', 'tg_port', 'dev_type', 'dev_ini'], axis=1)

    # Rename columns and reoder columns
    rxapp.columns = ['nodeController', 'scgr', 'dev1', 'dcp', 'numdev', 
                 'dev_range', 'sc']

    rxapp = rxapp[['nodeController', 'scgr', 'sc', 'dev1', 'dcp', 'numdev', 
               'dev_range']]
    
    return rxapp

def ScgrSwap(site_list, rrscp, tg_planning):
    """
    Argument:
    List -- List with the sites
    Pandas Dataframe -- rrscp
    Pandas Dataframe -- tg_planning input
    
    Returns:
    Pandas Dataframe -- rrscp ajusted with the new scgr values
    """

    for site in site_list:

        scgr_list = rrscp.loc[rrscp['nodename'] == site, 'scgr'].unique().tolist()

        tg_list = tg_planning.loc[tg_planning['nodeName'].str.contains(site),
            'RXTG'].tolist()

        tg_list = tg_list[:len(scgr_list)]

        rrscp = rrscp.replace({'scgr': dict(zip(scgr_list, tg_list))})
    
    return rrscp

def ConvertDev1(Dev1, Old_range, New_range):

    _, old_dev, _ = Old_range.split('-')
    old_dev = old_dev.replace('&&', '')
    old_dev = int(old_dev)

    new_type, new_dev, _ = New_range.split('-')
    new_dev = new_dev.replace('&&', '')
    new_dev = int(new_dev)

    _, Dev1 = Dev1.split('-')
    Dev1 = int(Dev1)

    for old, new in zip(range(old_dev, old_dev+31), range(new_dev, new_dev+31)):
        if old == Dev1:
            return new_type + '-' + str(new)

def Dev1Swap(rrscp, reparting_g_nodes):
    """
    Argument:
    Pandas Dataframe -- rrscp
    Pandas Dataframe -- reparting_g_nodes inout
    
    Returns:
    Pandas Dataframe -- rrscp ajusted with the new dev1 values
    """

    # Select BSC for filter
    bsc = rrscp['nodeController'][0]

    # Filter reparting_g_nodes with the bsc
    reparting_g_nodes = reparting_g_nodes.loc[
        reparting_g_nodes['From_SubNetwork'] == bsc]

    # Drop unsed columns
    reparting_g_nodes1 = reparting_g_nodes.drop(['Action', 'Id', 
        'To_SubNetwork', 'To_SDIP', 'To_DIP', 'To_KLM', 'To_nodeName', 
        'From_SubNetwork', 'From_SNT', 'From_DIP', 'From_KLM',
        'From_nodeName'], axis=1)

    # merge tables
    rrscp = pd.merge(left=rrscp, 
                     right=reparting_g_nodes1, 
                     how='left',
                     left_on='dev_range',
                     right_on='From_DEV')

    new_dev1 = []

    # Iterate over the dataframe and get new Dev1 value
    for _, row in rrscp.iterrows():
           new_dev1.append(ConvertDev1(row['dev1'], 
                           row['From_DEV'], 
                           row['To_DEV']))

    return new_dev1

def GetRRSCP(bsc, input, reparting_g_nodes, tg_planning):

    # RRSCP table to each BSC
    rrscp = PacketTDM(bsc)

    # RXMOP table to each BSC
    rxmop = ReadRXMOP(bsc)
    rxmop = rxmop.drop('nodeController', axis=1)
    rxmop.columns = ['rsite', 'scgr']

    # Join with rxmop
    rrscp = pd.merge(left=rrscp, right=rxmop, how='left', on=['scgr'])

    # Drop unsed columns
    input = input.drop(['region', 'model', 'nodeController_orig', 'customer'], 
                      axis=1)

    # Join with data and drop sites outsite the input_list
    rrscp = pd.merge(left=rrscp, right=input, how='left', on=['rsite'])
    rrscp = rrscp.dropna()

    # Remove TGs for Baseband
    tg_planning = tg_planning.loc[~tg_planning['nodeName'].str.contains('S0')]

    # Drop unused columns
    tg_planning = tg_planning.drop(['Action', 'Id'], axis=1)

    # Get Site List
    site_list = rrscp['nodename'].unique()

    # Update the SCGR values according the new TG values
    rrscp = ScgrSwap(site_list, rrscp, tg_planning)

    # Update the Dev1 according new Devices
    rrscp['dev1'] = Dev1Swap(rrscp, reparting_g_nodes)

    # # Drop unused columns
    rrscp = rrscp.drop(['dev_range', 'rsite'], axis=1)

    # rename and order the columns
    rrscp = rrscp[['nodeController', 'nodeController_dest', 'nodename', 'scgr',
                   'sc', 'dev1', 'dcp', 'numdev']]
    rrscp.columns = ['nodeController_orig', 'nodeController_dest', 'nodename', 
                     'scgr', 'sc', 'dev1', 'dcp', 'numdev']
    
    return rrscp







def WriteExcel(data):
    # Create a Pandas Excel writer using XlsxWriter as the engine.
    writer = pd.ExcelWriter('/home/esssfff/Documents/Test.xlsx', 
                            engine='xlsxwriter')

    # Convert the dataframe to an XlsxWriter Excel object.
    data.to_excel(writer, 
                  sheet_name='Site_List', 
                  index=False,
                  startcol=1,
                  startrow=1)

    # Close the Pandas Excel writer and output the Excel file.
    writer.save()

