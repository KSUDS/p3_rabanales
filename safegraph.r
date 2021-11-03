library(tidyverse)
install.packages("jsonlite")
library(jsonlite)
library(ggplot2)
library(dbplyr)
library(sf)

#2019
year19 <- read.csv("/Users/ashleyrabanales/Projects_ST/p3_AshLee/data/201907_formatted_county_data.csv")

dat19 <- year19 %>%
  mutate(year = "2019") 

  Gwinnett1 <- dat19 %>%
  filter(name == "Gwinnett")

Fulton1 <- dat19 %>%
  filter(name == "Fulton")

Forsyth1 <- dat19 %>%
  filter(name == "Forsyth")

Cherokee1 <- dat19 %>%
  filter(name == "Cherokee")

Fayette1 <- dat19 %>%
  filter(name == "Fayette")

Cobb1 <- dat19 %>%
  filter(name == "Cobb")

Columbia1 <- dat19 %>%
  filter(name == "Columbia")

Oconee1 <- dat19 %>%
  filter(name == "Oconee")

Dawson1 <- dat19 %>%
  filter(name == "Dawson")

DeKalb1 <- dat19 %>%
  filter(name == "DeKalb")


counties19 <- rbind(Gwinnett1, Fulton1, Forsyth1, Cherokee1, Fayette1, Cobb1, Columbia1, Oconee1, Dawson1, DeKalb1)


#2021

year21 <- read.csv("/Users/ashleyrabanales/Projects_ST/p3_AshLee/data/202107_formatted_county_data.csv")

dat21 <- year21 %>%
  mutate(year = "2021") %>%
  filter(name == "Gwinnett", "Fulton", "Forsyth", "Cherokee","Fayette",
         "Cobb", "Columbia", "Oconee", "Dawson", "DeKalb")

Gwinnett <- dat21 %>%
  filter(name == "Gwinnett")

Fulton <- dat21 %>%
  filter(name == "Fulton")

Forsyth <- dat21 %>%
  filter(name == "Forsyth")

Cherokee <- dat21 %>%
  filter(name == "Cherokee")

Fayette <- dat21 %>%
  filter(name == "Fayette")

Cobb <- dat21 %>%
  filter(name == "Cobb")

Columbia <- dat21 %>%
  filter(name == "Columbia")

Oconee <- dat21 %>%
  filter(name == "Oconee")

Dawson <- dat21 %>%
  filter(name == "Dawson")

DeKalb <- dat21 %>%
  filter(name == "DeKalb")

counties21 <- rbind(Gwinnett, Fulton, Forsyth, Cherokee, Fayette, Cobb, Columbia, Oconee, Dawson, DeKalb)

#######

ggplot(total_counties, aes(x = name, y=wam_age, color = year)) +  
  geom_point (aes(name)) +
  labs ( x = "County", y ="Age", 
         title = "Average Age in County",
         subtitle = "Change in the Average Age by County, 2019 and 2021",
         caption = "Source: SafeGraph", color = "Year"
  ) + scale_color_manual(values=c("brown3", "blue1"))


ggsave(filename = "age.png", width = 10, height = 7)



ggplot(total_counties, aes(x = name, y=wam_income, color = year)) +  
      geom_point (aes(wam_age)) +
      geom_line(aes(wam_age)) +
      labs ( x = "Age", y ="Income", 
             title = "Annual Income ",
             subtitle = "Income In Year by the Average Age, 2019 and 2021",
             caption = "Source: SafeGraph", color = "Year"
             ) + scale_color_manual(values=c("darkolivegreen3", "steelblue2"))
  

ggsave(filename = "income_in_year_by_age.png", width = 10, height = 7)




#######################


datNest4 <- read.csv("/Users/ashleyrabanales/Projects_ST/p3_AshLee/data/v1_base_with_census_metrics.csv")

datNest4 <- datNest4 %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)  # i omitted lat/long...needed?

ga <- USAboundaries::us_counties(states = 'Georgia')

# Join data
gas_in_ga <- st_join(datNest4, ga, join = st_within)
# remove duplicate state
gas_in_ga <- gas_in_ga %>% select(-24)

# Write the joined mapping data
write.csv('/Users/ashleyrabanales/Projects_ST/p3_AshLee/data/v1_base_with_census_metrics.csv', x = gas_in_ga)

#Income, Total Pop
ggplot(data = gas_in_ga) +
  geom_sf(aes(color = wam_income, size = ttl_population)) +
  scale_fill_viridis_c(option = "plasma", trans = "sqrt") 
#geom_sf(data = filter(gas_in_ga, region == "GA"))
#geom_sf_text(data = ga, aes(label = name), color = "#da0a0a")

#Income, white
ggplot()+
  geom_sf(data = ga) +
  geom_sf(data = gas_in_ga, aes(color = wam_income, size = ttl_white)) +
  scale_fill_viridis_c(option = "plasma", trans = "sqrt")
#Income, black
ggplot()+
  geom_sf(data = ga) +
  geom_sf(data = gas_in_ga, aes(color = wam_income, size = ttl_black)) +
  scale_fill_viridis_c(option = "plasma", trans = "sqrt")
#Income, asian
ggplot()+
  geom_sf(data = ga) +
  geom_sf(data = gas_in_ga, aes(color = wam_income, size = ttl_asian)) +
  scale_fill_viridis_c(option = "plasma", trans = "sqrt")

#Age difference thru state
ggplot(data = gas_in_ga) +
  geom_sf(aes(color = wam_age))


ggplot()+
  geom_sf(data = ga) +
  geom_sf(data = gas_in_ga, aes(color = wam_income, size = ttl_asian)) +
  scale_fill_viridis_c(option = "plasma", trans = "sqrt")


ggplot()+
  geom_sf(data = ga) +
  geom_sf(data = gas_in_ga, aes(color = ttl_value)) +
  scale_fill_viridis_c(option = "plasma", trans = "sqrt")



##Making a graph

#geom_sf_text(data = ga, aes(label = name), color = "grey")


#comparing the years to county in the census gov
#aggerating county
#median age by county year over year. 
#seeing the change from 19 / 20 

#create an age group
#seperate and combine those near to cobb county. 


#exporting the data into python
remotes::install_github("ropensci/USAboundaries")
remotes::install_github("ropensci/USAboundariesData")
install.packages("sfarrow")

#exporting out the data 
#install.packages("sfarrow")
library(USAboundaries)
library(sfarrow)
library(tidyverse)
library(sf)

usa <- USAboundaries::us_boundaries() %>%
    st_transform(4326)

usa_counties <- USAboundaries::us_counties() %>%
    select(-state_name) %>%
    st_transform(4326)

usa_cities <- USAboundaries::us_cities() %>%
    st_transform(4326)



sfarrow::st_write_feather(usa, "data/usa.feather")
sfarrow::st_write_parquet(usa, "data/usa.parquet")

sfarrow::st_write_feather(usa_counties, "usa_counties.feather")
sfarrow::st_write_parquet(usa_counties, "usa_counties.parquet")

sfarrow::st_write_feather(usa_cities, "data/usa_cities.feather")
sfarrow::st_write_parquet(usa_cities, "data/usa_cities.parquet")

#Apache Arrow? open source, farme work of datawork from other people. Two packages parka and feathers
#geopandas can read it in, quicker, faster, and less space.