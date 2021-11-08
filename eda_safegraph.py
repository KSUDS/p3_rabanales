#%%
import pandas as pd
import numpy as np
import geopandas as gpd
import folium 
from plotnine import *
import safegraph_functions as sgf
import requests 
#%% 
import re #regular expression
#range number - if the size is 1 
#%%

your_location = "safegraph_functions.py"

url = "https://gist.githubusercontent.com/hathawayj/ddb41bb308aaf4e95cede353311fb4f5/raw/02184ca131c0b145931a028feba5c38f8c7e4b52/safegraph_functions.py"

response = requests.get(url)

print(response.headers.get('content-type'))

open(your_location, "wb").write(response.content)
# %%
url_loc = "https://github.com/KSUDS/p3_spatial/raw/main/SafeGraph%20-%20Patterns%20and%20Core%20Data%20-%20Chipotle%20-%20July%202021/Core%20Places%20and%20Patterns%20Data/chipotle_core_poi_and_patterns.csv"
dat = pd.read_csv(url_loc)

datl = dat.iloc[:10,:]
#%%
#Now we can use sgf.expand_json() and sgf.expand.list() to get the embedded data out of the dataframe.
list_cols = ['visits_by_day', 'popularity_by_hour']
json_cols = ['open_hours','visitor_home_cbgs', 'visitor_country_of_orgin', 'bucketed_dwell_times', 'related_same_day_brand', 'related_same_month_brand', 'popularity_by_day', 'device_type', 'visitor_home_aggregation', 'visitor_daytime_cbgs']

dat_pbd = sgf.expand_json('popularity_by_day', datl)
#row is a store by day of the week 

dat_rsdb = sgf.expand_json('related_same_day_brand', datl)
#different stores by seeing who went to each.

dat_vbd = sgf.expand_list("visits_by_day", datl)
#return 0 if no visits, number by day of the month

dat_pbh = sgf.expand_list("popularity_by_hour", datl)
#%%

#What are the top three brands that Chipotle customers visit on the same day?
#Create a bar chart of the top 10 to show us.
dat_rsdb = sgf.expand_json('related_same_day_brand', dat)
#%%
(dat_rsdb
    .drop(columns=["placekey"])
    .sum()
    .reset.index()
    .rename(columns = {"index":"brand", 
    0:"visits"})
    .sort_values(by = "visits", ascending = False)
    .assign(brand = lambda x: x.brand.str.replace)
    .head(20)
    .reset.index(drop =True)
)
#%%
ggplot(dat20, aes(x= "brand", y = "visits")) +
geom_col() +
coord_flip())

#%%


dat_pbh = sgf.expand_list("popularity_by_hour", dat)

(ggplot(dat_pbd, aes( x = "hour.astype(str).str.", y = "popularity_by_hour"))+ 
geom_boxplot)

#last code is similar to cbind (pd.concat)in r code/ if code not order then row
# 
# %%
