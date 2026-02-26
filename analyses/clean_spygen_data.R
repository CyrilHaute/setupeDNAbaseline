source("R/function.R")

# This function convert spygen raw data to a site X species matrix

spygen_matrix <- convert_to_matrix_function(raw_spygen_path = "data/raw-data/Results_Med_2018-Oct2025.xlsx")


# This function remove misidentified species and check their names from fishbase

spygen_matrix_clean <- species_clean_function(spygen_matrix = spygen_matrix)

which_diff <- which(!colnames(spygen_matrix_clean$spygen_matrix_clean) %in% colnames(spygen_matrix_clean$spygen_matrix_old))
colnames(spygen_matrix_clean$spygen_matrix_clean)[which_diff]
colnames(spygen_matrix_clean$spygen_matrix_old)[which_diff]


spygen_matrix_test <- convert_to_matrix_function(raw_spygen_path = "data/raw-data/Teleo_SC23148_AMS_Corse_25-10_12122025_complet.xlsx")
spygen_matrix_test2 <- convert_to_matrix_function(raw_spygen_path = "data/raw-data/Teleo_SC23148_AMS_Occ_25_14_021225.xlsx")
spygen_matrix_test3 <- convert_to_matrix_function(raw_spygen_path = "data/raw-data/Teleo_SC21076_DPH_15_12012026_V2.xlsx")

which(spygen_matrix$spygen_code %in% spygen_matrix_test$spygen_code)

# Créer une fonction qui permet d'ajouter de nouvelles données aux anciennes, supprimer les doublons de l'ancien fichier (Med) car corresponds à une nouvelle version de la base de ref
# si la version est la même, verifier que les espèces et le nombre de read sont les mêmes. Normalement on est sensé ecrasé 

# Créer une fonction pour sélectionner des filtres spygen avec uniquement les espèces correspondantes à ces filtres
spygen_matrix$spygen_code[3543]
