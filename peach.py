#%%
import pandas as pd
import altair as alt
import numpy as np
import plotnine as plt
import matplotlib as mat
import geopandas as gpd
#%%
#import sys
#!{sys.executable} -mpip install pygeos
#gdal installation
#%%
#import sys
#!{sys.executable} -m pip install geopandas


census_url  = "https://www2.census.gov/geo/tiger/GENZ2018/shp/cb_2018_us_county_500k.zip"
county_shp = gpd.read_file(census_url)
# county_shp = gpd.read_file("data/cb_2018_us_county_500k.zip")
#%%
cobb_url = "https://github.com/johan/world.geo.json/raw/master/countries/USA/GA/Cobb.geo.json"
cobb_gj = gpd.read_file(cobb_url)
# cobb_gj = gpd.read_file("data/Cobb.geo.json")
#%%




#ga <- USAboundaries::us_counties(states = 'Georgia')

#%% 
datNest4 = pd.read_csv("/Users/ashleyrabanales/Projects_ST/p3_AshLee/data/v1_base_with_census_metrics.csv")
print (datNest4) #tell if import correctly

ga = pd.read_csv("/Users/ashleyrabanales/Projects_ST/p3_AshLee/data/ga.csv")

#%%