#%%
# Load Libraries and functions
from sqlalchemy import (create_engine, Table, Column, Integer, String, 
                        MetaData, select, or_)

import pandas as pd

# Reading MoView data

# Print Tables from the connection
# print(engine.table_names())
# Print columns from a specific Table
# print(engine.execute('select * from RRSCP').keys())

#%%

def RXOTG(bsc):

    # Create Engine
    engine = create_engine('mssql+pyodbc://mv_claro:claro@MoviewClaro')

    # Selection RXOTG data from RXMOP data base
    rxotg = Table('RXMOP', MetaData(),
                  Column('nodeLabel', String(10)), 
                  Column('RSITE', String(10)), 
                  Column('TG', Integer),
                  Column('MOTY', String(10))
                  )

    stmt = select([rxotg]).where(rxotg.columns.nodeLabel == bsc).distinct()

    results = engine.connect().execute(stmt).fetchall()

    results = pd.DataFrame(results)

    results.columns = ['nodeLabel', 'RSITE', 'TG', 'MOTY']

    results = results.drop(['nodeLabel', 'MOTY'], axis=1)

    return results

def NTCOP(bsc):

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

    stmt = select([ntcop]).where(ntcop.columns.nodeLabel == bsc).distinct()

    results = engine.connect().execute(stmt).fetchall()

    results = pd.DataFrame(results)

    results.columns = ['nodeLabel', 'SDIP', 'SNTINL', 'DIP', 'DEV']

    results = results.drop(['nodeLabel'], axis=1)

    return results

def RRSCP(bsc):

    # Create Engine
    engine = create_engine('mssql+pyodbc://mv_claro:claro@MoviewClaro')

    # Selection RXOTG data from RXMOP data base
    rrscp = Table('RRSCP', MetaData(),
                  Column('nodeLabel', String(10)), 
                  Column('SCGR', String(10)), 
                  Column('DEV1', String(20))
                  )

    stmt = select([rrscp]).where(rrscp.columns.nodeLabel == bsc).distinct()

    results = engine.connect().execute(stmt).fetchall()

    results = pd.DataFrame(results)

    results.columns = ['nodeLabel', 'SCGR', 'DEV1']

    results = results.drop(['nodeLabel'], axis=1)

    return results

#%%

rxotg = RXOTG('BSCSI61')
ntcop = NTCOP('BSCSI61')
rrscp = RRSCP('BSCSI61')

print(rrscp)
#%%
