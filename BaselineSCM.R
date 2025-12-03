# ==============================================================
# Script: Baseline_SCM.R
# Author: David Kreiner
# Description: Scales GDP data for NUTS2 regions and runs the Synthetic Control Method
# Usage: Run this script after loading the dataset via `Datensatz_SCM.R` and the Functions via `Functions.R`
# ==============================================================






# --------------------------------------------------------------
# 3. Prepare region and data frames
# --------------------------------------------------------------

# Extract all NUTS2 regions for the chosen country
Regions <- DATA %>%
  filter(str_starts(NUTS2, country)) %>%
  distinct(NUTS2) %>%
  pull(NUTS2)

# Initialize empty data frames for results
results_unaggregated <- data.frame()
all_datacheck <- data.frame()
all_donors <- data.frame()

# Create a code map for region names and numeric codes
code_map <- DATA %>%
  select(NUTS2, NUTS2_numeric, NAME_HTML) %>%
  distinct()

write.csv(code_map,here::here(Output_folder, "code_map.csv"))

# Extract control region IDs
control.ids <- code_map %>%
  filter(str_sub(NUTS2, 1, 2) %in% CONTROL_NUTS_CODE) %>%
  pull(NUTS2_numeric)

# --------------------------------------------------------------
# 4. Scale GDP data
# --------------------------------------------------------------

# Scaling GDP relative to 2021 to run the SCM based on trends
DATA <- DATA %>%
  group_by(NUTS2) %>%
  mutate(GDP_scaled = GDP / GDP[year == 2021]) %>%
  ungroup()

# Save Dataset for the loop
ORIGINAL_DATA <- as.data.frame(DATA)




# --------------------------------------------------------------
# 5. Run SCM for all selected regions
# --------------------------------------------------------------

# Apply run_scm_for_region function
results <- map(Regions, ~ run_scm_for_region(
  region_code = .x,
  data = ORIGINAL_DATA,
  control_codes = CONTROL_NUTS_CODE,
  code_map = code_map,
  predictors = predictors
))




# Expand results to dataframes
results_unaggregated <- map_dfr(results, "output")
all_donors <- map_dfr(results, "donors", .id = "Region")
all_datacheck <- map_dfr(results, "check", .id = "Region")










# --------------------------------------------------------------
# 6. Post-processing of results
# --------------------------------------------------------------
donors_extra <- all_donors

# Filter and format donor weights
all_donors <- all_donors %>%
  filter(w.weights >= 0.05) %>%
  arrange(Region, desc(w.weights)) %>%
  mutate(unit.names = paste0(unit.names, " (", w.weights, ")")) %>%
  select(-unit.numbers) %>%
  group_by(Region) %>%
  mutate(ColumnNumber = row_number()) %>%
  select(-w.weights) %>%
  pivot_wider(names_from = ColumnNumber, values_from = unit.names)

# Merge data check results with scaled GDPs
all_datacheck <- all_datacheck %>%
  left_join(
    results_unaggregated %>%
      filter(year == 2021) %>%
      select(NUTS, treatment_GDP),
    by = "NUTS"
  ) %>%
  select(Region, Treated, Synthetic, `Sample Mean`, metric, NUTS) %>%
  filter(metric %in% predictors)

# --------------------------------------------------------------
# 7. Compute average treatment effects (pre/post)
# --------------------------------------------------------------
results_unaggregated <- results_unaggregated %>%
  mutate(Difference = treatment_GDP - control_GDP,
         Difference_unscaled = treatment_GDP_unscaled - control_GDP_unscaled)

result <- results_unaggregated %>%
  filter(year != 2021) %>%
  mutate(Period = ifelse(year >= 2022, "post_treatment", "pre_treatment")) %>%
  group_by(NUTS, Period) %>%
  summarise(Estimate = mean(Difference), .groups = "drop") %>%
  pivot_wider(values_from = Estimate, names_from = Period) %>%
  select(NUTS, pre_treatment, post_treatment)

# Add mean row
mean_row <- result %>%
  summarise(
    NUTS = "Mean",
    pre_treatment = mean(pre_treatment, na.rm = TRUE),
    post_treatment = mean(post_treatment, na.rm = TRUE)
  )

result <- bind_rows(result, mean_row)

unscaled_estimate <- results_unaggregated %>% 
  filter(year>=2022) %>%
  summarise(unscaled_estimate = mean(Difference_unscaled))

unscaled_estimate_yearly <- results_unaggregated %>%
  filter(year>= 2022) %>%
  group_by(year)%>%
  summarise(unscaled_estimate = mean(Difference_unscaled))

# --------------------------------------------------------------
# 8. Export results
# --------------------------------------------------------------
write.csv(result, here::here(Output_folder,"result.csv"), row.names = FALSE)
write.csv(all_datacheck, here::here(Output_folder,"all_predictors.csv"), row.names = FALSE)
write.csv(all_donors, here::here(Output_folder,"all_donors.csv"), row.names = FALSE)
write.csv(results_unaggregated, here::here(Output_folder,"results_unaggregated.csv"), row.names = FALSE)
write.csv(donors_extra, here::here(Output_folder,"donors_extra.csv"), row.names = FALSE)
write.csv(unscaled_estimate, here::here(Output_folder,"unscaled_estimate.csv"), row.names = FALSE)
write.csv(unscaled_estimate_yearly, here::here(Output_folder,"unscaled_estimate_yearly.csv"), row.names = FALSE)


