#### Bibliothèques et espace de travail ####

library(ape)
library(dplyr)
library(entropart)
library(fastDummies)
library(fishtree)
library(geiger)
library(ggplot2)
library(ggpubr)
library(gridExtra)
library(margins)
library(mFD)
library(pbapply)
library(picante)
library(purrr)
library(rfishbase)
library(rsq)
library(scales)
library(stringr)
library(tidyr)
library(tidyverse)
library(viridis)
library(readxl)

library(readxl)
library(dplyr)
library(tibble)

#1) Charger la donnée ####

#Charger la checklist Med - Atlantique
check <- read.csv("data/raw-data/checklist_Med_Atl_cleaned.csv", sep = ";")
`%!in%` = Negate(`%in%`)  # Créer un opérateur pour la négation de `%in%`


#Lire le fichier brut SPYGEN sans noms de colonnes (pour travailler sur les lignes)
raw <- readxl::read_xlsx("data/raw-data/Results_Med_2018-Oct2025.xlsx",
                 col_names = FALSE)
#trouver la ligne qui contient "scientific_name" 
header_row <- which(apply(raw, 1, function(r) any(grepl("^scientific_name$",
                                                        r, ignore.case = TRUE))))
if(length(header_row) == 0) stop("Impossible de trouver la ligne contenant 'scientific_name'.")

#Indices des lignes qui correspondent aux taxons (juste après la ligne header)
species_rows <- (header_row + 1):nrow(raw)

#Prendre la colonne des noms scientifiques (4ème colonne dans ton fichier)
sp_col <- as.character(raw[[4]][species_rows])

#Détecter les "mauvaises" lignes PARMI ces seules lignes d'espèces
is_sp_word     <- grepl("\\bsp\\.?\\b", sp_col, ignore.case = TRUE)  # sp ou sp.
is_underscore  <- grepl("_", sp_col, fixed = TRUE)                   # contient "_"
is_family      <- grepl("dae", sp_col, ignore.case = TRUE)           # contient "dae"

bad_mask <- is_sp_word | is_underscore | is_family
bad_species_rows <- species_rows[bad_mask]

#(Optionnel) afficher les valeurs qui seront supprimées
if(length(bad_species_rows) > 0){
  message("Taxons détectés comme à supprimer (exemples) :")
  print(unique(sp_col[bad_mask]))
} else {
  message("Aucun taxon problématique détecté parmi les lignes d'espèces.")
}

#créer un raw_clean sans ces lignes d'espèces problématiques
raw_clean <- raw[-bad_species_rows, ]


#2) Formater le dataframe ####
data_all <- data.frame(t(raw_clean))                                                     # transposes the data frame  
data_all <- tibble::rownames_to_column(data_all, var = "region")                                # add the row names as a new column 
names(data_all) <- data_all[4,]                                                         # replace the Column names by the species names
data_all <- data_all[,-1:-5] # colonnes
names(data_all)[1] <- "code_spygen"
data_all <- data_all[-1:-5,]  #lignes
names(data_all)[2] <- "variable"

# Remplacer les NA par 0
data_all[is.na(data_all)] <- 0

# delete the firts 5 lines (adjust for each dataframe to process)
data_all[,3:length(data_all)] <- apply(data_all[,3:length(data_all)], 2, 
                                       function(x)gsub('\\s+', '',x))                    # remove blank spaces in excess
data_all[,3:length(data_all)] <- sapply(data_all[,3:length(data_all)], as.numeric)              # make sure the data are numeric

# supprimer la colonne "total" de SPYGEN
data_all <- data_all[ , -313]



#3) CLEAN LA DATA (1.)#### 
# Correct the identification of 'Dasyatis marmorata' into 'Dasyatis tortonesei'
which(grepl("Dasyatis marmorata", names(data_all))) 
which(grepl("Dasyatis tortonesei", names(data_all))) 

data_all[length(data_all)+1] <- data_all[,291] + data_all[,293]

data_all <- data_all |> 
  dplyr::select(! c("Dasyatis marmorata", "Dasyatis tortonesei")) |>               # remove the columns with the duplicated species
  dplyr::rename("Dasyatis tortonesei" = "V313" )                                       # rename the merged column


## sommer tous els doublons avec .1, .2, .3 etc
# identifier les colonnes numériques
num_cols <- sapply(data_all, is.numeric)

# pour les séparer des character et ainsi faire nos calculs sur les numeriques
data_num  <- data_all[, num_cols]
data_meta <- data_all[, !num_cols]

# récupérer les noms de base des espèces (sans .1, .2, .3, etc.)
base_names <- sub("\\.[0-9]+$", "", names(data_num))

# sommer les colonnes ayant le même nom
data_num_sum <- as.data.frame(
  sapply(unique(base_names), function(sp) {
    rowSums(data_num[, base_names == sp, drop = FALSE], na.rm = TRUE)
  })
)

names(data_num_sum) <- unique(base_names)

# résultat final 
data_all_sum <- cbind(data_meta, data_num_sum)

#voir quelles espèces étaient dupliquées
dup_species <- unique(base_names[duplicated(base_names)])
dup_species

# autres colonnes pblematique
which(grepl("Notoscopelus elongatus", names(data_all_sum))) 
# si Notoscopelus elongatus kroyeri : renommer Notoscopelus elongatus
names(data_all_sum)[149] <- "Notoscopelus elongatus"


# autres
which(grepl("Dasyatis SP", names(data_all))) 



#4) Matching w/ Metadatas ####
# Load metadata -- application sur fichier fusionné qui ne garde que  spygen_code pour le décompte
metadatas <- read.csv("data/raw-data/Med_metadonnees_ADNe - 2018-2025.csv", sep = ";", dec = ".") |> 
  dplyr::rename(code_spygen = spygen_code) |> 
  dplyr::mutate(pool = gsub("\\.", "_", pool)) |> 
  dplyr::mutate(pool = ifelse(pool == "no", code_spygen, pool))

# |>               # Dans la colonne "pool" remplacer les valeurs "no" par le "code_spygen" (utile pour matching avec data_all par la suite)
# 
#   dplyr::mutate(pool_inv = dplyr::case_when(nchar(pool) > 10 ~ 
#                                 paste(substr(pool,11,19),
#                                       substr(pool, 1, 9), sep = "-"), 
#                               TRUE ~ pool)) 

### a appliquer sur metadonnées completes 18-24 / ET 25 clean
# Remove Angelshark contamination
ls_conta_shark <- metadatas |> 
  dplyr::filter(str_detect(comments, "contamination Ange de mer"))  

data_all_sum <- data_all_sum %>% 
  mutate(`Squatina squatina` = ifelse(code_spygen %in% ls_conta_shark$code_spygen, 0, `Squatina squatina`))

# Remove filters absent from the metadata and remove empty species columns
data_all_meta <- data_all_sum |> 
  dplyr::mutate(code_spygen = gsub("\\-", "_", code_spygen)) |> 
  dplyr::filter(code_spygen %in% metadatas$pool) |> 
  dplyr::mutate(dplyr::across(-c(1:2), ~ if (sum(.) != 0){ . } else { NULL })) |>                # check for empty columns # 104 species removed
  dplyr::select(where(~ !is.null(.)))


# List of filtersdata_all# List of filters present in the results but absent from metadata
data_out_meta <- subset(data_all_sum, !(data_all_sum$code_spygen %in% metadatas$pool))  
filter_out_meta <- data_out_meta %>%                                        
  pull(code_spygen) %>% 
  unique()


# List of filters in the metadata but absent from the results
meta_out_data <- subset(metadatas, !(metadatas$pool %in% data_all_sum$code_spygen))  
filter_out_data <- meta_out_data %>% 
  pull(code_spygen) %>% 
  unique()



# ----------------------- CLEAN LA DATA 2. -------------------------
#5)  DOUBLONS : Identifier toutes les colonnes se terminant par ".1"  ####
cols_dot1 <- grep("\\.1$", names(data_all_sum), value = TRUE)

#Déduire les noms "de base" (sans le .1)
base_names <- sub("\\.1$", "", cols_dot1)

# Boucle sur chaque espèce pour fusionner les colonnes
for (species in base_names) {
  
  # Vérifier que la colonne sans .1 existe bien
  if (species %in% names(data_all_sum)) {
    
    # Créer une nouvelle colonne fusionnée = somme des deux
    data_all_sum[[species]] <- data_all_sum[[species]] + data_all_sum[[paste0(species, ".1")]]
    
    # Supprimer la colonne doublon
    data_all_sum <- data_all_sum %>%
      select(!all_of(paste0(species, ".1")))
    
  } else {
    message("Colonne ", species, " n’a pas de doublon clair, sautée.")
  }
}


#6)  Matching avec la checklist MED/ATL ####
# Check for species absent from the checklist
s_i <- data_all_sum |> 
  dplyr::select(-code_spygen, -variable) |> 
  dplyr::select(names(.)[colSums(.) > 0])
s_i <- names(s_i)
s_i <- data.frame(s_i)

sp_in_checklist <- s_i |>  dplyr::filter(s_i %in% check$species) 
sp_out_checklist <- s_i |>  dplyr::filter(s_i %!in% check$species) 


#REMOVE INCORRECT SP NAMES
sp_out_notOK <- sp_out_checklist |> 
  dplyr::filter(!grepl("\\s", s_i))  # Filtre les noms qui n'ont pas d'espace, donc composés d'un seul mot

# Afficher ou sauvegarder l'objet
sp_out_notOK #plot

sp_out_OK <- sp_out_checklist |> 
  dplyr::filter(grepl("\\s", s_i)) 

sp_out_OK #plot


#7) Suppression des colonnes de data_all_meta qui ont des noms présents dans noms_invalides ####
data_clean <- data_all_sum |> 
  dplyr::select(-all_of(sp_out_notOK$s_i))

# trier les colonnes par ordre alphabétique
data_clean <- data_clean |> 
  dplyr::select(1:2, sort(names(.)[3:ncol(.)]))

# supprimer les espèces exogènes détectées par Alice (SPYGEN) + sp_out_OK après checking
data_clean <- data_clean %>%
  select(-c(
    "Ophisurus macrorhynchos",
    "Nansenia boreacrassicauda",
    "Cololabis saira",
    "Zu cristatus",
    "Encrasicholina punctifer",
    "Lophius litulon",
    "Chelon richardsonii",
    "Planiliza macrolepis",
    "Diaphus anderseni",
    "Johnius belangerii",
    "Larimichthys crocea",
    "Cataetyx rubrirostris",
    "Stomias boa",
    "Centrophorus squamosus",
    "Gobiusculus flavescens",
    "Bolinichthys supralateralis",
    "Notacanthus chemnitzii",
    "Euthynnus affinis",
    "Vinciguerria nimbaria",
    "Hyperoplus lanceolatus"
  ))

# supprimer les espèces exogènes restantes présentées par Celia 
data_clean <- data_clean %>%
  select(-c(
    "Istiophorus platypterus" ))

# renommer Pomatomus saltator selon nom correct > WORMS
names(data_clean)[names(data_clean) == "Pomatomus saltator"] <- "Pomatomus saltatrix"


#8) Create 3 data frames : number of PCR replicates, number of reads, presence/absence of species ####

data_rep <- data_clean %>% 
  dplyr::filter(variable == "nb_rep") #%>% 
#distinct(code_spygen, keep_all = TRUE)


data_seq <- data_clean %>% 
  dplyr::filter(variable == "nb_seq") #%>% 
#distinct(code_spygen, keep_all = TRUE)

data_pres <- data_rep %>% 
  dplyr:: select(-variable ) %>% 
  mutate_at(vars(-code_spygen), ~ifelse(. > 0, 1, .)) #%>%                        # replace values by 0/1
# distinct(code_spygen, keep_all = TRUE)                           

write.table(data_pres, "/Users/marieorblin/Desktop/METADONNEES/data_MED_teleo_pres_1825_V1.csv", row.names = F, dec = ".", sep = ";")
write.table(data_rep, "Desktop/ADNe_MATRICES_sept25/data_MED_teleo_rep_1824_V1.csv", row.names = F, dec = ".", sep = ";")
write.table(data_seq, "Desktop/ADNe_MATRICES_sept25/data_MED_teleo_seq_1824_V1.csv", row.names = F, dec = ".", sep = ";")

#### VIGILIFE ####
data_pres <- read.csv("/Users/marieorblin/Desktop/ADNe_MATRICES_sept25/data_MED_teleo_pres_1824_V1.csv",  sep = ";")
metadatas <- metadatas %>%
  select(-c(3, 5, 6, 9, 10, 11, 12, 13, 14, 19:38))
merge_VG2 <- left_join(
  data_pres,
  metadatas,
  by = c("code_spygen" = "pool")
)

cols <- colnames(merge_VG2)
new_order <- c(
  cols[1],          # colonne 1
  cols[240:247],    # colonnes à déplacer
  cols[-c(1, 240:247)] # le reste
)
merge_VG_clean <- merge_VG2[, new_order]

merge_VG_clean <- merge_VG_clean[, -2]

merge_VG_clean_filtered <- merge_VG_clean %>%
  filter(site == "banyuls")

write.table(merge_VG_clean_filtered, "/Users/marieorblin/Desktop/ADNe_MATRICES_sept25/data_banuyls_teleo_pres_1824_VGL.csv", row.names = F, dec = ".", sep = ";")

