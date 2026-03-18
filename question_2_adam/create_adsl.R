#------------------------------------------------------------------------------
# Question 1: ADaM ADSL Dataset Creation using {admiral}
# Description: Create ADaM Subject-Level Analysis Dataset (ADSL)
#              with custom variables: AGEGR9/AGEGR9N, TRTSDTM/TRTSTMF,
#              ITTFL, LSTAVLDT
# Author: Adashi Odama
# Date  : 03/18/2026

#  Custom Derived Variables:
#  - AGEGR9 & AGEGR9N: Age grouping ("<18", "18 - 50", ">50")
#  - TRTSDTM & TRTSTMF: Treatment start datetime with imputation flag
#  - ITTFL: Intent-to-Treat flag
#  - LSTAVLDT: Last known alive date from VS, AE, DS, EX
#------------------------------------------------------------------------------

# Install and Load packages

install.packages(c("admiral", "lubridate","stringr", "xportr", "labelled"))
library(admiral)
library(pharmaversesdtm)
library(dplyr)
library(tidyr)
library(lubridate)
library(stringr)
library(xportr)

#--- 1: Load SDTM Input Datasets ---

## Load SDTM domains
dm <- pharmaversesdtm::dm  # Demographics - base for ADSL
vs <- pharmaversesdtm::vs  # Vital Signs - for LSTAVLDT
ex <- pharmaversesdtm::ex  # Exposure - for treatment dates
ds <- pharmaversesdtm::ds  # Disposition - for LSTAVLDT
ae <- pharmaversesdtm::ae  # Adverse Events - for LSTAVLDT


## Convert blank characters to NA (SAS import handling)
dm <- convert_blanks_to_na(dm)
vs <- convert_blanks_to_na(vs)
ex <- convert_blanks_to_na(ex)
ds <- convert_blanks_to_na(ds)
ae <- convert_blanks_to_na(ae)

cat("Input datasets loaded:\n")
cat("  DM:", nrow(dm), "rows\n")
cat("  VS:", nrow(vs), "rows\n")
cat("  EX:", nrow(ex), "rows\n")
cat("  DS:", nrow(ds), "rows\n")
cat("  AE:", nrow(ae), "rows\n\n")

## Start with DM as base (one record per subject)
adsl <- dm %>% select(-DOMAIN)

cat("Base ADSL created with", nrow(adsl), "subjects\n\n")





#---2: Derive AGEGR9 and AGEGR9N (Age Grouping) ---
# Per Assessment Specification:
# AGEGR9: "<18", "18 - 50", ">50" # AGEGR9N: 1, 2, 3
# Approach: Create reusable functions for age categorization

## Function to create character age groups
format_agegr9 <- function(age) {
  case_when(
    age < 18 ~ "<18",
    between(age, 18, 50) ~ "18 - 50", 
    age > 50 ~ ">50",
    TRUE ~ NA_character_  # If AGE is missing, return NA
  )
}

## Function to create numeric age groups
format_agegr9n <- function(age) {
  case_when(
    age < 18 ~ 1,
    between(age, 18, 50) ~ 2, 
    age > 50 ~ 3,
    TRUE ~ NA_real_  # If AGE is missing, return NA
  )
}

## Apply the functions to create age groups
adsl <- adsl %>%
  mutate(
    AGEGR9 = format_agegr9(AGE),
    AGEGR9N = format_agegr9n(AGE)
  )

## Verify the derivation

print(table(adsl$AGEGR9, useNA = "ifany"))
print(table(adsl$AGEGR9N, useNA = "ifany"))

cat("Step 2 Complete\n\n")



  

#--- 3: Derive TRTSDTM and TRTSTMF (Treatment Start DateTime) ---

# Per Assessment Specification:
# TRTSDTM: Treatment start datetime with valid dose & complete datepart(exstdtc)
# TRTSTMF: Imputation flag - ONLY set when hours or minutes imputed
#          (NOT set if only seconds are imputed)
#
# Valid Dose Definition:
#   - EXDOSE > 0, OR
#   - EXDOSE = 0 AND EXTRT contains "PLACEBO"

## Diagnostic: Sample of original EXSTDTC values to see if we have partial times

ex %>% 
  filter(EXDOSE > 0 | (EXDOSE == 0 & str_detect(EXTRT, "PLACEBO"))) %>%
  select(USUBJID, EXSTDTC, EXDOSE) %>%
  head(20)

## 3a: Convert EX dates to datetimes with imputation

  ex_ext <- ex %>%
  derive_vars_dtm(
    dtc = EXSTDTC,            # Source: EX start date/time character
    new_vars_prefix = "EXST", # Creates: EXSTDTM, EXSTTMF
    highest_imputation = "M", # Allow imputation up to minute level
    time_imputation = "first" # Impute missing time as 00:00:00
  ) %>%
  derive_vars_dtm(
    dtc = EXENDTC,
    new_vars_prefix = "EXEN",
    highest_imputation = "M",
    time_imputation = "last"  # Impute end time as 23:59:59
  )

cat("  EX dataset prepared with datetime variables\n")



##3b: Derive treatment start datetime (first valid dose)

adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ex_ext,
    filter_add = (EXDOSE > 0 | 
                    (EXDOSE == 0 & str_detect(EXTRT, "PLACEBO"))) & 
      !is.na(EXSTDTM),
    # Merge these variables from EX to ADSL
    new_vars = exprs(TRTSDTM = EXSTDTM, TRTSTMF = EXSTTMF),
    # Sort by datetime, then sequence to get first exposure
    order = exprs(EXSTDTM, EXSEQ),
    mode = "first",  # Take first (earliest) record
    by_vars = exprs(STUDYID, USUBJID)
  )

## Check how many subjects have TRTSDTM
cat("  TRTSDTM derived for", sum(!is.na(adsl$TRTSDTM)), "subjects\n")
cat("  TRTSTMF flag frequency:\n")
print(table(adsl$TRTSTMF, useNA = "ifany"))


## 3c: Derive treatment start date (without time)
  adsl <- adsl %>%
     derive_vars_dtm_to_dt(source_vars = exprs(TRTSDTM))
  

  
  

  
  
#--- 4: Derive ITTFL (Intent-to-Treat Flag) ---
  
  # Per Assessment Specification:
  # ITTFL = "Y" if ARM is not missing 
  # ITTFL = "N" if ARM is missing
  # HOWEVER, based on clinical trial standards and common ITT population definition:
  # ITT typically includes only RANDOMIZED subjects (those assigned to treatment arms)
  # Screen failures have ARM populated but were NOT randomized
  # Decision: Set ITTFL = "N" for screen failures even though ARM is not missing
  
  
  adsl <- adsl %>%
    mutate(
      ITTFL = if_else(
        !is.na(ARM) & !ARM %in% c("Screen Failure", "Not Assigned", "Not Treated"),
        "Y",
        "N"
      )
    )
  
 ##Verify the derivation
  cat("  ITTFL frequency:\n")
  print(table(adsl$ITTFL, useNA = "ifany"))
  
  cat("  ITTFL by ARM:\n")
  print(table(adsl$ARM, adsl$ITTFL, useNA = "ifany"))
  
  
  

  
#--- 5: Derive LSTAVLDT (Last Known Alive Date) ---

  # Per Assessment Specification:
  # LSTAVLDT = Latest date from ANY of these sources:
  # 1. Last VS date with valid result)(VSTRESC/N not missing and VSDTC not missing)
  # 2. Last AE onset date (AESTDTC with complete date)
  # 3. Last disposition date (DSSTDTC with complete date)
  # 4. Last treatment date (from TRTEDTM)

  
## 5a Extract last vital signs date with valid result
  
  vs_dates <- vs %>%
    filter(!is.na(VSSTRESN) | !is.na(VSSTRESC)) %>%
    derive_vars_dt(      # Convert character date to numeric date
      dtc = VSDTC,
      new_vars_prefix = "VS"
    ) %>%
    filter(!is.na(VSDT)) %>%   # Keep only complete dates
    group_by(STUDYID, USUBJID) %>%
    summarise(last_vs_dt = max(VSDT, na.rm = TRUE), .groups = "drop") # Get last (maximum) date per subject
  
  
  cat("    Found VS dates for", nrow(vs_dates), "subjects\n") #252 subjects consistent with patients with assigned treatments
  
  
  
## 5b: Extract last AE onset date
  
  ae_dates <- ae %>%
    derive_vars_dt(
      dtc = AESTDTC,   # Convert AE start date to numeric date
      new_vars_prefix = "AE"
    ) %>%
    filter(!is.na(AEDT)) %>%  # Keep only complete dates
    group_by(STUDYID, USUBJID) %>%
    summarise(last_ae_dt = max(AEDT, na.rm = TRUE), .groups = "drop")  # Get last date per subject
  
  cat("    Found AE dates for", nrow(ae_dates), "subjects\n")

  
  
##5c: Extract last disposition date
  
  ds_dates <- ds %>%
    derive_vars_dt(
      dtc = DSSTDTC, # Convert DS start date to numeric date
      new_vars_prefix = "DS"
    ) %>%
    filter(!is.na(DSDT)) %>%   # Keep only complete dates
    group_by(STUDYID, USUBJID) %>%
    summarise(last_ds_dt = max(DSDT, na.rm = TRUE), .groups = "drop") # Get last date per subject
  
  cat("    Found DS dates for", nrow(ds_dates), "subjects\n")

  
  
## 5d: We need treatment END date first
  
  adsl <- adsl %>%
    derive_vars_merged(
      dataset_add = ex_ext,
      filter_add = (EXDOSE > 0 | 
                      (EXDOSE == 0 & str_detect(EXTRT, "PLACEBO"))) & 
        !is.na(EXENDTM),
      new_vars = exprs(TRTEDTM = EXENDTM),
      order = exprs(EXENDTM, EXSEQ),
      mode = "last",  # Take last (latest) exposure
      by_vars = exprs(STUDYID, USUBJID)
    ) %>%
    derive_vars_dtm_to_dt(source_vars = exprs(TRTEDTM))  # Convert treatment end datetime to date
  
 
  
  
## 5e: Merge all date sources and compute maximum

  adsl <- adsl %>%
    left_join(vs_dates, by = c("STUDYID", "USUBJID")) %>%     # Merge VS dates
    left_join(ae_dates, by = c("STUDYID", "USUBJID")) %>%     # Merge AE dates
    left_join(ds_dates, by = c("STUDYID", "USUBJID")) %>%     # Merge DS dates
    rowwise() %>%
    mutate(
      LSTAVLDT = max(c(last_vs_dt, last_ae_dt, last_ds_dt, TRTEDT), na.rm = TRUE) # Take max across all 4 sources, ignoring NA values
         ) %>%
      ungroup() %>%
      mutate(
      # If max() returns -Inf (all dates were NA), set to NA
      LSTAVLDT = if_else(is.infinite(LSTAVLDT), as.Date(NA), LSTAVLDT)
    ) %>%

    select(-last_vs_dt, -last_ae_dt, -last_ds_dt)  # Clean up temporary date columns
  
    cat("  LSTAVLDT derived for", sum(!is.na(adsl$LSTAVLDT)), "subjects\n")

    
    
    


#--- 6: Add Some Essential Standard ADSL Variables to make dataset more well rounded ---
    #opportunity to practice more admiral functions
    
## Treatment duration (days on treatment)
## Uses admiral function to calculate TRTEDT - TRTSDT + 1
    
    adsl <- adsl %>%
      derive_var_trtdurd()
    
    # Treatment variables (planned and actual)
    adsl <- adsl %>%
      mutate(
        TRT01P = ARM,    # Planned treatment 
        TRT01A = ACTARM  # Actual treatment 
      )
    
    cat("  TRTDURD derived for", sum(!is.na(adsl$TRTDURD)), "subjects\n")
    
    
    
    
    
    
    
    
#--- Step 7: Add Variable Labels to make ADSL coherent ---
#     Using ADAM IG V1.3 for new variable labels 
    
    library(labelled)
    
    adsl <- adsl %>%
      set_variable_labels(
        AGEGR9 = "Pooled Age Group 9",
        AGEGR9N = "Pooled Age Group 9 (N)",
        
        # Treatment Start/End Dates and Times (Assessment Requirement)
        TRTSDTM = "Datetime of First Exposure to Treatment",
        TRTSTMF = "Time of First Exposure Imput. Flag",
        TRTSDT = "Date of First Exposure to Treatment",
        TRTEDTM = "Datetime of Last Exposure to Treatment",
        TRTEDT = "Date of Last Exposure to Treatment",
        TRTDURD = "Total Treatment Duration (Days)",
        
        # Treatment Variables
        TRT01P = "Planned Treatment for Period 01",
        TRT01A = "Actual Treatment for Period 01",
        
        # Intent-to-Treat Flag (Assessment Requirement)
        ITTFL = "Intent-to-Treat Population Flag",
        
        # Last Known Alive Date (Assessment Requirement)
        LSTAVLDT = "Date Last Known Alive"
      )
    
    cat("  Labels added for custom derived variables\n")
    
    
    print(adsl)
  