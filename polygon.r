    ###10/11/2021 - Polygons###

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

httpgd::hgd() #VScode
httpgd::hgd_browse() #VsCode


dat <- read_rds("/Users/ashleyrabanales/Projects_ST/p3_AshLee/data/chipotle_nested.rds")

dat <- dat %>%
    st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

select(dat, street_address, region, geometry)

cal <- USAboundaries::us_counties(states = "California")

ggplot() +
    geom_sf(data = cal) +
    geom_sf(data = filter(dat, region == "CA"))
    

ggplot() +
    geom_sf(data = cal, aes(fill = awater)) +
    geom_sf_text(data = cal, aes(label = name), color = "grey")

cal %>%
    select(-9) %>% # has state_name twice removing one.
    mutate(
        sf_area = st_area(geometry),
        sf_middle = st_centroid(geometry)
    )

chipotle_in_county <- st_join(dat, cal, join = st_within)

chipotle_in_county %>%
    as_tibble() %>%


##polygon2##

library(tidyverse)
library(sf)
library(USAboundaries)
library(leaflet)

httpgd::hgd() # for VSCode
httpgd::hgd_browse() # for VSCode

dat <- read_rds("/Users/ashleyrabanales/Projects_ST/p3_AshLee/data/chipotle_nested.rds") %>%
    st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

cal <- us_counties(states = "California") %>%
    select(countyfp, countyns, name, aland, awater, state_abbr, geometry)


cal %>%
    mutate(
        states_area = aland + awater,
        sf_area = st_area(geometry)) %>%
    select(name, states_area, aland, sf_area, awater) %>%
    filter(name == "Santa Barbara")

ksu <- tibble(lat = 34.037876, long = -84.58102) %>%
    st_as_sf(coords = c("long", "lat"), crs = 3310)

    # https://epsg.io/4326 units are degrees
calw <- cal %>%            #st_transform - changing the projections
    st_transform(3310) %>% # search https://spatialreference.org/ref/?search=california&srtext=Search. Units are in meters for buffer.
    filter(name != "San Francisco") %>%
    mutate(
        aland_acres = aland * 0.000247105,
        awater_acres = awater * 0.000247105,
        percent_water = 100 * (awater / aland),
        sf_area = st_area(geometry),
        sf_center = st_centroid(geometry),
        sf_length = st_length(geometry),
        sf_distance = st_distance(sf_center, ksu),
        sf_buffer = st_buffer(sf_center, 24140.2), # 24140.2 is 15 miles
        sf_intersects = st_intersects(., filter(., name == "Los Angeles"), sparse = FALSE)
        ) #89 intersects county that arent part to add to LA.



ggplot(data = calw) +
    geom_sf(aes(fill = sf_intersects)) + 
    geom_sf(aes(geometry = sf_buffer), fill = "white") +
    geom_sf(aes(geometry = sf_center), color = "darkgrey") +
    geom_sf_text(aes(label = name), color = "lightgrey") +
    geom_sf(data = filter(dat, region == "CA"), color = "black") + # our chipotle locations
    theme_bw() 

ggplot(data = calw) +
    geom_sf(aes(fill = sf_intersects)) + 
    geom_sf(aes(geometry = sf_buffer), fill =NA) +
    geom_sf(aes(geometry = sf_center), color = "darkgrey") +
    geom_sf_text(aes(label = name), color = "lightgrey") +
    geom_sf(data = filter(dat, region == "CA"), color = "black") + # our chipotle locations
    theme_bw() 

##the join chart build process
store_in_county <- st_join(dat, cal, join = st_within) %>%
    select(placekey, city, region, geometry, countyfp, name)


store_in_county_count <- store_in_county %>%
    as_tibble() %>% 
    count(countyfp, name) %>%
    filter(!is.na(countyfp)) # drop the NA counts.

calw <- calw %>%
    left_join(store_in_county_count, fill = 0) %>%
    replace_na(list(n = 0)) 

calw %>%
ggplot() +
    geom_sf(aes(fill = n)) + 
    scale_fill_continuous(trans = "sqrt") +
    geom_sf(data = filter(dat, region == "CA"), color = "white", shape = "x") +
    theme_bw() +
    theme(legend.position = "bottom") +
    labs(fill = "Number of Chipotle\nstores")


#Unnesting, calculating, then joining
#Creating our county group columns
#Notice how the sf object structure is kept for the left object dat and the non-geometry columns
# are brought into dat from the cal object.

dat_wc <- st_join(dat, cal, join = st_within) 

#Unnest and pivot - complicate join
days_week_long <- dat_wc %>%
    filter(region == "CA") %>%
    as_tibble() %>% # notice this line to break the sf object rules.
    rename(name_county = name) %>%
    unnest(popularity_by_day) %>%
    select(placekey, city, region, contains("raw"),
        name, value, geometry, countyfp, name_county)

#Now we have our table of popularity by day in long format. We want to move
#the days to columns with the counts by day in each column (pivot_wider())
days_week <-  days_week_long %>%
    pivot_wider(names_from = name, values_from = value)

days_week


#Calculating summaries
#Now we can create summaries using our new pivoted columns
# average visits per day over the n stores by county.
visits_day_join <- days_week %>%
    group_by(countyfp, name_county) %>%
    summarise(
        count = n(),
        Monday = sum(Monday, na.rm = TRUE) / count,
        Tuesday = sum(Tuesday, na.rm = TRUE) / count,
        Wednesday = sum(Wednesday, na.rm = TRUE) / count,
        Thursday = sum(Thursday, na.rm = TRUE) / count,
        Friday = sum(Friday, na.rm = TRUE) / count,
        Saturday = sum(Saturday, na.rm = TRUE) / count,
        Sunday = sum(Sunday, na.rm = TRUE) / count,
    ) %>%
    ungroup()

#Combining summaries back into our calw sf object.
calw <- calw %>%
    left_join(visits_day_join %>% select(-name_county)) %>%
    replace_na(list(Monday = 0, Tuesday = 0, Wednesday = 0,
      Thursday = 0, Friday = 0, Saturday = 0, Sunday = 0)) 

#Plotting Saturday use
#Let’s make a plot similar to our previous chart.
calw %>%
ggplot() +
    geom_sf(aes(fill = Saturday)) + 
    geom_sf(data = filter(dat, region == "CA"), color = "white", shape = "x") +
    theme_bw() +
    theme(legend.position = "bottom") +
    labs(fill = "Average store traffic", 
      title = "Saturday traffic for Chipotle")

#We can add our count variable to provide some additional insight
calw %>%
ggplot() +
    geom_sf(aes(fill = Saturday)) + 
    geom_sf(aes(geometry = sf_center, size = count), color = "grey") +
    theme_bw() +
    scale_size_continuous(breaks = c(1, 5, 10, 25, 50, 75),
      trans = "sqrt", range = c(2, 15)) +
    labs(
        fill = "Average store traffic",
        size = "Number of stores",
        title = "Saturday traffic for Chipotle")


#PLOTTING WITH LEAFLET
calw_4326 <- st_transform(calw, 4326) # will need in 4326 for leaflet 

bins <- c(0, 10, 20, 30, 50, 70, 90, 110)
pal <- colorBin("YlOrRd", domain = calw_4326$n)

m <- leaflet(calw_4326) %>%
    addPolygons(
        data = calw_4326,
        fillColor = ~pal(n),
        fillOpacity = .5,
        color = "darkgrey",
        weight = 2) %>%
    addCircleMarkers(
        data = filter(dat, region == "CA"),
        radius = 3,
        color = "grey") %>%
    addProviderTiles(providers$CartoDB.Positron)


    ###10/18 - A time and space example

    #package & data
library(tidyverse)
library(sf)
library(USAboundaries)
library(leaflet)
library(geofacet)

httpgd::hgd()
httpgd::hgd_browse()

dat <- read_rds("chipotle_nested.rds") %>%
    st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

states <- us_states() %>%
    filter(!state_name %in% c("Alaska", "Hawaii", "Puerto Rico")) %>%
    st_transform(4326)

##Build plotting data
#SPATIAL
dat_space <- dat %>%
    select(placekey, street_address, city, stusps = region, raw_visitor_counts) %>%
    filter(!is.na(raw_visitor_counts)) %>%
    group_by(stusps) %>%
    summarise(
        total_visitors = sum(raw_visitor_counts, na.rm = TRUE),
        per_store = mean(raw_visitor_counts, na.rm = TRUE),
        n_stores = n(),
        across(geometry, ~ sf::st_combine(.)),
    ) %>%
    rename(locations = geometry) %>%
    as_tibble()

states <- states %>%
    left_join(dat_space) 


#TEMPORAL
dat_space <- dat %>%
    select(placekey, street_address, city, stusps = region, raw_visitor_counts) %>%
    filter(!is.na(raw_visitor_counts)) %>%
    group_by(stusps) %>%
    summarise(
        total_visitors = sum(raw_visitor_counts, na.rm = TRUE),
        per_store = mean(raw_visitor_counts, na.rm = TRUE),
        n_stores = n(),
        across(geometry, ~ sf::st_combine(.)),
    ) %>%
    rename(locations = geometry) %>%
    as_tibble()

states <- states %>%
    left_join(dat_space) 


#PLOTS WITH GEOFACET    

dat_time %>%
    ggplot(aes(x = dayMonth, y = dayAverage)) +
    geom_point() +
    geom_smooth() +
    geom_text(
        aes(label = stores_label),
            x = -Inf, y = Inf,
            hjust = "left", vjust = "top") +
    facet_geo(~region, grid = "us_state_grid2", label = "name")

dat_time %>%
    ggplot(aes(x = dayMonth, y = dayAverage)) +
    geom_point() +
    geom_smooth() +
    geom_text(aes(label = stores_label),
        x = -Inf, y = Inf,
        hjust = "left", vjust = "top") +
    coord_cartesian(ylim = c(5, 25)) +
    facet_geo(~region, grid = "us_state_grid2", label = "name")

