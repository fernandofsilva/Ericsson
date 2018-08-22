#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 22 11:07:32 2018

@author: esssfff
"""

# Import pandas
import pandas as pd
import glob
import numpy as np

# Assign spreadsheet filename: file
file1 = glob.glob("/media/sf_SharedUbuntu/Rehome*")[0]
file2 = glob.glob("/media/sf_SharedUbuntu/99._Report*")[0]

# Load spreadsheet:
demand = pd.ExcelFile(io=file1).parse(sheet_name=0)
sh = pd.ExcelFile(file2).parse(sheet_name=0, skiprows=list(range(18)))
del file1, file2

# Format dataframes

demand = demand.loc[:,["REGISTRO ID SH", "TX"]]
demand.columns = ["Registro", "TX"]

shcols = ["Registro", "INTEGRAÇÃO PLANEJADA", "424. BSC/RNC Old_3G", 
    "RNC New_3G", "INTEGRAÇÃO REAL", "421. Status TND_2G", 
    "988. TND REVISÃO_2G"]
sh = sh.loc[:,shcols]

# Joing data frames
result = pd.merge(left=demand, 
  right=sh,
  how="left", 
  on=["Registro","Registro"])
del shcols, sh, demand

# Order a data frame by date
result = result.sort_values(by="INTEGRAÇÃO PLANEJADA")
result = result.dropna(subset=["424. BSC/RNC Old_3G"])

# Export results
writer = pd.ExcelWriter("/media/sf_SharedUbuntu/Result_demanda.xlsx")
result.to_excel(excel_writer=writer, sheet_name='Sheet1', index=False)
writer.save()

del result