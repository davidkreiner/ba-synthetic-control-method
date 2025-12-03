library(pacman)
pacman::p_load(Synth,dplyr,ggplot2,stringr, knitr, kableExtra, webshot2,tidyr,parallel,purrr)
#### ACHTUNG in output wurde *treatment2021 entfernt 

write("", file = "log.txt")
write("", file = "log_fertig.txt")



# Cluster starten
cl <- makeCluster(1)

clusterExport(cl, varlist = c("DATA","Regions"), envir = environment())
clusterEvalQ(cl, {
  library(dplyr)
  library(tidyr)
  library(Synth)
  library(stringr)
})




Placebo_results_list <- parLapply(cl, 1:number_permutations, placebo_function)


stopCluster(cl)


Placebo_general <- Placebo_results_list %>%
  map(~ .x[[1]]) %>%   
  bind_rows()         

Placebo_yearly <- Placebo_results_list %>%
  map(~ .x[[2]]) %>%   
  bind_rows()         





write.csv(Placebo_general, here::here(Output_folder,"Placebo_general.csv"))
write.csv(Placebo_yearly, here::here(Output_folder,"Placebo_yearly.csv"))



p_wert <- mean(abs(Placebo_general$post_treatment) >= abs(0.032291858))

p_wert






