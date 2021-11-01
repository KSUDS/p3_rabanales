#brad's code in importing and merging data

# importing libraries for file access
library(tidyverse)
library(sf)
library(jsonlite)
library(USAboundaries)
library(leaflet)
library(tmap)

json_to_tibble <- function(x) {
    if(is.na(x))  return(x)
    parse_json(x) %>%
    enframe() %>%
    unnest(value)
}

bracket_to_tibble <- function(x){
    value <- str_replace_all(x, "\\[|\\]", "") %>%
        str_split(",", simplify = TRUE) %>%
        as.numeric()

    name <- seq_len(length(value))

    tibble::tibble(name = name, value = value)
}

# Read in original file
dat <- read_csv("C:/code/p3_AshLee/hackathon_data/202107/core_poi-patterns.csv")

# Create version with filtered columns

dat2 <- dat %>%
    select(c('street_address','poi_cbg','latitude', 'longitude','raw_visit_counts','visitor_home_cbgs'))

# Flip to tibble (Only on visitor home cbgs, keeping other just in case)

datNest <- dat2 %>%
    #slice(1:50) %>% # for the example in class.
    mutate(
        visitor_cbg = map(visitor_home_cbgs, ~json_to_tibble(.x))
        )

# Verticle breakage

datNest2 <- datNest %>%
    select(street_address, poi_cbg, latitude, longitude, visitor_cbg) %>%
    unnest(visitor_cbg) 

# Write csv file for base.
write.csv('C:/code/p3_AshLee/data/2021_base_b4_census.csv', x = datNest2)

# Import definition files for lat/long
#def1 <- read_csv("C:/code/p3_AshLee/hackathon_data/safegraph_open_census_data_2019/metadata/cbg_geographic_data2.csv", col_types = "cddcc")

#dat_w_geo <- merge(datNest2, def1, by = xxxxxxxx)

# If need to read in material after blowing up pc again

def2 <- read_csv("C:/code/p3_AshLee/hackathon_data/safegraph_open_census_data_2019/data/cbg_b03.csv")
def4 <- read_csv("C:/code/p3_AshLee/hackathon_data/safegraph_open_census_data_2019/data/cbg_b01.csv")
def5 <- read_csv("C:/code/p3_AshLee/hackathon_data/safegraph_open_census_data_2019/data/cbg_b19.csv")

# CReate df with unique data
# made no change
#datNest2_stripped = subset(datNest2, select = -c(placekey, brands, city, visitor_cbg))

# Create other race column
def2 <- def2 %>%
    mutate(other = (B03002e5+B03002e7+B03002e8+B03002e9))

# create subset of just race counts
def3 <- def2 %>%
    select(census_block_group, B03002e1, B03002e3, B03002e4, B03002e6, B03002e12, other)

def4 = subset(def4, select = c(census_block_group,B01002e1))
def5 = subset(def5, select = c(census_block_group,B19013e1))

# merge race data with main data
datNest3 <- merge(datNest2, def3, by.x = c('name'), by.y = c('census_block_group'))
datNest3 <- merge(datNest3, def4, by.x = c('name'), by.y = c('census_block_group'))
datNest3 <- merge(datNest3, def5, by.x = c('name'), by.y = c('census_block_group'))

#pull down to one level head(datNest3)

datNest4 <- datNest3 %>%
        group_by(street_address, poi_cbg, latitude, longitude) %>%
        summarise(wam_age = weighted.mean(B01002e1,value,na.rm = TRUE)
                ,wam_income = weighted.mean(B19013e1,value,na.rm = TRUE)
                ,ttl_value = sum(value)
                ,ttl_population = sum(B03002e1)
                ,ttl_white = sum(B03002e3)
                ,ttl_black = sum(B03002e4)
                ,ttl_asian = sum(B03002e6)
                ,ttl_hispanic = sum(B03002e12)
                ,ttl_other = sum(other)
                ) %>%
        ungroup()
     
    
# checking
filter(datNest4, street_address == "2009 W Hill Ave")

# Write data with census data metrics
write.csv('C:/code/p3_AshLee/data/2021_base_with_census_metrics.csv', x = datNest4)
#write.csv('C:/code/p3_AshLee/data/garbage.csv', x = datNest3)

# Code in case break in work
datNest4 <- read_csv("C:/code/p3_AshLee/data/2021_base_with_census_metrics.csv")


# Getting mapping data
datNest4 <- datNest4 %>%
    st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

ga <- USAboundaries::us_counties(states = 'Georgia')


# Showing options middle and area
#ga %>%
#    select(-9) %>%
#    mutate(sf_area = st_area(geometry),
#    sf_middle = st_centroid(geometry)
#    )

# remove duplicate state
ga <- ga %>% select(-9)

# Join data (why polygons dropped)
gas_in_ga2 <- st_join(datNest4, ga, join = st_within) %>%
    select(street_address, geometry, countyfp, wam_age, wam_income, ttl_value, ttl_population, ttl_white, ttl_black, ttl_asian, ttl_hispanic, ttl_other)


# Write the joined mapping data
write.csv('C:/code/p3_AshLee/data/2021_base_with_census_mapping_metrics2.csv', x = gas_in_ga)


# join is our friend not working here

gas_in_ga2_count <- gas_in_ga2 %>%
    as_tibble() %>%
    weighted.mean(wam_age,ttl_value,na.rm = TRUE) %>%
    weighted.mean(wam_income,ttl_value,na.rm = TRUE) %>%
    sum(ttl_value) %>%
    sum(ttl_population) %>%
    sum(ttl_white) %>%
    sum(ttl_black) %>%
    sum(ttl_asian) %>%
    sum(ttl_hispanic) %>%
    sum(ttl_other) %>%
    filter(!is.na(countyfp))

calw <- calw %>%
    left_join(store_in_county_count, fill = 0) %>%
    replace_na(list(n = 0)) 



# Graph?
ggplot() +
    geom_sf(data = ga) +
    geom_sf(data = gas_in_ga2, aes(fill = wam_income)) +
    scale_fill_viridis_c(option = "plasma", trans = "sqrt")
    #geom_sf_text(data = ga, aes(label = name), color = "grey")

tmap_mode("view")
tm_shape(gas_in_ga) +
    tm_fill(
        col = "wam_income",
        palette = 'Greens',
        style = 'cont',
        contrast = c(.1,1),
        title = 'Median Income By County',
        id = ,
        showNA = FALSE,
        alpha = 0.8,
        popup.vars = c("Total Visits" = 'value',
        'Median Income' = 'wam_income'),
        popup.format = list( value = list(format = "f", digits = 0),
        wam_income = list(format = "f", disgits = 0)
        )
    ) +
tm_borders(col = 'darkgray', lwd = 0.7) 


leaflet(gas_in_ga2) %>%
    addPolygons(
        data = gas_in_ga2,
        fillColor = ~pal(value),
        fillOpacity = .5,
        color = "darkgrey",
        weight = 2) #%>%
    #addCircleMarkers(
        #data = filter(dat, region == "CA"),
        #radius = 3,
        #color = "grey") %>%
    addProviderTiles(providers$CartoDB.Positron)



#########hackathon2 from brad#######

# Initiate libraries

library(tidyverse)
library(sf)
library(USAboundaries)
library(leaflet)
 
# function to help shift to tibble

json_to_tibble <- function(x) {
    if(is.na(x))  return(x)
    parse_json(x) %>%
    enframe() %>%
    unnest(value)
}

# Import the data and set up with initial geometry

dat <- read_csv("C:/code/p3_AshLee/hackathon_data/202107/core_poi-patterns.csv") %>%
    select(c('street_address','poi_cbg','latitude', 'longitude','raw_visit_counts','visitor_home_cbgs'))

# Flip to tibble (Only on visitor home cbgs, keeping other just in case)

datNest <- dat %>%
    mutate(
        visitor_cbg = map(visitor_home_cbgs, ~json_to_tibble(.x))
        )

# Verticle breakage

datNest2 <- datNest %>%
    select(street_address, poi_cbg, , latitude, longitude, visitor_cbg) %>%
    unnest(visitor_cbg) 

# Pull in census tables needed for calculations

def2 <- read_csv("C:/code/p3_AshLee/hackathon_data/safegraph_open_census_data_2019/data/cbg_b03.csv")
def4 <- read_csv("C:/code/p3_AshLee/hackathon_data/safegraph_open_census_data_2019/data/cbg_b01.csv")
def5 <- read_csv("C:/code/p3_AshLee/hackathon_data/safegraph_open_census_data_2019/data/cbg_b19.csv")

# Create other race column
def2 <- def2 %>%
    mutate(other = (B03002e5+B03002e7+B03002e8+B03002e9))

# create subset of just race counts
def3 <- def2 %>%
    select(census_block_group, B03002e1, B03002e3, B03002e4, B03002e6, B03002e12, other)

def4 = subset(def4, select = c(census_block_group,B01002e1))
def5 = subset(def5, select = c(census_block_group,B19013e1))

# merge race data with main data
datNest3 <- merge(datNest2, def3, by.x = c('name'), by.y = c('census_block_group'))
datNest3 <- merge(datNest3, def4, by.x = c('name'), by.y = c('census_block_group'))
datNest3 <- merge(datNest3, def5, by.x = c('name'), by.y = c('census_block_group'))

#pull down to one level head(datNest3)

datNest4 <- datNest3 %>%
        group_by(street_address, poi_cbg, latitude, longitude) %>%
        summarise(wam_age = weighted.mean(B01002e1,value,na.rm = TRUE)
                ,wam_income = weighted.mean(B19013e1,value,na.rm = TRUE)
                ,ttl_value = sum(value)
                ,ttl_population = sum(B03002e1)
                ,ttl_white = sum(B03002e3)
                ,ttl_black = sum(B03002e4)
                ,ttl_asian = sum(B03002e6)
                ,ttl_hispanic = sum(B03002e12)
                ,ttl_other = sum(other)
                ) %>%
        ungroup()

# Format the geometry
datNest4 <- datNest4 %>%
    st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# Pull in initial boundries

ga <- us_counties(states = "Georgia") %>%
    select(countyfp, countyns, name, aland, awater, state_abbr, geometry)

# Calculations in GA file

gaw <- ga %>%
    mutate(
        aland_acres = aland * 0.000247105,
        awater_acres = awater * 0.000247105,
        percent_water = 100 * (awater / aland),
        sf_area = st_area(geometry),
        sf_center = st_centroid(geometry),
        sf_length = st_length(geometry)
        )

# Combine data with initial boundries

dat2 <- st_join(datNest4, ga, join = st_within) %>%
    select(street_address, countyfp, name, wam_age, wam_income, ttl_value, ttl_population, ttl_white, ttl_black, ttl_asian, ttl_hispanic, ttl_other)

# Summarize by county (wam will work...need to work on totals)

dat3 <- dat2 %>%
        group_by(countyfp, name) %>%
        summarise(wam_age = weighted.mean(wam_age,ttl_value,na.rm = TRUE)
                ,wam_income = weighted.mean(wam_income,ttl_value,na.rm = TRUE)
                ,ttl_value = sum(ttl_value)
                ,ttl_population = sum(ttl_population)
                ,ttl_white = sum(ttl_white)
                ,ttl_black = sum(ttl_black)
                ,ttl_asian = sum(ttl_asian)
                ,ttl_hispanic = sum(ttl_hispanic)
                ,ttl_other = sum(ttl_other)
                ) %>%
        ungroup()

# Write out safegraph data to get on with it.  Work on mapping later
dat3 <- dat3 %>% as_tibble %>% select(-geometry)
write.csv('C:/code/p3_AshLee/data/202107_formatted_county_data.csv', x = datNest)


#####################################################  End


# Set up tibble to link over
ga_count <- dat2 %>%
    select(countyfp, name, wam_age, wam_income, ttl_value, ttl_population, ttl_white, ttl_black, ttl_asian, ttl_hispanic, ttl_other) %>%
    as_tibble()

# Final combination
gaw <- gaw %>%
    left_join(ga_count, by = 'countyfp') %>%
    replace_na(list(n = 0)) 

write.csv('C:/code/p3_AshLee/data/garbage2chk.csv', x = dat2)
