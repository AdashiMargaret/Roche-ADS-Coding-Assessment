#------------------------------------------------------------------------------
# Question 3: TLG - Adverse Events Visualizations
# Author: Adashi Odama
# Date: 03/18/2026
#
# Objective: Create visualizations of adverse events using {ggplot2}
# Treating Sample outputs like a TLG shell and seeking to match 100%
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
  
  
  

#---Step 2: Create Plot 1 - AE Severity Distribution by Treatment---
  severity_data <- adae_filtered %>%
    count(ACTARM, AESEV, name = "n_events")
  
  cat("Severity distribution data:\n")
  print(severity_data)
  cat("\n")
  
  
## Define custom colors for severity levels as indicated in Assessment Sample
  severity_colors <- c(
    "MILD" = "red",
    "MODERATE" = "green",
    "SEVERE" = "blue"
  )
  
## Create stacked bar chart
  plot1 <- ggplot(severity_data, aes(x = ACTARM, y = n_events, fill = AESEV)) +
    geom_bar(stat = "identity", position = "stack") +
    labs(
      title = "AE severity distribution by treatment",
      x = "Treatment Arm",
      y = "Count of AEs",
      fill = "Severity/Intensity"
    ) +
    theme(
      plot.title = element_text(hjust = 0, size = 14),
      legend.position = "right",
      panel.background = element_rect(fill = "gray90") # to match background in Assessment example
    )
  
## Display plot1
  print(plot1)
  
  
## Save plot1
  ggsave(
    filename = "ae_severity_by_treatment.png",
    plot = plot1,
    width = 10,
    height = 6,
    dpi = 300
  )
  
  cat("\n✓ Plot 1 saved as: ae_severity_by_treatment.png\n\n")
  

