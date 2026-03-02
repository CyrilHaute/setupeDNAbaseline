source("R/function.R")

# This function convert spygen raw data to a site X species matrix

spygen_matrix <- convert_to_matrix_function(raw_spygen_path = "data/raw-data/eDNA_raw_data/1.Results_Med_2018-Oct2025.xlsx")


# This function remove misidentified species and check their names from fishbase

spygen_matrix_clean <- species_clean_function(spygen_matrix = spygen_matrix)

which_diff <- which(!colnames(spygen_matrix_clean$spygen_matrix_clean) %in% colnames(spygen_matrix_clean$spygen_matrix_old))
colnames(spygen_matrix_clean$spygen_matrix_clean)[which_diff]
colnames(spygen_matrix_clean$spygen_matrix_old)[which_diff]

write.csv(spygen_matrix_clean$spygen_matrix_clean, file = "outputs/1.Results_Med_2018-Oct2025_site_species_matrix.csv",
          row.names = FALSE)

# Créer une fonction qui permet d'ajouter de nouvelles données aux anciennes, supprimer les doublons de l'ancien fichier (Med) car corresponds à une nouvelle version de la base de ref
# si la version est la même, verifier que les espèces et le nombre de read sont les mêmes. Normalement on est sensé ecrasé 

# Créer une fonction pour sélectionner des filtres spygen avec uniquement les espèces correspondantes à ces filtres

spygen1_2 <- spygen_new_data_function(old_spygen_data_path = "outputs/1.Results_Med_2018-Oct2025_site_species_matrix.csv",
                                      new_spygen_data_path = "data/raw-data/eDNA_raw_data/2.Teleo_SC21076_DPH_15_08-12-2025.xlsx")
write.csv(spygen1_2, file = "outputs/spygen1_2.csv", row.names = FALSE)

spygen2_3 <- spygen_new_data_function(old_spygen_data_path = "outputs/spygen1_2.csv",
                                      new_spygen_data_path = "data/raw-data/eDNA_raw_data/3.Teleo_SC21076_DPH_15_12012026_V2.xlsx")
write.csv(spygen2_3, file = "outputs/spygen2_3.csv", row.names = FALSE)

spygen3_4 <- spygen_new_data_function(old_spygen_data_path = "outputs/spygen2_3.csv",
                                      new_spygen_data_path = "data/raw-data/eDNA_raw_data/4.Teleo_SC23148_AMS_Corse_25-10_12122025_complet.xlsx")
write.csv(spygen3_4, file = "outputs/spygen3_4.csv", row.names = FALSE)

spygen4_5 <- spygen_new_data_function(old_spygen_data_path = "outputs/spygen3_4.csv",
                                      new_spygen_data_path = "data/raw-data/eDNA_raw_data/5.Teleo_SC23148_AMS_Occ_25_14_021225.xlsx")
write.csv(spygen4_5, file = "outputs/spygen4_5.csv", row.names = FALSE)

spygen5_6 <- spygen_new_data_function(old_spygen_data_path = "outputs/spygen4_5.csv",
                                      new_spygen_data_path = "data/raw-data/eDNA_raw_data/6.Teleo_SC23148_AMS_Occ_25_14_130126-V2.xlsx")
write.csv(spygen5_6, file = "outputs/spygen5_6.csv", row.names = FALSE)


# eDNA_raw_data <- list.files("data/raw-data/eDNA_raw_data", full.names = TRUE)
# 
# spygen_matrix_all <- pbmcapply::pbmclapply(1:length(eDNA_raw_data), function(i) {
#   
#   spygen_matrix_i <- convert_to_matrix_function(raw_spygen_path = eDNA_raw_data[i])
# 
# }, mc.cores = parallel::detectCores() - 1)
