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

bsc_list = ['BSCSI46']

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
    results.columns = ['nodeLabel', 'RSITE', 'TG_', 'MOTY']

    # Drop unused columns
    results = results.drop(['nodeLabel', 'MOTY'], axis=1)

    # Convert column to integer
    results['TG_'] = pd.to_numeric(results['TG_'])

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
    results.columns = ['nodeLabel', 'SDIP', 'SNTINL_', 'DIP', 'DEV_']

    # Drop unused columns
    results = results.drop(['nodeLabel'], axis=1)

    # Convert column to integer
    results['SNTINL_'] = pd.to_numeric(results['SNTINL_'])

    # Return the dataframe
    return results

def RXAPP(bsc):
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
              Column('DEV', String(20))
              )
    stmt = select([rxapp]).where(rxapp.columns.nodeLabel == bsc).distinct()
    results = engine.connect().execute(stmt).fetchall()

    # Convert to pandas DataFrame
    results = pd.DataFrame(results)

    # Add column names
    results.columns = ['nodeLabel', 'TG', 'DEV']
    
    # Remove tgs without dev assigned
    results = results.dropna()

    # Drop unused columns
    results = results.drop(['nodeLabel'], axis=1)
    
    # Converte columns to integer type
    results['TG'] = pd.to_numeric(results['TG'])
   
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
    This functions create a list with the KLMs in sequence and the SNTINL
    value for reference in a pandas dataframe

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
    
    # Create a Datafrane with the values
    klm = pd.DataFrame({'KLM'   : klm,
                        'SNTINL': range(63)})
    
    # Return the dataframe
    return klm

def MergeDataFrames(rxotg, ntcop, rxapp):
    """
    Functions merge the three tables and adjust the values

    Parameters:
    result - pandas dataframe
    """

    rxapp['DEV'] = E1Range(rxapp['DEV'].tolist())

    rxapp = pd.merge(left=rxapp, 
                     right=rxotg, 
                     how='left', 
                     left_on='TG', 
                     right_on='TG_')

    rxapp = rxapp.drop(['TG', 'TG_'], axis=1)

    rxapp = rxapp.drop_duplicates()

    ntcop = pd.merge(left=ntcop,
                     right=KLM(),
                     how='left',
                     left_on='SNTINL_',
                     right_on='SNTINL')

    ntcop = ntcop.drop(['SNTINL_'], axis=1)

    # Merge the two result table
    result = pd.merge(left=rxapp,
                      right=ntcop,
                      how='left',
                      left_on='DEV',
                      right_on='DEV_')

    # Drop unused columns
    result = result.drop(['DEV_'], axis=1)

    # Sort values according E1 number
    result = result.sort_values(['RSITE'])

    # Reorder columns
    result = result[['SDIP', 'DIP', 'KLM', 'DEV', 'SNTINL', 'RSITE']]

    # Return table
    return result

def WriteExcel(dataframe, bsc):
    # Create a Pandas Excel writer using XlsxWriter as the engine.
    writer = pd.ExcelWriter('/home/esssfff/Documents/{}_ET155.xlsx'.format(bsc), 
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

    rxapp = RXAPP(bsc)

    df = MergeDataFrames(rxotg, ntcop, rxapp)

    WriteExcel(df, bsc)