# ba-synthetic-control-method
This repository contains the R and RMarkdown code used for my bachelor’s thesis: "Next Generation EU and Regional Economic Growth in Italy: An Empirical Analysis Using the Synthetic Control Method."

## Data
The estimation uses data from Eurostat on NUTS2 level. The Synthetic control method was used for each italian NUTS 2 region individually and individual effects, as well as timewise- and regionalwise- aggregated effects are calculated.

## Scripts
- `RunSCM.R` is the main script. Parameters have to be defined in this script. After setting the relevant parameters, RunSCM.r loads the required packages and runs all the other scripts. The main output is a raw pdf document with visualisations of all the results. These are the results I used in my bachelors thesis. A description of the parameters can be found below. 

- `Functions.R` is a script that loads 2 functions
        - the first function "run_scm_for_region" runs the scm for a given region and a given donor pool as well as a set of             predictors
        - The second function "placebo_function" creates one random placebo SCM, for the donor pool as well as the set of               predictors
  
- `Dataset.R` reads all the Eurostat datasets and combines them and saves "data.csv"
  
- `BaselineSCM.R` uses the run_scm_for_region function and applies it to every selected NUTS2 region. It post-processes the        results and saves the dataframes "results.csv","all_predictors.csv", "all_donors.csv", "results_unaggregated.csv",           "donors_extra.csv", "unscaled_estimate.csv" and "unscaled_estimate_yearly.csv"

- `Placebo.R` applies the placebo_function in a parallelized way for a given number of permutations and post-processes the    results. It saves the dataframes "Placebo_general.csv", a aggregated collection of the placebo results, and   	             "Placebo_yearly.csv", the unaggregated counterpart. 

- `BA_Github.rmd` loads the results and creates a variety of tables and plots that are then rendered into a pdf document.


## Parameters
  - `country` ... this parameter sets the country for which the analysis should be done. The standard value (out of my        bachelors thesis) is IT. If all NUTS2 Regions of a country should be selected, the country identifier (e.g.IT)         should be used. If only the NUTS2 subregions of a NUTS1 region should be used it is also possible to use NUTS1 identifiers (e.g.ITC) or even just one single NUTS2 Region (e.g.ITC1)

  - `CONTROL_NUTS_CODE` ... this is a vector of all the country identifiers of the countries that are used in the donor pool   of potential control units.

  - `num_cores` ... this parameter sets the number of cores that should be used for parallel processing of the tasks. The standard value is the number of all cores minus 1.

  - `number_permutations` ... this parameter sets the number of permutations that are done in the placebo-inference procedure. A too high number of permutations may lead to long computing times. The standard value is 1500 as used in my bachelors thesis, but for simple replication of the results a lower number is recommended.

  - `predictors` ... this is a vector of the predictors that are used in the SCM procedure. The standard value is using allthe predictors from my bachelors thesis (i.e. "LN_POP","DENS","CAPITAL","EDUC")
