#%%

#arrow to the construct

#parquch 
#feather allows us to add special feature that parquch doesnt
import pandas as pd
import altair as alt
import numpy as np
import plotnine as plt
import matplotlib as mat
import geopandas as gpd
import folium 

#%%
#import sys
#!{sys.executable} -m pip install rtree
#%%
#import sys
#!{sys.executable} -mpip install pygeos
#gdal installation
#%%
#import sys
#!{sys.executable} -m pip install pyarrow
#arrow install
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

usa = gpd.read_parquet("data/usa.parquet")
county = gpd.read_parquet("/Users/ashleyrabanales/Projects_ST/p3_rabanales/SafeGraph - Patterns and Core Data - Chipotle - July 2021/usa_counties.feather")
cities = gpd.read_parquet("data/usa_cities.parquet")
#%%
#ga <- USAboundaries::us_counties(states = 'Georgia')

#%% 
datNest4 = pd.read_csv("/Users/ashleyrabanales/Projects_ST/p3_AshLee/data/v1_base_with_census_metrics.csv")
print (datNest4) #tell if import correctly

ga = pd.read_csv("/Users/ashleyrabanales/Projects_ST/p3_AshLee/data/ga.csv")

#%%
#Getting lat and long columns to spatial objects
#Let’s load our SafeGraph data on Chipotle stores and convert the latitude and longitude to a geometry column.
# you may need to change your file path.
dat = pd.read_csv("SafeGraph - Patterns and Core Data - Chipotle - July 2021/Core Places and Patterns Data/chipotle_core_poi_and_patterns.csv")

dat_sp = gpd.GeoDataFrame(
    dat.filter(["placekey", "latitude", "longitude", "median_dwell"]), 
    geometry=gpd.points_from_xy(
        dat.longitude,
        dat.latitude))
#%%
import folium
from plotnine import *
#%%
#MATPLOTLIB
#Maps with layers
county = gpd.read_parquet("data/usa_counties.parquet")
c48=county.query('stusps not in ["HI", "AK", "PR"]')

base = c48.plot(color="white", edgecolor="darkgrey")
dat_sp.plot(ax=base, color="red", markersize=5)
#%%
#FOLIUM
#They also have an interactive option that depends on Folium which leverages leaflet.js like the leaflet package 
#in R. We need to install some additional dependencies.
import sys
!{sys.executable} -m pip install folium matplotlib mapclassify
#%%
dat_sp_lt100 = dat_sp.query("median_dwell < 100")
c48 = county.query('statusps not in ["HI", "AK", "PR"]')

# %%
base_inter = c48.explore(
    style_kwds = {"fill":False, 
        "color":"darkgrey",
        "weight":.4}
)

theplot=dat_sp_lt100.explore(
    m=base_inter,
    column='median_dwell',
    cmap="Set1",
    marker_kwds={"radius":2, "fill":True},
    style_kwds={"fillOpacity":1})

folium.TileLayer('Stamen Toner', control=True).add_to(base_inter)  # use folium to add alternative tiles
folium.LayerControl().add_to(base_inter)  

theplot
If we want to get the plot out of the interactive viewer we save the map object as an .html file and open the file in our web browser.

theplot.save("map.html")

#%%


#%%
######P3D10 ############
import pandas as pd
import numpy as np
import geopandas as gpd

#import folium
import rtree

from plotnine import *

url_loc = "/Users/ashleyrabanales/Projects_ST/p3_rabanales/SafeGraph - Patterns and Core Data - Chipotle - July 2021/Core Places and Patterns Data/chipotle_core_poi_and_patterns.csv"
dat = pd.read_csv(url_loc)
#%%
county = gpd.read_parquet("usa_counties.parquet")
#%%
#Now we can subset the Chipotles to California and build a goemetry column.
dat_cal = dat.query("region=='CA'")
dat_cal = gpd.GeoDataFrame(
    dat_cal.filter(["placekey", "latitude", "longitude", "median_dwell", "region"]),
        geometry=gpd.points_from_xy(dat_cal.longitude, dat_cal.latitude),
    crs='EPSG:4326')

#geometry tells it to givr it a point 
#making a spatial plots, 
#%%
#Lets parse our county polygons
#Now we can build out some spatial calculations on our California counties. In the example below we want to calculate the distance of each county center to KSU.
#The code to get our KSU point.#
#%%
from shapely.geometry import Point
ksu_df = pd.DataFrame({"lat":[34.037876],
        "long":[-84.58102]})

ksu = gpd.GeoDataFrame(ksu_df,
    geometry=gpd.points_from_xy(ksu_df.long, ksu_df.lat),
    crs='EPSG:4326')

point = Point(
    ksu.geometry.to_crs(epsg = 3310).x,
    ksu.geometry.to_crs(epsg = 3310).y)

ksu.geometry.to_crs(epsg = 3310) 
#trying too get it in meters instead of degrees
#%%
cal = county.query("stusps == 'CA'")


# %%
#Our new wrangled California, calw.
calw = (cal
    .assign(
        gp_area = lambda x: x.geometry.to_crs(epsg = 3310).area,
        gp_acres = lambda x: x.gp_area * 0.000247105,
        aland_acres = lambda x: x.aland * 0.000247105,
        percent_water = lambda x: x.awater / x.aland,
        gp_center = lambda x: x.geometry.to_crs(epsg = 3310).centroid,
        gp_length = lambda x: x.geometry.to_crs(epsg = 3310).length,
        gp_distance = lambda x: x.gp_center.distance(point),
        gp_buffer = lambda x: x.geometry.to_crs(epsg = 3310).buffer(24140.2)      
))
# %%
calw.gp_center.plot()
calw.gp_buffer.plot()
# %%
base = calw.plot(color="white", edgecolor="darkgrey")
dat_cal.plot(ax=base, color="red", markersize=5)
# %%
# we want to plot filled counties by count.
# Now count stores by county
#%%
dat_join_s1 = gpd.sjoin(dat_cal, calw)

dat_join_merge = (dat_join_s1
    .groupby("name")
    .agg(counts = ('percent_water', 'size'))
    .reset_index())

calw_join = (calw
    .merge(dat_join_merge, on="name", how="left")
    .fillna(value={"counts":0}))
# %%
base = calw_join.plot(
    edgecolor="darkgrey",
    column = "counts", legend=True)
dat_cal.plot(ax=base, color="red", markersize=2)


# %%
base_inter = calw_join.explore(
    column = 'counts',
    style_kwds = { 
        "color":"darkgrey",
        "weight":.4}
)

base_inter.save("plot.html")
# %%
theplot = dat_cal.explore(
    m=base_inter,
    marker_kwds={"radius":2, "fill":True},
    style_kwds={"fillOpacity":1})

theplot.save("plot.html")
# %%

folium.TileLayer('Stamen Toner', control=True).add_to(base_inter)  # use folium to add alternative tiles
folium.LayerControl().add_to(base_inter)  

theplot
# %%
theplot.save("plot.html")

# %%