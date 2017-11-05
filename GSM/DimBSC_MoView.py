# -*- coding: utf-8 -*-
"""
@author: Fernando Silva

This file constains a code to retrieve information from MoView databse to
output a file for BSC Dimensioning

"""

# Load Libraries and functions
from sqlalchemy import (create_engine, Table, Column, Integer, String, 
                        MetaData, select, and_)

import pandas as pd
import glob as glob


# File with the list of BSC and the Operator

filename = '/media/sf_SharedUbuntu/NodeList.txt'

with open(filename) as f:
    filelist = f.read().splitlines()

operator = filelist[0]
bsclist = filelist[1:]

del filename, filelist

# Selecting engine according operator

if operator == 'VIVO':
    engine = create_engine("mssql+pyodbc://mv_vivo:vivo@MoviewVivo")
elif operator == 'TIM':
    engine = create_engine("mssql+pyodbc://mv_tim:tim@MoviewTim")
elif operator == 'CLARO':
    engine = create_engine("mssql+pyodbc://mv_claro:claro@MoviewClaro")
else:
    engine = create_engine("mssql+pyodbc://mv_bra_oi:bra_oi@MoviewOi")

del operator

# Selection RXOTRX data from RXOMOP data base

rxotrx = Table('RXMOP', MetaData(),
              Column('nodeLabel', String(10)), 
              Column('TG', Integer), 
              Column('TRX', Integer), 
              Column('CELL', String(10)), 
              Column('MOTY', String(10))
              )

stmt = select([rxotrx]).where(
        and_(rxotrx.columns.MOTY == 'RXOTRX',
             rxotrx.columns.nodeLabel.in_(bsclist)
             )
        ).distinct()

results = engine.connect().execute(stmt).fetchall()

rxotrx = pd.DataFrame(results)

rxotrx.columns = ['nodeLabel', 'TG', 'TRX', 'CELL', 'MOTY']

del rxotrx['MOTY']

del results


# Selection RXAPP data from RXAPP data base

rxapp = Table('RXAPP', MetaData(),
              Column('nodeLabel', String(10)), 
              Column('TG', Integer), 
              Column('DEV', String(10)), 
              Column('64k', String(5))
              )

stmt = select([rxapp]).where(rxapp.columns.nodeLabel.in_(bsclist)).distinct()

results = engine.connect().execute(stmt).fetchall()

rxapp = pd.DataFrame(results)

rxapp.columns = ['nodeLabel', 'TG', 'DEV', '64k']

del results


# Selection RLBDP data from RLBDP data base

rlbdp = Table('RLBDP', MetaData(),
              Column('nodeLabel', String(10)), 
              Column('CELL', String(10)), 
              Column('CHGR', Integer), 
              Column('NUMREQEGPRSBPC', Integer)
              )

stmt = select([rlbdp]).where(rlbdp.columns.nodeLabel.in_(bsclist)).distinct()

results = engine.connect().execute(stmt).fetchall()

rlbdp = pd.DataFrame(results)

rlbdp.columns = ['nodeLabel', 'CELL', 'CHGR', 'NUMREQEGPRSBPC']

del results, bsclist


# Reading STS files

path = r'/media/sf_SharedUbuntu/'
allfiles = glob.glob(path + "/*.csv")
df = (pd.read_csv(f) for f in allfiles)
sts   = pd.concat(df, ignore_index=True)

sts.columns = ['time', 'CELL_nodeLabel', 'DATA', 'TCH']

del allfiles, path, df