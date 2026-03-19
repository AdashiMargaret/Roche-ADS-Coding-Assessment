#------------------------------------------------------------------------------
# Question 3: TLG - Adverse Events Visualizations
# Author: Adashi Odama
# Date: 03/18/2026
#
# Objective: Create visualizations of adverse events using {ggplot2}
#
# Input: pharmaverseadam::adae, pharmaverseadam::adsl
# Output: 
#   - ae_severity_by_treatment.png
#   - top10_ae_incidence.png
#-------------------------------------------------------------------------------

# Start logging
log_file <- "02_create_visualizations.log"
sink(log_file, split = TRUE)

cat("================================================================================\n")
cat("Script: 02_create_visualizations.R\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("================================================================================\n\n")

# Install and Load required packages

install.packages(c("dplyr", "pharmaverseadam","ggplot2"))

library(pharmaverseadam)  # For ADAE 
library(ggplot2)          # For creating visualizations
library(dplyr)            # For data manipulation


#---1: Load and Explore AESEV (Severity) Variable----


## Load datasets
  adae <- pharmaverseadam::adae


## Explore AESEV variable
  cat("AESEV (Severity) levels:\n")
  print(table(adae_filtered$AESEV, useNA = "ifany"))
  cat("\n")

  cat("AESEV by treatment:\n")
  print(table(adae_filtered$ACTARM, adae_filtered$AESEV))
  cat("\n")

## Check if AESEV has any missing values
  cat("Missing AESEV values:", sum(is.na(adae_filtered$AESEV)), "\n\n")