#%%
# Import libraries
from sqlalchemy import (create_engine, Table, Column, Integer, String, 
                        MetaData, select, or_, and_)
import pandas as pd


data = pd.read_csv('/home/esssfff/Documents/Inputs/BSC_Vivo.csv', 
                   sep=',',
                   names=['Time', 'Bsc', 'Tch', 'Data'],
                   skiprows=1)


def format_data(dataframe, initial_data='2017-09-01'):

    # Replace values with comma to dot
    data = dataframe.apply(lambda x: x.str.replace(',', '.'))
    
    # Convert Cols data Tch e Data to numeric
    data[['Tch', 'Data']] = data[['Tch', 'Data']].apply(pd.to_numeric)

    # Convert column Time to datatime(ns)
    data['Time'] = pd.to_datetime(data['Time'])
    
    # Get Bsc list of the dataframe
    Bsc_list = data['Bsc'].unique()

    # Convert ini_data to pandas datatime
    ini_date = pd.to_datetime(initial_data)

    # Subset the dataframe according the initial value
    data = data.loc[data['Time'] >= ini_date,]
    
    # Pivot the data for each Bsc per col
    data = data.pivot(index='Time', columns='Bsc', values=['Tch', 'Data'])

    # Fill missing values according the last value
    data = data.fillna(method='backfill')
    data = data.fillna(method='ffill')

    # Get the difference between the days
    days = data.index[-1] - data.index[-0]

    return Bsc_list, days, data

def ReadRXOTRX():
    """
    Argument:
    String -- String with the BSC name
    
    Returns:
    pandas dataframe -- dataframe with RXMOP:MOTY=RXOTRX;
    """
    
    # Create Engine
    engine = create_engine('mssql+pyodbc://mv_vivo:vivo@MoviewVivo')

    # Selection RXOTG data from RXMOP data base
    rxotrx = Table('RXMOP', MetaData(),
              Column('nodeLabel', String(10)),
              Column('TG', Integer), 
              Column('TRX', Integer),
              Column('CELL', String(10)),
              Column('MOTY', String(10))
              )
    stmt = select([rxotrx]).where(rxotrx.columns.MOTY == 'RXOTRX').distinct()
    
    results = engine.connect().execute(stmt).fetchall()

    # Convert to pandas DataFrame
    rxotrx = pd.DataFrame(results)

    # Add column names and drop unused columns
    rxotrx.columns = ['Bsc', 'tg', 'trx', 'cell', 'moty']
    rxotrx = rxotrx.drop(['cell', 'moty'], axis=1)
    
    # Converte columns to integer type
    rxotrx[['tg', 'trx']] = rxotrx[['tg', 'trx']].astype(int)
   
    return rxotrx

# Apply function
Bsc_list, days, data = format_data(data)

rxotrx = ReadRXOTRX()

#%%
df = data.resample('M').mean()

print(df.iloc[0,:])
print(df.iloc[-1,:])

df = df.iloc[0,:] - df.iloc[-1,:]

print(df)

#%%
rxotrx = rxotrx.groupby(['Bsc']).size().reset_index(name='Trx')

print(rxotrx)



#%%
# Import ols from statsmodels, and fit a model to the data
from statsmodels.formula.api import ols

df = data['Tch']['BSCAJUA'].reset_index()
df['Int'] = range(len(df))
model_fit = ols(formula="Int ~ BSCAJUA", data=df).fit()
print(model_fit.summary())
#%%
rxotrx.to_csv('/home/esssfff/Documents/Inputs/Trx.csv',
            sep=';')
