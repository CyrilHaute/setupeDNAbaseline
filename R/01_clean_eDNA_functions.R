
#' convert_to_matrix_function
#' 
#' This function convert spygen raw data into a site X species matrix.
#'
#' @param raw_spygen_path A character indicating the path of spygen raw data. Data has to be in the format ".xlsx".
#'
#' @returns A dataframe in the format site X species.
#' @export
#'
#' @examples 

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
      
      stop(print("No or more than one SPY column detected"))
      
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


#' species_clean_function
#' 
#' This function clean species eDNA data in terms of species names. 
#' 
#' The function removes all misidentified species (missing names, identified at the family level or as spp., sp., all species not spelled in the binomial format).
#' 
#' Once misidentified species has been removed, the function check the correct names of remaining species from FishBase.
#' 
#' Caution : this function only convert data to a suitable format for analysis, with only basic cleaning step. This does not exempt users from checking the list of species returned by the functions (e.g., species detected outside their distribution range).
#'
#' @param spygen_matrix A dataframe of species eDNA in the format site X species.
#'
#' @returns A list containing three objects : 
#' 
#' A dataframe in the format site X species with new species names checked from FishBase;
#' 
#' A dataframe in the format site X species with old species names before checking from FishBase;
#' 
#' A character vector listing all removed species.
#' 
#' @export
#'
#' @examples

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
  
  if(any(is.na(validname))){
    
    na_species <- spygen_clean_species_names[which(is.na(validname))]
    
    validname_worms <- as.data.frame(worrms::wm_records_names(na_species))$valid_name
    
    validname[which(is.na(validname))] <- validname_worms
    
    validname_clean <- validname
    
  }else{
    
    validname_clean <- validname
    
  }

  old_spygen_name <- spygen_clean
  
  colnames(spygen_clean)[! colnames(spygen_clean) %in% c("spygen_code", "nb")] <- validname_clean

  to_return <- list(spygen_clean, old_spygen_name, bad_mask)
  names(to_return) <- c("spygen_matrix_clean", "spygen_matrix_old", "removed_species")

  return(to_return)
  
  # END
  
}


#' spygen_new_data_function
#' 
#' This function add new eDNA data to previous ones.
#' 
#' The function first convert new raw species data to site X species matrix using the 'convert_to_matrix_function' and then check for correct species names using the 'species_clean_function'.
#' 
#' The function then look for common spygen code between old and new data, potentially resulting from reanalysis from Spygen (update of reference data base).
#' 
#' If no common spygen code are detected, the function join the new data to the old ones.
#' 
#' Otherwise, once identified, the function look at differences between old and new data. 
#' 
#' If no difference detected, the function join the new data to the old ones with no changes in common data.
#' 
#' If differences have been detected, the function will replace the old data with new data.
#'
#' @param old_spygen_data_path A character indicating the path of spygen old data (cleaned). Data has to be in the format ".csv".
#' @param new_spygen_data_path A character indicating the path of spygen new raw data. Data has to be in the format ".xlsx".
#' @param path_save A character indicating the path to save data.
#'
#' @returns Save new data to `path_save`.
#' @export
#'
#' @examples

spygen_new_data_function <- function(old_spygen_data_path,
                                     new_spygen_data_path,
                                     path_save){
  
  # Convert new spygen raw data to a site X species matrix
  spygen_matrix_new <- convert_to_matrix_function(raw_spygen_path = new_spygen_data_path)
  
  # Remove misidentified species and check their names from fishbase
  spygen_matrix_new_clean <- species_clean_function(spygen_matrix = spygen_matrix_new)
  spygen_matrix_new_clean <- spygen_matrix_new_clean$spygen_matrix_clean
  
  
  # Compare new and old spygen data, look for common spygen code
  
  spygen_matrix_old_clean <- read.csv(old_spygen_data_path, header = TRUE, sep = ",", check.names = FALSE)
  
  # Get old and new spygen code
  # Check if spygen code pooled

  spygen_code_new <- unique(spygen_matrix_new_clean$spygen_code)
  
  spygen_code_old <- unique(spygen_matrix_old_clean$spygen_code)
  
  # Which new spygen code are common with old ones
  common_spygen_code <- spygen_code_new[which(spygen_code_new %in% spygen_code_old)]
  
  # If no common spygen code between old and new data, just join the two data
  if(length(common_spygen_code) == 0) {

    join_old_new <- spygen_matrix_old_clean |> 
      merge(spygen_matrix_new_clean, all = TRUE)
    
    join_old_new[is.na(join_old_new)] <- 0
    
   }else{ # Otherwise, look at differences between common old and new data
    
     # Consider only common spygen code in both new and old data
     spygen_old_common <- spygen_matrix_old_clean[spygen_matrix_old_clean$spygen_code %in% common_spygen_code,]
     
     spygen_new_common <- spygen_matrix_new_clean[spygen_matrix_new_clean$spygen_code %in% common_spygen_code,]
     
     # Consider only common species in both new and old data
     col_new <- colnames(spygen_new_common)
     col_old <- colnames(spygen_old_common)
     
     common_species <- col_old[which(col_old %in% col_new)]

     spygen_old_common <- spygen_old_common[,colnames(spygen_old_common) %in% col_new]
     
     # Check for new species in new data
     
     new_species <- col_new[which((col_new %in% col_old) == FALSE)]
     
     if(length(new_species) != 0){
       
       add_new_species <- spygen_new_common[,colnames(spygen_new_common) %in% c("spygen_code", "nb", new_species)]
       
       spygen_old_common <- spygen_old_common |> 
         merge(add_new_species, all = TRUE)
       
     }else{
       
       spygen_old_common <- spygen_old_common
       
     }

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
     
     # If no differences between old and new data, just join the two data
     if(length(any_diff) == 0){
       
       join_old_new <- spygen_matrix_old_clean |> 
         merge(spygen_matrix_new_clean, all = TRUE)
       
       join_old_new[is.na(join_old_new)] <- 0
       
     }else{ # Otherwise, consider the new data

       # Look at the differences between old and new data
       spygen_new_diff <- spygen_new_common[,c("spygen_code", "nb", any_diff)]
       
       spygen_old_diff <- spygen_old_common[,c("spygen_code", "nb", any_diff)]
       
       # For the spygen_code common in the old data, replace the data with that from the new data.
       spygen_matrix_old_clean[,c("spygen_code", "nb", any_diff)][spygen_matrix_old_clean[,c("spygen_code", "nb", any_diff)]$spygen_code %in% spygen_old_diff$spygen_code,] <- spygen_new_diff
       
       # Then join old and new data
       
       join_old_new <- spygen_matrix_old_clean |> 
         merge(spygen_matrix_new_clean, all = TRUE)
       
       # Check if some common spygen_code with differences are still in the data, this should lead to more than two replicates per spygen_code
       
       test <- join_old_new |> 
         dplyr::group_by(spygen_code) |> 
         dplyr::summarise(n = dplyr::n())
       
       if(any(test$n != 2)) { stop("Error in joining old and new data") }
       
       # test <- by(
       #   
       #   subset(spygen_matrix_new_clean, spygen_code %in% common_spygen_code),
       #   
       #   INDICES = list(
       #     spygen_matrix_new_clean$spygen_code[
       #       spygen_matrix_new_clean$spygen_code %in% common_spygen_code
       #     ],
       #     spygen_matrix_new_clean$nb[
       #       spygen_matrix_new_clean$spygen_code %in% common_spygen_code
       #     ]
       #   ),
       #   
       #   FUN = function(df) {
       #     data.frame(
       #       spygen_code = df$spygen_code[1],
       #       nb = df$nb[1],
       #       seq_tot = sum(
       #         rowSums(df[ , !(names(df) %in% c("spygen_code", "nb"))])
       #       )
       #     )
       #   }
       #   
       # )
       # test <- do.call(rbind, test)
       # 
       # test2 <- by(
       #   
       #   subset(spygen_matrix_old_clean, spygen_code %in% common_spygen_code),
       #   
       #   INDICES = list(
       #     spygen_matrix_old_clean$spygen_code[
       #       spygen_matrix_old_clean$spygen_code %in% common_spygen_code
       #     ],
       #     spygen_matrix_old_clean$nb[
       #       spygen_matrix_old_clean$spygen_code %in% common_spygen_code
       #     ]
       #   ),
       #   
       #   FUN = function(df) {
       #     data.frame(
       #       spygen_code = df$spygen_code[1],
       #       nb = df$nb[1],
       #       seq_tot = sum(
       #         rowSums(df[ , !(names(df) %in% c("spygen_code", "nb"))])
       #       )
       #     )
       #   }
       #   
       # )
       # test2 <- do.call(rbind, test2)

     }
     
   }
  
  nb_rep <- join_old_new[join_old_new$nb == "nb_rep",]
  nb_rep <- nb_rep[,!colnames(nb_rep) %in% "nb"]
  nb_rep <- nb_rep[, c("spygen_code", sort(setdiff(names(nb_rep), "spygen_code")))] # Sort species name by alphabethic order
  
  nb_seq <- join_old_new[join_old_new$nb == "nb_seq",]
  nb_seq <- nb_seq[,!colnames(nb_seq) %in% "nb"]
  nb_seq <- nb_seq[, c("spygen_code", sort(setdiff(names(nb_seq), "spygen_code")))]
  
  occurrence <- nb_rep
  species <- occurrence[,!colnames(nb_seq) %in% "spygen_code"]
  species[species > 0] <- 1
  occurrence_final <- cbind(occurrence[colnames(occurrence) == "spygen_code"], species)
  occurrence_final <- occurrence_final[, c("spygen_code", sort(setdiff(names(occurrence_final), "spygen_code")))]
  
  dir.create(path_save)
  write.csv(join_old_new, file = paste0(path_save, "all.csv"), row.names = FALSE)
  write.csv(nb_rep, file = paste0(path_save, "rep.csv"), row.names = FALSE)
  write.csv(nb_seq, file = paste0(path_save, "seq.csv"), row.names = FALSE)
  write.csv(occurrence_final, file = paste0(path_save, "occ.csv"), row.names = FALSE)

  # END

}

#' spygen_subset_function
#' 
#' This function create a subset of eDNA data by spygen_code.
#'
#' @param eDNA_species_data_path A character indicating the path of cleaned spygen data. Data has to be in the format ".csv". 
#' @param spygen_code_subset A character or a dataframe indicating which spygen_code to subset the data with. If supply a dataframe, make sure to name the spygen code column "spygen_code"
#'
#' @returns A dataframe in the format site X species, subset from eDNA_species_data.
#' @export
#'
#' @examples

spygen_subset_function <- function(eDNA_species_data_path,
                                   spygen_code_subset){

  # Load eDNA species data
  eDNA_species_data <- read.csv(eDNA_species_data_path, header = TRUE, check.names = FALSE)
  
  
  # Get spygen_code subset
  if(any(class(spygen_code_subset) %in% c("data.frame", "tbl_df", "tbl"))) {
    
    get_spygen_subset <- unique(unlist(spygen_code_subset[,colnames(spygen_code_subset) == "spygen_code"]))
    
  }
  
  if(class(spygen_code_subset) == "character") {
    
    get_spygen_subset <- unique(spygen_code_subset)
    
  }
  
  
  # Subset
  eDNA_species_subset <- eDNA_species_data[eDNA_species_data$spygen_code %in% get_spygen_subset,]
  
  
  # Select only species present in the subset area
  # Get species names
  species <- colnames(eDNA_species_subset)[!colnames(eDNA_species_subset) %in% c("spygen_code", "nb")]
  
  # Is the species present in the area ?
  is_sp_present <- lapply(1:length(species), function(i) {
    
    data.frame(species = species[i],
               present = any(eDNA_species_subset[,colnames(eDNA_species_subset) == species[i]] != 0))
    
  })
  is_sp_present_bind <- do.call(rbind, is_sp_present)
  
  # Select only species present in the subset area
  sp_present <- is_sp_present_bind[is_sp_present_bind$present == TRUE,]
  
  eDNA_subset_sp_present <- eDNA_species_subset[,colnames(eDNA_species_subset) %in% c("spygen_code", "nb", sp_present$species)]
  
  return(eDNA_subset_sp_present)

}
