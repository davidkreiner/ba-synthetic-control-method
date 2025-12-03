# --------------------------------------------------------------
# run_scm_for_region -> Funktion zum Ausführen der Basis SCM-Analyse für eine Region
# --------------------------------------------------------------
  


run_scm_for_region <- function(region_code, data, control_codes, code_map,predictors) {
  
  # Reset
  DATA <- data
  

  
  # Lookup treatment
  treatment.id <- code_map %>%
    filter(NUTS2 == region_code) %>%
    pull(NUTS2_numeric)
  
  treatment.name <- code_map %>%
    filter(NUTS2 == region_code) %>%
    pull(NAME_HTML)
  
  treatment_2021 <- DATA %>%
    filter(year == 2021 & NUTS2 == region_code) %>%
    pull(GDP)
  
  # Scale GDP relative to treatment region
  DATA <- DATA %>%
    mutate(GDP_scaled_21 = GDP_scaled * treatment_2021)
  
  # Prepare data for Synth
  dataprep.out <- dataprep(
    foo = DATA,
    dependent = "GDP_scaled",
    predictors = predictors,
    time.variable = "year",
    treatment.identifier = treatment.id,
    controls.identifier = code_map %>%
      filter(str_sub(NUTS2, 1, 2) %in% control_codes & NUTS2_numeric != treatment.id) %>%
      pull(NUTS2_numeric),
    time.predictors.prior = 2015:2021,
    time.optimize.ssr = 2015:2021,
    unit.variable = "NUTS2_numeric",
    unit.names.variable = "NAME_HTML",
    time.plot = 2015:2026,
    predictors.op = "mean",
    special.predictors = list(
      list("GDP_scaled", 2019, "mean"),
      list("GDP_scaled", 2016, "mean")
    )
  )
  
  synth.out <- synth(dataprep.out, optimxmethod = "All")
  
  # Extract results
  output <- as.data.frame(cbind(
    dataprep.out$Y1plot,
    dataprep.out$Y0plot %*% synth.out$solution.w
  ))
  colnames(output)[1] <- "treatment_GDP"
  output <- output %>%
    rename(control_GDP = "w.weight") %>%
    mutate(
      Region = treatment.name,
      NUTS = region_code,
      year = as.numeric(rownames(output)),
      treatment_GDP_unscaled = treatment_GDP,
      control_GDP_unscaled = control_GDP,
      treatment_GDP = treatment_GDP * treatment_2021,
      control_GDP = control_GDP * treatment_2021
    )
  

  
  return(list(
    output = output,
    donors = synth.tab(dataprep.res = dataprep.out, synth.res = synth.out)$tab.w%>%
      mutate("NUTS" = region_code),
    check = as.data.frame(synth.tab(dataprep.res = dataprep.out, synth.res = synth.out)$tab.pred)%>%
      mutate("NUTS" = region_code,
             "metric" = rownames(.))
  ))
}




# --------------------------------------------------------------
# placebo_function -> Funktion zum Erstellen von zufälligen Placebo-Permutations-Szenarios für die Inferenzanalyse
# --------------------------------------------------------------

placebo_function<- function(permutation){
  set.seed(permutation)
  write(paste(Sys.time(), "Starte Durchlauf", permutation), file = "log.txt", append = TRUE)
  
  # code map erstellen
  code_map <- DATA %>%
    select(NUTS2, NUTS2_numeric, NAME_HTML) %>%
    distinct()
  
  
  # Potentielle Kontrollgruppe
  CONTROL_NUTS_CODE <- c("DE","NL","FI","DK","SE","IE","LU")
  
  potential_control <- code_map %>%
    filter(str_sub(NUTS2, 1, 2) %in% CONTROL_NUTS_CODE) %>%
    pull(NUTS2)
  
  # Sample von 21 Regionen ziehen
  country <- sample(potential_control,length(Regions))
  
  
  
  #### Alle Regionen des Landes, leerer Ergebnis df
  Regions  <- DATA %>%
    filter(NUTS2 %in% country) %>%
    distinct(NUTS2) %>%
    pull(NUTS2)
  
  all_output <- data.frame()
  
  
  control.ids <- code_map %>%
    filter(str_sub(NUTS2, 1, 2) %in% CONTROL_NUTS_CODE) %>%
    filter(!(NUTS2 %in% country)) %>%
    pull(NUTS2_numeric)
  
  
  
  # scaling auf 1
  DATA <- DATA %>%
    group_by(NUTS2) %>%
    mutate(GDP_scaled = GDP / GDP[year == 2021]) %>%
    ungroup()
  
  
  DATA <- as.data.frame(DATA)
  ORIGINAL_DATA <- DATA
  
  
  
  
  
  
  ## Schleife über alle Regionen
  for(Region in Regions) {
    
    DATA <- ORIGINAL_DATA  # <- zurücksetzen
    
    
    
    
    
    
    ####### Numerische NUTS Codes für treatment und Kontrollregion raussuchen:
    
    treatment.id <- code_map %>%
      filter(NUTS2 == Region) %>%
      pull(NUTS2_numeric)
    
    
    
    treatment.name <- DATA %>%
      group_by(NUTS2) %>%
      summarise(NAME_HTML = first(NAME_HTML)) %>%
      filter(NUTS2 == Region) %>%
      pull(NAME_HTML)
    
    
    
    
    
    
    
    # Verwendung von NUTS2_numeric als unit.variable in dataprep
    dataprep.out <- dataprep(
      foo = DATA,  # Dein Datensatz
      dependent = "GDP_scaled",  # Abhängige Variable (hier GDP)
      predictors = c("LN_POP","DENS","CAPITAL","EDUC"), 
      time.variable = "year",  # Zeitvariable (hier Jahr)
      treatment.identifier = treatment.id,  # Behandelte Region (hier Spanien)
      controls.identifier = control.ids,  # Kontrollregionen (DE, NL, AT)
      time.predictors.prior = 2015:2021,  # Zeitperiode vor der Intervention (2015-2019)
      time.optimize.ssr = 2015:2021 , # Optimierungszeitraum (2015-2019)
      unit.variable = "NUTS2_numeric",  # Verwendet NUTS2_numeric als numerische Einheit
      unit.names.variable = "NAME_HTML",
      time.plot = 2015:2026,
      predictors.op = "mean",
      special.predictors = list(list("GDP_scaled",2019,"mean"),
                                list("GDP_scaled",2016,"mean")))
    
    
    
    synth.out <- tryCatch({
      synth(dataprep.out, optimxmethod = c("Nelder-Mead","BFGS"))
    }, error = function(e) {
      # Fehlertext holen
      msg <- conditionMessage(e)
      
      # Wenn es nur ein numerisches Problem ist → trotzdem weitermachen
      if (grepl("computationally singular", msg, ignore.case = TRUE)) { 
        return("singular")  # Marker, um später ggf. zu handeln
      }
      
      # Bei echten Fehlern abbrechen
      return(NULL)
    })
    
    # Falls Fehler: Funktion vorzeitig verlassen
    if (is.null(synth.out)) return(NULL)    
    
    
    
    output <- as.data.frame(cbind(dataprep.out$Y1plot,dataprep.out$Y0plot %*% synth.out$solution.w))
    colnames(output)[1] <- "treatment_GDP" 
    output <- output %>%
      rename(control_GDP = "w.weight") %>%
      mutate(Region = treatment.name,
             NUTS = Region, 
             year = rownames(output),
             treatment_GDP = treatment_GDP,
             control_GDP = control_GDP)
    
    
    
    all_output <- rbind(all_output, output)
    
  }
  
  
  # all output mit allen jahren von allen regionen
  # result mit nur pre und post pro region
  
  all_output <- all_output %>% 
    mutate(Difference = treatment_GDP - control_GDP,
           Permutation = permutation)
  
  
  result <- all_output %>%
    filter(year != 2021) %>%
    mutate(Period = ifelse(year >= 2022,"post_treatment","pre_treatment")) %>%
    group_by(NUTS,Period) %>%
    summarise(Estimate = mean(Difference)) %>%
    pivot_wider(values_from = Estimate, names_from = Period) %>%
    select("NUTS","pre_treatment","post_treatment") 
  
  mean_row <- result %>%
    group_by() %>%
    summarise(
      NUTS = "Mean",
      `pre_treatment` = mean(`pre_treatment`),
      `post_treatment` = mean(`post_treatment`)
    )
  
  result <- rbind(result,mean_row) %>%
    mutate(Permutation = permutation)
  
  mean_row <- mean_row %>% mutate(Permutation = permutation)
  write(paste(Sys.time(), "Fertig mit:", permutation), file = "log_fertig.txt", append = TRUE)
  
  
  
  return(list(mean_row,all_output))

}


