library(pacman)
pacman::p_load(dplyr,stringr,tidyr,here)
"https://ec.europa.eu/eurostat/databrowser/explore/all/economy?lang=en&subtheme=gov&display=list&sort=category"



##### Daten einlesen

GDP <- read.csv(here("data", "ARDECO_GDP.csv"))
EDUC <- read.csv(here("data", "ARDECO_EDUCATION.csv"))
POP <- read.csv(here("data", "ARDECO_POPULATION.csv"))
CAPITAL <- read.csv(here("data", "ARDECO_GFCF.csv"))
AREA <- read.csv(here("data", "EUROSTAT_AREA.csv"))



###### Einzelne Datensätze vorbereiten

GDP <- GDP %>% 
  filter(UNIT == "EUR") %>%
  pivot_longer(cols = starts_with("X"), names_to = "year" ) %>%
  mutate(GDP = value,
         year = as.character(substr(year,2,5)),
         NUTS2 = TERRITORY_ID) %>%
  filter(LEVEL_ID == 2) %>%
  select(-"value",-"TERRITORY_ID",-"LEVEL_ID",-"VERSIONS",-"UNIT") %>%
  filter(year >= 2015)

CAPITAL <- CAPITAL %>% 
  filter(UNIT == "Million EUR") %>%
  pivot_longer(cols = starts_with("X"), names_to = "year" ) %>%
  mutate(CAPITAL = value,
         year = as.character(substr(year,2,5)),
         NUTS2 = TERRITORY_ID) %>%
  filter(LEVEL_ID == 2) %>%
  select("NUTS2","year","CAPITAL") %>%
  filter(year >= 2015)

EDUC <- EDUC %>%
  pivot_longer(cols = starts_with("X"), names_to = "year" ) %>%
  mutate(EDUC = value,
         year = as.character(substr(year,2,5)),
         NUTS2 = NUTS) %>%
  filter(nchar(NUTS2) == 4) %>%
  select("NUTS2","year","EDUC") %>%
  filter(year >= 2015)

POP <- POP %>% 
  filter(LEVEL_ID == 2, SEX == "Total", AGE == "Total") %>%
  pivot_longer(cols = starts_with("X"), names_to = "year" ) %>%
  mutate(POP = value,
         year = as.character(substr(year,2,5)),
         NUTS2 = TERRITORY_ID) %>%
  select("NUTS2","year","POP") %>%
  filter(year >= 2015) 



AREA <- AREA %>%
  mutate(NUTS2 = substr(geo,1,4),
         year = as.character(TIME_PERIOD),
         AREA = OBS_VALUE) %>%
  select("NUTS2","year","AREA")

#########LN WIEDER EINFÜGEN!!!!!!!!!
DENS <- left_join(POP,AREA,by = c("NUTS2","year")) %>%
  mutate(DENS = POP/AREA,
         LN_POP = log(POP)) %>%
  select(-"POP",-"AREA")

rm(AREA,POP)




###### Datensete mergen

DATA <- left_join(GDP,EDUC, by = c("NUTS2","year"))

DATA <- left_join(DATA,DENS, by = c("NUTS2","year"))

DATA <- left_join(DATA, CAPITAL, by = c("NUTS2","year"))




####### NUTS2 numerisch für Synth

DATA <- DATA %>%
  mutate(year = as.numeric(year),
         NUTS2_numeric = as.numeric(as.factor(NUTS2))) %>% 
  mutate(CAPITAL = CAPITAL/GDP)

  



rm(CAPITAL,DENS,EDUC,GDP)


#### sicherstellen dass DATA ein dataframe ist

DATA <- as.data.frame(DATA)


write.csv(DATA, here::here(Output_folder, "data.csv"))

