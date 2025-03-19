### Aquatic Forecast Workflow ###
# devtools::install_github("eco4cast/neon4cast")
library(tidyverse)
## ── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
## ✔ dplyr     1.1.4     ✔ readr     2.1.5
## ✔ forcats   1.0.0     ✔ stringr   1.5.1
## ✔ ggplot2   3.5.1     ✔ tibble    3.2.1
## ✔ lubridate 1.9.4     ✔ tidyr     1.3.1
## ✔ purrr     1.0.2     
## ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
## ✖ dplyr::filter() masks stats::filter()
## ✖ dplyr::lag()    masks stats::lag()
## ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
library(neon4cast)
library(lubridate)
#install.packages("rMR")
library(rMR)
## Loading required package: biglm
## Loading required package: DBI
forecast_date <- Sys.Date()
noaa_date <- Sys.Date() - days(1)  #Need to use yesterday's NOAA forecast because today's is not available yet

#Step 0: Define team name and team members 
team_info <- list(team_name = "air2waterSat_MCD",
                  team_list = list(list(individualName = list(givenName = "Mike", 
                                                              surName = "Dietze"),
                                        organizationName = "Boston University",
                                        electronicMailAddress = "dietze@bu.edu"))
)

## Load required functions
if(file.exists("01_download_data.R"))      source("01_download_data.R")
if(file.exists("02_calibrate_forecast.R")) source("02_calibrate_forecast.R")
if(file.exists("03_run_forecast.R"))       source("03_run_forecast.R")
if(file.exists("04_submit_forecast.R"))    source("04_submit_forecast.R")

### Step 1: Download Required Data
target     <- download_targets()       ## Y variables
## Rows: 218254 Columns: 4
## ── Column specification ────────────────────────────────────────────────────────
## Delimiter: ","
## chr  (2): site_id, variable
## dbl  (1): observation
## date (1): datetime
## 
## ℹ Use `spec()` to retrieve the full column specification for this data.
## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
site_data  <- download_site_meta()
## Rows: 81 Columns: 54
## ── Column specification ────────────────────────────────────────────────────────
## Delimiter: ","
## chr (34): field_domain_id, field_site_id, field_site_name, phenocam_code, ph...
## dbl (20): terrestrial, aquatics, phenology, ticks, beetles, field_latitude, ...
## 
## ℹ Use `spec()` to retrieve the full column specification for this data.
## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
target     <- merge_met_past(target)   ## append met data (X) into target file
met_future <- download_met_forecast(forecast_date) ## Weather forecast (future X)

## visual check of data
ggplot(target, aes(x = temperature, y = air_temperature)) +
  geom_point() +
  labs(x = "NEON water temperature (C)", y = "NOAA air temperature (C)") +
  facet_wrap(~site_id)
## Warning: Removed 38775 rows containing missing values or values outside the scale range
## (`geom_point()`).


met_future %>% 
  ggplot(aes(x = datetime, y = air_temperature, group = parameter)) +
  geom_line() +
  facet_grid(~site_id, scale ="free")


### Step 2: Calibrate forecast model
model <- calibrate_forecast(target)

### Step 3: Make a forecast into the future
forecast <- run_forecast(model,met_future,site_data)

#Visualize forecast.  Is it reasonable?
forecast %>% 
  ggplot(aes(x = datetime, y = prediction, group = parameter)) +
  geom_line() +
  facet_grid(variable~site_id, scale ="free")


### Step 4: Save and submit forecast and metadata
submit_forecast(forecast,team_info,submit=FALSE)
## aquatics-2025-01-23-air2waterSat_MCD.csv.gz
## ✔ file has model_id column✔ forecasted variables found correct variable + prediction column✔ temperature is a valid variable name✔ oxygen is a valid variable name✔ file has correct family and parameter columns✔ file has site_id column✔ file has datetime column✔ file has correct datetime column
## Warning: file missing duration column (values for the column: daily = P1D,
## 30min = PT30M, Weekly = P1W)
## Warning: file missing project_id column (use `neon4cast` as the project_id
## ✔ file has reference_datetime column
## Forecast format is valid
## Warning in system("git rev-parse HEAD", intern = TRUE): running command 'git
## rev-parse HEAD' had status 128