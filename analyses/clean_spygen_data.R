source("R/function.R")

spygen_matrix <- convert_to_matrix_function(raw_spygen_path = "data/raw-data/Results_Med_2018-Oct2025.xlsx")

spygen_matrix_clean <- species_clean_function(spygen_matrix = spygen_matrix)
