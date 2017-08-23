# -*- coding: utf-8 -*-
"""
@author: Fernando Silva
"""

BSC = 'BSCRJ28'

# Load Libraries and functions
from sqlalchemy import (create_engine, Table, Column, Integer, String, 
                        MetaData, select, and_)

import pandas as pd

engine = create_engine("mssql+pyodbc://mv_claro:claro@MoviewClaro")


rxmop = Table('RXMOP', MetaData(),
              Column('nodeLabel', String(10)), 
              Column('TG', Integer), 
              Column('TRX', Integer), 
              Column('CELL', String(10)), 
              Column('MOTY', String(10))
              )

stmt = select([rxmop]).where(
        and_(rxmop.columns.MOTY == 'RXOTG',
             rxmop.columns.nodeLabel == 'BSCRJ28'
             )
        )
        
stmt = select([rxmop]).where(rxmop.columns.nodeLabel == BSC).distinct()

results = engine.connect().execute(stmt).fetchall()

# Print Results
print(results)
        
df = pd.DataFrame(results)



















