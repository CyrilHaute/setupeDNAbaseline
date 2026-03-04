############################################################
#
# 01_clean_spygen_data.R: clean spygen eDNA raw data
#
############################################################

# Load required functions
source("R/01_clean_eDNA_functions.R")

# Set directory to save cleaned eDNA data
dir.create("outputs")
dir.create("outputs/01_clean_eDNA")
dir_save <- "outputs/01_clean_eDNA/"

# This function convert spygen raw data to a site X species matrix

spygen_matrix <- convert_to_matrix_function(raw_spygen_path = "data/raw-data/eDNA_raw_data/1.Results_Med_2018-Oct2025.xlsx")

# This function remove misidentified species and check their names from FishBase

spygen_matrix_clean <- species_clean_function(spygen_matrix = spygen_matrix)
write.csv(spygen_matrix_clean$spygen_matrix_clean, file = paste0(dir_save, "1.spygen_2018_2025.csv"), row.names = FALSE)

which_diff <- which(!colnames(spygen_matrix_clean$spygen_matrix_clean) %in% colnames(spygen_matrix_clean$spygen_matrix_old))
colnames(spygen_matrix_clean$spygen_matrix_clean)[which_diff]
colnames(spygen_matrix_clean$spygen_matrix_old)[which_diff]


# Créer une fonction qui permet d'ajouter de nouvelles données aux anciennes, supprimer les doublons de l'ancien fichier (Med) car corresponds à une nouvelle version de la base de ref
# si la version est la même, verifier que les espèces et le nombre de read sont les mêmes. Normalement on est sensé ecrasé 

spygen1_2 <- spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/1.spygen_2018_2025.csv",
                                      new_spygen_data_path = "data/raw-data/eDNA_raw_data/2.Teleo_SC21076_DPH_15_08-12-2025.xlsx",
                                      path_save = paste0(dir_save, "spygen1_2.csv"))

spygen2_3 <- spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen1_2.csv",
                                      new_spygen_data_path = "data/raw-data/eDNA_raw_data/3.Teleo_SC21076_DPH_15_12012026_V2.xlsx",
                                      path_save = paste0(dir_save, "spygen2_3.csv"))

spygen3_4 <- spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen2_3.csv",
                                      new_spygen_data_path = "data/raw-data/eDNA_raw_data/4.Teleo_SC23148_AMS_Corse_25-10_12122025_complet.xlsx",
                                      path_save = paste0(dir_save, "spygen3_4.csv"))

spygen4_5 <- spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen3_4.csv",
                                      new_spygen_data_path = "data/raw-data/eDNA_raw_data/5.Teleo_SC23148_AMS_Occ_25_14_021225.xlsx",
                                      path_save = paste0(dir_save, "spygen4_5.csv"))

spygen5_6 <- spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen4_5.csv",
                                      new_spygen_data_path = "data/raw-data/eDNA_raw_data/6.Teleo_SC23148_AMS_Occ_25_14_130126-V2.xlsx",
                                      path_save = paste0(dir_save, "spygen5_6.csv"))


# This function create a subset of eDNA data (by spygen_code) and return only species present in the subset area

test <- read.csv("data/raw-data/Med_metadonnees_ADNe - v1.2_2018-2025.csv", header = TRUE)
spain_test <- test[test$country == "Spain",]

subset_test <- spygen_subset_function(eDNA_species_data_path = "outputs/1.Results_Med_2018-Oct2025_site_species_matrix.csv",
                                      spygen_code_subset = spain_test) # If spygen_code_subset is a dataframe
subset_test2 <- spygen_subset_function(eDNA_species_data_path = "outputs/1.Results_Med_2018-Oct2025_site_species_matrix.csv",
                                       spygen_code_subset = spain_test$spygen_code) # If spygen_code_subset is a vector of character
