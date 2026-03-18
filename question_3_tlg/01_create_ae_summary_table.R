#------------------------------------------------------------------------------
# Question 3: TLG - Adverse Events Summary Table
# Author: Adashi Odama
# Date: 03/18/2026
#
# Objective: Create a summary table of treatment-emergent adverse events (TEAEs)
#            using {gtsummary}

# Input: pharmaverseadam::adae, pharmaverseadam::adsl
# Output: ae_summary_table.html
#------------------------------------------------------------------------------


# Install and Load packages

install.packages(c("dplyr", "pharmaverseadam","gtsummary", "gt"))

library(pharmaverseadam)
library(gtsummary)      
library(dplyr)            
library(gt)             

#---1. Load datasets and check variables structure before table production---
adae <- pharmaverseadam::adae
adsl <- pharmaverseadam::adsl


## Check key variables in ADAE
cat("Key ADAE variables:\n")
cat("- TRTEMFL (Treatment-Emergent Flag):", unique(adae$TRTEMFL), "\n")
cat("- ACTARM (Actual Treatment):", unique(adae$ACTARM), "\n")
cat("- AESOC (System Organ Class) - First 5:", head(unique(adae$AESOC), 5), "\n")
cat("- AETERM (Preferred Term) - First 5:", head(unique(adae$AETERM), 5), "\n\n")

## Check SAFFL (Safety Population Flag) if it exists
if("SAFFL" %in% names(adae)) {
  cat("- SAFFL (Safety Flag) in ADAE:", unique(adae$SAFFL), "\n")
}
if("SAFFL" %in% names(adsl)) {
  cat("- SAFFL (Safety Flag) in ADSL:", unique(adsl$SAFFL), "\n\n")
}

## Check treatment groups in ADSL
print(table(adsl$ACTARM))


## Check how many treatment-emergent AEs we have
print(table(adae$TRTEMFL))


## View structure of key variables
str(adae[, c("USUBJID", "TRTEMFL", "ACTARM", "AESOC", "AETERM")])




