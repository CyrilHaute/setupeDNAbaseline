
convert_to_matrix_function <- function(raw_spygen_path){
  
  # Load raw spygen data
  raw_data <- readxl::read_xlsx(raw_spygen_path, col_names = FALSE)
  
  
  # Find row and column containing "SPY" 

  row_spy <- which(sapply(1:nrow(raw_data), function(i) { any(grepl("SPY", raw_data[i,])) }))

  col_spy <- which(grepl("SPY", raw_data[row_spy,]))
  
  # If no "SPY" detected, that might be because of a pool, check for that
  
  if(length(c(row_spy, col_spy)) == 0) {
    
    row_spy <- which(sapply(1:nrow(raw_data), function(i) { any(grepl("^[0-9]+-[0-9]+$", raw_data[i,])) }))
    
    if(length(row_spy) != 1) { 
      
      stop(print("No or more than one ... detected"))
      
    }else{
        
      col_spy <- which(grepl("^[0-9]+-[0-9]+$", raw_data[row_spy,]))
      
      }

  }
  
  
  # Flip the dataframe and select select spygen_code column
  
  data_fliped <- data.frame(t(raw_data))
  
  data_spygen <- data_fliped[,row_spy:ncol(data_fliped)]
  
  
  # Find row and column containing "scientific_name" 
  
  col_sn <- which(sapply(1:ncol(data_spygen), function(i) { any(grepl("scientific_name", data_spygen[,i])) }))
  
  row_sn <- which(grepl("scientific_name", data_spygen[,col_sn]))
  
  # Rename column by species (first column is spygen code)
  colnames(data_spygen) <- data_spygen[row_sn,]
  
  # Remove unnecessary rows
  data_clean1 <- data_spygen[col_spy,]
  
  colnames(data_clean1)[which(colnames(data_clean1) == "scientific_name")] <- "nb"

  colnames(data_clean1)[1] <- "spygen_code"

  data_clean1[,!colnames(data_clean1) %in% c("spygen_code", "nb")] <- sapply(data_clean1[,!colnames(data_clean1) %in% c("spygen_code", "nb")], as.numeric)
  
  data_clean1[is.na(data_clean1)] <- 0
  
  if(any(is.na(colnames(data_clean1))) == TRUE) {
    
    data_clean1 <- data_clean1[-which(is.na(colnames(data_clean1)))]
    
  }else{
    
    data_clean1 <- data_clean1
    
  }

  
  # Make the sum of species identified multiple times

  # Select numeric columns
  num_cols <- sapply(data_clean1, is.numeric)
  
  data_clean1_num  <- data_clean1[, num_cols]
  data_clean1_meta <-  data_clean1[!num_cols]

  # Species names without .1, .2, .3, etc.
  base_names <- sub("\\.[0-9]+$", "", names(data_clean1_num))

  # Sum columns with the same names
  data_num_sum <- lapply(1:length(unique(base_names)), function(i) {
      
      sp_sp <- data.frame(species = rowSums(data_clean1_num[ base_names == unique(base_names)[i]], na.rm = TRUE))
      
      colnames(sp_sp) <- unique(base_names)[i]
      
      return(sp_sp)

    })
  data_num_sum_bind <- do.call(cbind, data_num_sum)

  # Bind metadata and species
  data_all_sum <- cbind(data_clean1_meta, data_num_sum)
  
  # If no "SPY" in spygen code because of pool, change pool code to match our format
  
  if(any(grepl("SPY", data_all_sum$spygen_code) == TRUE) == FALSE) {

    data_all_sum$spygen_code <- stringr::str_replace_all(data_all_sum$spygen_code, "([0-9]+)", "SPY\\1")
    
    data_all_sum$spygen_code <- stringr::str_replace_all(data_all_sum$spygen_code, "-", "_")
    
  }
  
  # If spygen code pooled, change pool code to match our format
  
  if(any(grepl("([0-9]+)", data_all_sum$spygen_code) == TRUE)) {
    
    data_all_sum$spygen_code <- stringr::str_replace_all(data_all_sum$spygen_code, "-", "_")
    
  }
  
  return(data_all_sum)
  
  # END

}


species_clean_function <- function(spygen_matrix) {
  
  species_names <- colnames(spygen_matrix)
  species_names <- species_names[! species_names %in% c("spygen_code", "nb")]
  
  # Filter misidentification

  bad_mask <- species_names[unique(c(which(is.na(species_names)), # Missing
                                     which(species_names == ""), # Empty
                                     which(grepl("dae", species_names, ignore.case = TRUE)), # Families
                                     which(grepl("_", species_names)), # _
                                     which(sapply(strsplit(species_names, "[ _]"), length) != 2), # Only one token (no space or underscore)
                                     which(grepl("spp.", species_names)), # spp.
                                     which(grepl("sp\\.", species_names)), # sp
                                     which(grepl("\\(cf\\)", species_names)), # (cf)
                                     which(grepl("hybrid", species_names)), # hybrid
                                     which(grepl("Unidentified", species_names)), # Unidentified
                                     which(grepl("\\?", species_names)), # ?
                                     which(grepl("\\!", species_names)), # !
                                     which(grepl("\\/", species_names)), # /
                                     which(grepl("New", species_names)) # New
  ))]

  # Remove problematic taxon rows from raw data
  spygen_clean <- spygen_matrix[!colnames(spygen_matrix) %in% bad_mask]
  
  # Check names from fishbase
  spygen_clean_species <- colnames(spygen_clean)
  spygen_clean_species_names <- spygen_clean_species[! spygen_clean_species %in% c("spygen_code", "nb")]
  
  validname <- rfishbase::validate_names(spygen_clean_species_names)
  
  remove_genus <- grep("Genus Species", validname)
  
  if(length(remove_genus) == 0) {
    
    validname_clean <- validname
    
  }else{
    
    validname_clean <- validname[-remove_genus]
    
  }
  
  old_spygen_name <- spygen_clean
  
  colnames(spygen_clean)[! colnames(spygen_clean) %in% c("spygen_code", "nb")] <- validname_clean
  
  
  # Sort species name by alphabethic order
  
  # old_spygen_name <- old_spygen_name[, c("spygen_code", sort(setdiff(names(old_spygen_name), "spygen_code")))]
  # 
  # spygen_clean <- spygen_clean[, c("spygen_code", sort(setdiff(names(spygen_clean), "spygen_code")))]

  to_return <- list(spygen_clean, old_spygen_name, bad_mask)
  names(to_return) <- c("spygen_matrix_clean", "spygen_matrix_old", "removed_species")
  
  return(to_return)
  
  # END
  
}


spygen_new_data_function <- function(old_spygen_data_path,
                                     new_spygen_data_path){
  
  
  # Convert new spygen raw data to a site X species matrix
  spygen_matrix_new <- convert_to_matrix_function(raw_spygen_path = new_spygen_data_path)
  
  # Remove misidentified species and check their names from fishbase
  spygen_matrix_new_clean <- species_clean_function(spygen_matrix = spygen_matrix_new)
  spygen_matrix_new_clean <- spygen_matrix_new_clean$spygen_matrix_clean
  
  
  # Compare new and old spygen data, look for common spygen code
  
  spygen_matrix_old_clean <- read.csv(old_spygen_data_path, header = TRUE, sep = ",", check.names = FALSE)
  
  # Get old and new spygen code
  # Check if spygen code pooled
  # if(any(grepl("^SPY[0-9]+_SPY[0-9]+$", spygen_matrix_new_clean$spygen_code) == TRUE)) {
  #   
  #   spygen_code_new <- unique(unlist(strsplit(stringr::str_replace_all(spygen_matrix_new_clean$spygen_code, "_", " "), " ")))
  #   
  # }else{
  #   
  #   spygen_code_new <- unique(spygen_matrix_new_clean$spygen_code)
  #   
  # }
  
  spygen_code_new <- unique(spygen_matrix_new_clean$spygen_code)
  
  spygen_code_old <- unique(spygen_matrix_old_clean$spygen_code)
  
  # Which new spygen code are common with old ones
  common_spygen_code <- spygen_code_new[which(spygen_code_new %in% spygen_code_old)]
  
  if(length(common_spygen_code) == 0) {
    
    join_old_new <- spygen_matrix_old_clean |> 
      dplyr::full_join(spygen_matrix_new_clean)
    
    join_old_new[is.na(join_old_new)] <- 0
    
   }else{
    
     # Consider only common spygen code in both new and old data
     spygen_old_common <- spygen_matrix_old_clean[spygen_matrix_old_clean$spygen_code %in% common_spygen_code,]
     
     spygen_new_common <- spygen_matrix_new_clean[spygen_matrix_new_clean$spygen_code %in% common_spygen_code,]
     
     # Consider only common species in both new and old data
     col_new <- colnames(spygen_new_common)
     
     spygen_old_common <- spygen_old_common[,colnames(spygen_old_common) %in% col_new]
     
     # Look at differences between old and new data
     # Order species in alphabetic order
     spygen_old_common <- spygen_old_common[, c("spygen_code", "nb", sort(setdiff(names(spygen_old_common), c("spygen_code", "nb"))))]
     # Order spygen code
     spygen_old_common <- spygen_old_common[order(spygen_old_common$spygen_code),]
     
     # Order species in alphabetic order
     spygen_new_common <- spygen_new_common[, c("spygen_code", "nb", sort(setdiff(names(spygen_new_common), c("spygen_code", "nb"))))]
     # Order spygen code
     spygen_new_common <- spygen_new_common[order(spygen_new_common$spygen_code),]
     
     any_diff <- which((spygen_old_common == spygen_new_common) == FALSE)
     
     any_diff <- unique(stringr::str_replace_all(names(which((unlist(spygen_old_common) == unlist(spygen_new_common)) == FALSE)), "[0-9]", ""))
     
     if(length(any_diff) == 0){
       
       join_old_new <- spygen_matrix_old_clean |> 
         dplyr::full_join(spygen_matrix_new_clean)
       
       join_old_new[is.na(join_old_new)] <- 0
       
     }else{
       
       spygen_new_diff <- spygen_new_common[,c("spygen_code", "nb", any_diff)]
       
       spygen_old_diff <- spygen_old_common[,c("spygen_code", "nb", any_diff)]
       
       test <- spygen_matrix_new_clean |> 
         dplyr::filter(spygen_code %in% common_spygen_code) |> 
         dplyr::group_by(spygen_code, nb) |> 
         dplyr::summarise(seq_tot = rowSums(dplyr::across(where(is.numeric))))
       
       
       test2 <- spygen_matrix_old_clean |> 
         dplyr::filter(spygen_code %in% common_spygen_code) |> 
         dplyr::group_by(spygen_code, nb) |> 
         dplyr::summarise(seq_tot = rowSums(dplyr::across(where(is.numeric))))

     }
     
   }
  
  return(join_old_new)
  
  # END

}
