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

install.packages(c("admiral", "lubridate","stringr"))
library(admiral)
library(pharmaversesdtm)
library(dplyr)
library(tidyr)
library(lubridate)
library(stringr)

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

# Apply the functions to create age groups
adsl <- adsl %>%
  mutate(
    AGEGR9 = format_agegr9(AGE),
    AGEGR9N = format_agegr9n(AGE)
  )

# Verify the derivation

print(table(adsl$AGEGR9, useNA = "ifany"))
print(table(adsl$AGEGR9N, useNA = "ifany"))

cat("Step 2 Complete\n\n")


  




