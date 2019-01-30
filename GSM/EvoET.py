#%%
# Load Libraries and functions
from sqlalchemy import (create_engine, Table, Column, Integer, String, 
                        MetaData, select, or_)

import pandas as pd
import math


# Reading MoView data

# Print Tables from the connection
# print(engine.table_names())
# Print columns from a specific Table
# print(engine.execute('select * from RRSCP').keys())

#%%

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
    stmt = select([rxotg]).where(rxotg.columns.nodeLabel == bsc).distinct()

    # Fetch all the results
    results = engine.connect().execute(stmt).fetchall()

    # Convert the result to the pandas dataframe
    results = pd.DataFrame(results)

    # Add names to the columns
    results.columns = ['nodeLabel', 'RSITE', 'TG', 'MOTY']

    # Drop unused columns
    results = results.drop(['nodeLabel', 'MOTY'], axis=1)

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
    results.columns = ['nodeLabel', 'SDIP', 'SNTINL', 'DIP', 'DEV']

    # Drop unused columns
    results = results.drop(['nodeLabel'], axis=1)

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

    # Return the dataframe
    return results

def E1Range(dev):
    """
    Functions calculate the device range for the specific device

    Parameters:
    String - Device from RRSCP

    """
    # Split the string between the type and dev
    dev_type, dev_num = dev.split('-')

    # Calculate the initial device
    dev_init = (math.ceil(int(dev_num) / 32) * 32 - 2) - 30

    # Calculate the end device
    dev_end  = math.ceil(int(dev_num) / 32) * 32 - 1

    # Return the device range
    return '{}-{}&&-{}'.format(dev_type, dev_init, dev_end)

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

#%%
