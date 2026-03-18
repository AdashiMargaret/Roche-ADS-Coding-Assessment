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
