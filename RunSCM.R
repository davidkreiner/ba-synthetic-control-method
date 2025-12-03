# --------------------------------------------------------------
# 1. Define relevant Parameters:
# --------------------------------------------------------------

country <- "ITC" # Treated country
CONTROL_NUTS_CODE <- c("DE", "NL", "FI", "DK", "SE", "IE", "LU")
num_cores <- detectCores()-1
number_permutations <- 1500
predictors <- c("LN_POP","DENS","CAPITAL","EDUC")
Output_folder <- "Output"


# --------------------------------------------------------------
# 2. Load required packages and create directories
# --------------------------------------------------------------
if (!require("pacman")) install.packages("pacman")
library(pacman)
pacman::p_load(Synth, dplyr, ggplot2, stringr, knitr, kableExtra, webshot2, tidyr,purrr)

if(!dir.exists(Output_folder)) dir.create(Output_folder)

subfolders <- c("plots/results", "plots/placebo")


for(sub in subfolders){
  folder_path <- here::here(Output_folder, sub)
  if(!dir.exists(folder_path)) dir.create(folder_path, recursive = TRUE)
}
# --------------------------------------------------------------
# 3. Run scripts
# --------------------------------------------------------------
source(here::here("Scripts","Functions.R"))
source(here::here("Scripts","Dataset.R"))
source(here::here("Scripts","BaselineSCM.R"))
source(here::here("Scripts","Dataset.R"))
source(here::here("Scripts","Placebo.R"))


rmarkdown::render(input = here::here("BA_Github.rmd"),output_format="pdf_document",
                  params = list(Output_folder = Output_folder),
                  envir = globalenv())




