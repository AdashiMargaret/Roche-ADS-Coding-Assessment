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





#---2. filter data for analysis---

## Filter ADSL: Safety population only (this automatically excludes Screen Failures)
adsl_filtered <- adsl %>%
  filter(SAFFL == "Y")

cat("ADSL after filtering (Safety Population):\n")
print(table(adsl_filtered$ACTARM))
cat("\n")


## Filter ADAE: Treatment-emergent AEs, Safety population

adae_filtered <- adae %>%
  filter(TRTEMFL == "Y",
         SAFFL == "Y")

cat("ADAE after filtering:", nrow(adae_filtered), "records\n")
cat("Treatment groups in filtered ADAE:\n")
print(table(adae_filtered$ACTARM))


## Count unique subjects per treatment group (for denominator)
n_subjects <- adsl_filtered %>%
  count(ACTARM, name = "N")

print(n_subjects)
cat("\n")




#---3. Create hierarchical Adverse Event Table---

##Structure: System Organ Class (AESOC) → Reported Term (AETERM)
tbl_ae <- adae_filtered %>%
  tbl_hierarchical(
    variables = c(AESOC, AETERM),   # Hierarchy: SOC → Reported Term
    by = ACTARM,                     # Split by treatment arm
    id = USUBJID,                    # Subject identifier
    denominator = adsl_filtered,     # Use filtered ADSL for denominators
    overall_row = TRUE,              # Add "Any TEAE" summary row at top
    label = list(
      "..ard_hierarchical_overall.." = "Treatment Emergent AEs"
    )
  ) %>%
  add_overall(last = TRUE) %>%       # Add "Overall" column at the end
  bold_labels() %>%
  modify_header(
    all_stat_cols() ~ "**{level}**<br>N = {n}"
  ) %>%
  modify_footnote(
    all_stat_cols() ~ "n (%)"
  )
##sort by descending frequency
tbl_ae <- sort_hierarchical(tbl_ae, sort = everything() ~ "descending")

##Display the table
cat("Treatment-Emergent Adverse Events Summary Table:\n\n")
print(tbl_ae)



