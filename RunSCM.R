# --------------------------------------------------------------
# 1. Define relevant Parameters:
# --------------------------------------------------------------

country <- "ITC" # Treated country
CONTROL_NUTS_CODE <- c("DE", "NL", "FI", "DK", "SE", "IE", "LU")
num_cores <- detectCores()-1
number_permutations <- 1500
predictors <- c("LN_POP","DENS","CAPITAL","EDUC")
Output_folder <- "Output1"


# --------------------------------------------------------------
# 2. Load required packages
# --------------------------------------------------------------
if (!require("pacman")) install.packages("pacman")
library(pacman)
pacman::p_load(Synth, dplyr, ggplot2, stringr, knitr, kableExtra, webshot2, tidyr,purrr)


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



