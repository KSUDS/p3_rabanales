install.packages("remotes")
remotes::install_github("ropensci/USAboundaries")
remotes::install_github("ropensci/USAboundariesData")
install.packages("USAboundaries")
install.packages("USAboundariesData", repos = "http://packages.ropensci.org", type = "source")
install.packages("leaflet")


library(tidyverse)
library(sf) #sf and stars packages operate on simple feature obj. 
library(USAboundaries)
library(leaflet)

child_data <- read.csv("/Users/ashleyrabanales/Desktop/STAT 4210 - Regression/Data Sets/FC2019v1.csv") %>%
st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

 ga <- USAboundaries::us_counties(states = 'Georgia') %>%
    select(countyfp, countyns, name, aland, awater, state_abbr, geometry)

ga %>%
    mutate(
        states_area = aland + awater,
        sf_area = st_area(geometry)) %>%
    select(name, states_area, aland, sf_area, awater) %>%
    filter(name == "Douglas")

 #joining data
child_data <- st_join(child_data, ga, join = st_within)

# Write the joined mapping data
child_data <- read.csv ("/Users/ashleyrabanales/Desktop/STAT 4210 - Regression/Data Sets/FC2019v1.csv", x = ga)


