#%%
# Load Libraries and functions
from sqlalchemy import (create_engine, Table, Column, Integer, String, 
                        MetaData, select, or_)

import pandas as pd

# Reading MoView data

# Create Engine
engine = create_engine('mssql+pyodbc://mv_claro:claro@MoviewClaro')

# Selection RXOTG data from RXMOP data base
rxotg = Table('RXMOP', MetaData(),
              Column('nodeLabel', String(10)), 
              Column('RSITE', String(10)), 
              Column('TG', Integer),
              Column('MOTY', String(10))
              )

stmt = select([rxotg]).where(or_(rxotg.columns.MOTY == 'RXOTG',
                                 rxotg.columns.MOTY == 'RXSTG')
                             ).distinct()

results = engine.connect().execute(stmt).fetchall()

# Convert to pandas DataFrame
site = pd.DataFrame(results)

# Format Table
site.columns = ['BSC', 'SITE_ID', 'TG', 'MODEL']
site[['TG']] = site[['TG']].astype(int)
site = site.replace({'RXOTG': 'DU', 'RXSTG': 'BB'})
site = site.sort_values(by=['BSC', 'TG'])

# Create a Pandas Excel writer using XlsxWriter as the engine.
writer = pd.ExcelWriter('/home/esssfff/Documents/Site_List.xlsx', 
                        engine='xlsxwriter')

# Convert the dataframe to an XlsxWriter Excel object.
site.to_excel(writer, 
              sheet_name='Site_List', 
              index=False,
              startcol=1,
              startrow=1)

# Close the Pandas Excel writer and output the Excel file.
writer.save()