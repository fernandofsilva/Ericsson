# -*- coding: utf-8 -*-
"""
@author: Fernando Silva

This file constains a code to analysis BSC optimization performance

"""

# Load Libraries and functions
from sqlalchemy import (create_engine, Table, Column, Integer, String, 
                        MetaData, select, and_)

import pandas as pd
import glob as glob
import matplotlib.pyplot as plt

# Input Manualy required

operator = 'OI'

# Reading Printout file

path = r'/media/sf_SharedUbuntu/'
allfiles = glob.glob(path + "/*RRSCP.log")

list_ = []

for file_ in allfiles:
    df = pd.read_fwf(file_, widths = [6, 4, 15, 15, 8, 5, 7], 
                    skiprows = 4, skip_blank_lines = True)
    df['nodeLabel'] = file_[len(path):len(path)+7]
    list_.append(df)

rrscp = pd.concat(list_, ignore_index=True)

del allfiles, df, file_, list_, path

rrscp = rrscp.apply(lambda x: x.str.strip())
rrscp = rrscp[pd.notnull(rrscp['SC'])]
rrscp = rrscp[rrscp['SC'] != 'SC']
rrscp = rrscp.fillna(method='ffill')
rrscp[['SCGR', 'SC', 'NUMDEV', 'DCP']] = rrscp[['SCGR', 'SC', 'NUMDEV', 'DCP']].astype(int)
rrscp['SCGR_SC'] = rrscp['SCGR'].astype(str) + '-' + rrscp['SC'].astype(str)


# Reading MoView data

bsclist = rrscp['nodeLabel'].unique().tolist()

if operator == 'VIVO':
    engine = create_engine("mssql+pyodbc://mv_vivo:vivo@MoviewVivo")
elif operator == 'TIM':
    engine = create_engine("mssql+pyodbc://mv_tim:tim@MoviewTim")
elif operator == 'CLARO':
    engine = create_engine("mssql+pyodbc://mv_claro:claro@MoviewClaro")
else:
    engine = create_engine("mssql+pyodbc://mv_bra_oi:bra_oi@MoviewOi")

del operator

# Selection RXOTG data from RXOMOP data base

rxotg = Table('RXMOP', MetaData(),
              Column('nodeLabel', String(10)), 
              Column('TG', Integer),
              Column('RSITE', String(10)), 
              Column('MOTY', String(10))
              )

stmt = select([rxotg]).where(
        and_(rxotg.columns.MOTY == 'RXOTG',
             rxotg.columns.nodeLabel.in_(bsclist)
             )
        ).distinct()

results = engine.connect().execute(stmt).fetchall()

rxotg = pd.DataFrame(results)

rxotg.columns = ['nodeLabel', 'TG', 'RSITE', 'MOTY']

rxotg[['TG']] = rxotg[['TG']].astype(int)

del rxotg['MOTY'], results, bsclist


# Reading STS files

filename = '/media/sf_SharedUbuntu/SUPERCH.csv'
superch = pd.read_csv(filename)

superch.columns = superch.columns.str.replace('SUPERCH.pm', '')

del filename

superch['time'] = pd.to_datetime(superch['time'])
superch['object'] = superch['object'].replace(
        to_replace = ["SubNetwork=BSS,SubNetwork=BSS,MeContext=", "SUPERCH="], 
        value = "", regex = True
        )

superch['nodeLabel'], superch['SCGR_SC'] = superch['object'].str.split(',', 1).str

df = pd.merge(left = rrscp, 
              right = rxotg, 
              how = 'left',
              left_on = ['nodeLabel', 'SCGR'],
              right_on = ['nodeLabel', 'TG']
              )

df = pd.merge(left = superch, 
              right = df, 
              on = ['nodeLabel', 'SCGR_SC']
              )

del rxotg, rrscp, superch

df['Av_Link_Util_DL'] = 100 * (8000 * df['KBSENT']) / (df['KBSCAN'] * df['NUMDEV'] * 64000)
df['Av_Link_Util_UL'] = 100 * (8000 * df['KBREC']) / (df['KBSCAN'] * df['NUMDEV'] * 64000)
df['Max_Link_Util_DL'] = 100 * (8000 * df['KBMAXSENT']) / (df['NUMDEV'] * 64000)
df['Max_Link_Util_UL'] = 100 * (8000 * df['KBMAXREC']) / (df['NUMDEV'] * 64000)

df = df[['time', 'nodeLabel', 'RSITE', 'SCGR_SC', 
         'Av_Link_Util_DL', 'Av_Link_Util_UL', 
         'Max_Link_Util_DL', 'Max_Link_Util_UL']]


# Ploting the charts

for val1 in df['RSITE'].unique():
    
    site = df.loc[df['RSITE'] == val1,:]
    scgr = site['SCGR_SC'].unique()
    bsc = str(site['nodeLabel'].unique())
    
    plt.subplots(figsize = (20, 17))
    
    # Plot 1 Average Link Utilization DL
    
    plt.subplot(221)
    for index, val2 in enumerate(scgr):
        sc = site.loc[site['SCGR_SC'] == val2,:]
        plt.plot(sc['time'], sc['Av_Link_Util_DL'], 
                 'C{!r}'.format(index), 
                 label = str(val2)
                 )
    plt.title('Average Link Utilization DL, [%]')
    plt.xlabel('Time')
    plt.xticks(rotation = 45)
    plt.ylabel('[%]')
    plt.ylim([0, 100])
    plt.grid(True)
    plt.legend(loc = "upper right", bbox_to_anchor = [1.15, 1], 
               title = "SCGR-SC", fancybox = True)
    
    # Plot 2 Average Link Utilization UL
    
    plt.subplot(222)
    for index, val2 in enumerate(scgr):
        sc = site.loc[site['SCGR_SC'] == val2,:]
        plt.plot(sc['time'], sc['Av_Link_Util_DL'], 
                 'C{!r}'.format(index), 
                 label = str(val2)
                 )
    plt.title('Average Link Utilization UL, [%]')
    plt.xlabel('Time')
    plt.xticks(rotation = 45)
    plt.ylabel('[%]')
    plt.ylim([0, 100])
    plt.grid(True)
    plt.legend(loc = "upper right", bbox_to_anchor = [1.15, 1], 
               title = "SCGR-SC", fancybox = True)
    
    # Plot 3 Max Link Utilization UL last 15 min
    
    plt.subplot(223)
    for index, val2 in enumerate(scgr):
        sc = site.loc[site['SCGR_SC'] == val2,:]
        plt.plot(sc['time'], sc['Max_Link_Util_DL'], 
                 'C{!r}'.format(index), 
                 label = str(val2)
                 )
    plt.title('Max Link Utilization UL last 15 min, [%]')
    plt.xlabel('Time')
    plt.xticks(rotation = 45)
    plt.ylabel('[%]')
    plt.ylim([0, 100])
    plt.grid(True)
    plt.legend(loc = "upper right", bbox_to_anchor = [1.15, 1], 
               title = "SCGR-SC", fancybox = True)
    
    # Plot 4 Max Link Utilization DL last 15 min
    
    plt.subplot(224)
    for index, val2 in enumerate(scgr):
        sc = site.loc[site['SCGR_SC'] == val2,:]
        plt.plot(sc['time'], sc['Max_Link_Util_UL'], 
                 'C{!r}'.format(index), 
                 label = str(val2)
                 )
    plt.title('Max Link Utilization DL last 15 min, [%]')
    plt.xlabel('Time')
    plt.xticks(rotation = 45)
    plt.ylabel('[%]')
    plt.ylim([0, 100])
    plt.grid(True)
    plt.legend(loc = "upper right", bbox_to_anchor = [1.15, 1], 
               title = "SCGR-SC", fancybox = True)
    
    plt.savefig('/media/sf_SharedUbuntu/{!s}_{!s}.jpg'.format(bsc, val1))
    