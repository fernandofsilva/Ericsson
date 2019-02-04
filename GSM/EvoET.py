#%%
# Load Libraries and functions
from sqlalchemy import (create_engine, Table, Column, Integer, String, 
                        MetaData, select, and_)

import pandas as pd
import math


# Reading MoView data

# Print Tables from the connection
# print(engine.table_names())
# Print columns from a specific Table
# print(engine.execute('select * from RRSCP').keys())

bsc_list = ['BSCSI61', 'BSCSI60']

def RXOTG(bsc):
    """
    Function to return the RSITE and TG to the specific Bsc

    Parameters:
    String - Bsc name
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

    # Select where the nodeLabel equal to Bsc   
    stmt = select([rxotg]).where(and_(rxotg.columns.nodeLabel == bsc,
                                 rxotg.columns.MOTY == 'RXOTG')
                             ).distinct()

    # Fetch all the results
    results = engine.connect().execute(stmt).fetchall()

    # Convert the result to the pandas dataframe
    results = pd.DataFrame(results)

    # Add names to the columns
    results.columns = ['nodeLabel', 'RSITE', 'TG', 'MOTY']

    # Drop unused columns
    results = results.drop(['nodeLabel', 'MOTY'], axis=1)

    # Convert column to integer
    results['TG'] = pd.to_numeric(results['TG'])

    # Return the dataframe
    return results

def NTCOP(bsc):
    """
    Function to return the NTCOP command to the specific Bsc

    Parameters:
    String - Bsc name
    """

    # Create Engine
    engine = create_engine('mssql+pyodbc://mv_claro:claro@MoviewClaro')

    # Selection RXOTG data from RXMOP data base
    ntcop = Table('NTCOP', MetaData(),
                  Column('nodeLabel', String(10)), 
                  Column('SDIP', String(10)), 
                  Column('SNTINL', Integer),
                  Column('DIP', Integer),
                  Column('DEV', String(25))
                  )
    
    # Select where the nodeLabel equal to Bsc
    stmt = select([ntcop]).where(ntcop.columns.nodeLabel == bsc).distinct()

    # Fetch all the results
    results = engine.connect().execute(stmt).fetchall()

    # Convert the result to the pandas dataframe
    results = pd.DataFrame(results)

    # Add names to the columns
    results.columns = ['nodeLabel', 'SDIP_', 'SNTINL_', 'DIP', 'DEV']

    # Drop unused columns
    results = results.drop(['nodeLabel'], axis=1)

    # Convert column to integer
    results['SNTINL_'] = pd.to_numeric(results['SNTINL_'])

    # Return the dataframe
    return results

def RRSCP(bsc):
    """
    Function to return the RRSCP command to the specific Bsc

    Parameters:
    String - Bsc name
    """

    # Create Engine
    engine = create_engine('mssql+pyodbc://mv_claro:claro@MoviewClaro')

    # Selection RXOTG data from RXMOP data base
    rrscp = Table('RRSCP', MetaData(),
                  Column('nodeLabel', String(10)), 
                  Column('SCGR', String(10)), 
                  Column('DEV1', String(20))
                  )

    # Select where the nodeLabel equal to Bsc
    stmt = select([rrscp]).where(rrscp.columns.nodeLabel == bsc).distinct()

    # Fetch all the results
    results = engine.connect().execute(stmt).fetchall()

    # Convert the result to the pandas dataframe
    results = pd.DataFrame(results)

    # Add names to the columns
    results.columns = ['nodeLabel', 'SCGR', 'DEV1']

    # Drop unused columns
    results = results.drop(['nodeLabel'], axis=1)

    # Convert column to integer
    results['SCGR'] = pd.to_numeric(results['SCGR'])

    # Remove None values
    results = results.dropna()

    # Return the dataframe
    return results

def E1Range(dev1_list):
    """
    Functions calculate the device range for the specific device

    Parameters:
    String - Device from RRSCP

    """

    # Initialize the list
    dev_range = []


    for dev1 in dev1_list:

        # Split the string between the type and dev
        dev_type, dev_num = dev1.split('-')

        # Calculate the initial device
        dev_init = (math.ceil(int(dev_num) / 32) * 32 - 2) - 30

        # Calculate the end device
        dev_end  = math.ceil(int(dev_num) / 32) * 32 - 1

        # Append value to the list
        dev_range.append('{}-{}&&-{}'.format(dev_type, dev_init, dev_end))

    # Return the device range
    return dev_range

def KLM():
    """
    This functions create a list with the KLMs in sequence

    Parameters:
    None
    """
    
    # Initialize the list
    klm = []

    # Loop over the ranges and compose the KLMs
    for i in range(1, 4):
        for j in range(1, 8):
            for k in range(1, 4):
                klm.append('{},{},{}'.format(i, j, k))
    
    # Return the list
    return klm

def SdipFix(sdip):
    """
    Functions fix the SDIP column from Moview and add two other coluns in the
    dataframe for reference

    Parameters:
    sdip - pandas dataframe
    """

    # Split the string
    sdip_list = sdip.split(' ')

    # Get the len of the list for dimesioning how much STM does the BSC have
    size = len(sdip_list)

    # Initialize the list
    sdip_col = []

    # Loop over the list to construct a full SDIP column
    for sdip in sdip_list:
        sdip_col += [sdip] * 63

    # Create a Datafrane with the values
    new_sdip = pd.DataFrame({'SDIP'  : sdip_col,
                             'KLM'   : KLM() * size,
                             'SNTINL': range(63 * size)})
    
    # Return the dataframe
    return new_sdip

def MergeDataFrames(rxotg, ntcop, rrscp):
    """
    Functions merge the three tables and adjust the values

    Parameters:
    result - pandas dataframe
    """

    # Merge rrscp table with the rxotg for RSITE names
    rrscp = pd.merge(left=rrscp, 
                     right=rxotg, 
                     how='left', 
                     left_on='SCGR', 
                     right_on='TG')

    # Fill Na values with modernizado because the sites do not use the E1
    rrscp = rrscp.fillna('Modernizado')

    # Apply function E1Range in the DEV1 column of rrscp
    rrscp['DEV_'] = E1Range(rrscp['DEV1'].tolist())

    # Drop unused columns
    rrscp = rrscp.drop(['SCGR', 'DEV1', 'TG'], axis=1)

    #Fix the column SDIP from Moview
    sdip = SdipFix(ntcop['SDIP_'].tolist()[0])

    # Merge ntcop table with the correct sdip column
    ntcop = pd.merge(left=ntcop,
                     right=sdip,
                     how='left',
                     left_on='SNTINL_',
                     right_on='SNTINL')

    # Drop unused columns
    ntcop = ntcop.drop(['SDIP_', 'SNTINL_'], axis=1)

    # Merge the two result table
    result = pd.merge(left=ntcop,
                      right=rrscp,
                      how='left',
                      left_on='DEV',
                      right_on='DEV_')

    # Drop unused columns
    result = result.drop(['DEV_'], axis=1)

    # Sort values according E1 number
    result = result.sort_values(['SNTINL'])

    # Returno de results
    return result

def WriteExcel(dataframe, bsc):
    # Create a Pandas Excel writer using XlsxWriter as the engine.
    writer = pd.ExcelWriter('/home/esssfff/Documents/{}_EvoEt.xlsx'.format(bsc), 
                            engine='xlsxwriter')

    # Convert the dataframe to an XlsxWriter Excel object.
    dataframe.to_excel(writer, 
                       sheet_name='EvoEt', 
                       index=False,
                       startcol=1,
                       startrow=1)

    # Close the Pandas Excel writer and output the Excel file.
    writer.save()

for bsc in bsc_list:

    rxotg = RXOTG(bsc)

    ntcop = NTCOP(bsc)

    rrscp = RRSCP(bsc)

    df = MergeDataFrames(rxotg, ntcop, rrscp)

    WriteExcel(df, bsc)





