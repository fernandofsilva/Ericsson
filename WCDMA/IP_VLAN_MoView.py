# -*- coding: utf-8 -*-
"""
Created on Tue Jul 25 20:22:36 2017

@author: Fernando Silva
"""

import pandas as pd
import pypyodbc as pyodbc

from sqlalchemy import create_engine

engine = create_engine('mssql+pyodbc://mv_claro:claro@146.250.136.12/moView_Claro')

filename = 'C:/Users/esssfff/Documents/Inputs/AbisAnalysis.csv'

data = pd.read_csv(filename, sep=',', index_col=False, header=0)