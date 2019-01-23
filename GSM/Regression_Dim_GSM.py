#%%
# Import libraries
import pandas as pd

data = pd.read_csv('/home/esssfff/Documents/Inputs/BSC_Vivo.csv', 
                   sep=',',
                   names=['Time', 'Bsc', 'Tch', 'Data'],
                   skiprows=1)

data = data.apply(lambda x: x.str.replace(',', '.'))
data[['Tch', 'Data']] = data[['Tch', 'Data']].apply(pd.to_numeric)
data['Time'] = pd.to_datetime(data['Time'])

Bsc_list = data['Bsc'].unique()

ini_date = pd.to_datetime('2018-09-01')

data = data.loc[data['Time'] >= ini_date,]

data = data.pivot(index='Time', columns='Bsc', values=['Tch', 'Data'])

#%%
# Import ols from statsmodels, and fit a model to the data
from statsmodels.formula.api import ols

df = data['Tch']['BSCAFLA'].reset_index()
df['Int'] = range(len(df))
model_fit = ols(formula="Int ~ BSCAFLA", data=df).fit()
print(model_fit.summary())


#%%



from statsmodels.formula.api import ols
model_fit = ols(formula="masses ~ Bsc", data=data).fit()



#%%
data.to_csv('/home/esssfff/Documents/Inputs/Formated.csv',
            sep=',',
            index=False)

#%%
