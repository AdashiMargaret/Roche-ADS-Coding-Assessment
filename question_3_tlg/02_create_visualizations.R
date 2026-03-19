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
cat("Author: Adashi Odama\n")
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

## Filter data (SAFFL). Only focusing on safety because there is no mention of TEAE consideration
adae_filtered <- adae %>%
  filter(SAFFL == "Y")

## Explore AESEV variable
  cat("AESEV (Severity) levels:\n")
  print(table(adae_filtered$AESEV, useNA = "ifany"))
  cat("\n")

  cat("AESEV by treatment:\n")
  print(table(adae_filtered$ACTARM, adae_filtered$AESEV))
  cat("\n")

## Check if AESEV has any missing values
  cat("Missing AESEV values:", sum(is.na(adae_filtered$AESEV)), "\n\n")
  
  
  

#---2: Create Plot 1 - AE Severity Distribution by Treatment---
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
  
  
  
  
  
#---3: Create Plot 2 - Top 10 Most Frequent AEs with 95% CI---
  
  
## Get unique subject-AE combinations 
    ae_subject_level <- adae_filtered %>%
    distinct(USUBJID, AETERM)
  
## Count subjects per AE term and calculate proportions
  ae_freq <- ae_subject_level %>%
    count(AETERM, name = "subjects") %>%
    arrange(desc(subjects)) %>%
    head(10)  # Get top 10
  
##view data
  cat("Top 10 AE frequencies\n")
  print (ae_freq)
  
  
## Calculate total subjects for proportion
  total_subjects <- n_distinct(adae_filtered$USUBJID)
  
cat("Total subjects in analysis:", total_subjects, "\n\n")
  



#---4 Add proportion and 95% CI--

##Calculate CIs

 ae_freq <- ae_freq %>%
   mutate(
    prop = subjects / total_subjects,
    # Calculate 95% CI using binomial proportion
    ci_lower = (prop - 1.96 * sqrt(prop * (1 - prop) / total_subjects))*100,
    ci_upper = (prop + 1.96 * sqrt(prop * (1 - prop) / total_subjects))*100
  )

cat("Top 10 Most Frequent Adverse Events")
print(ae_freq)
cat("\n")

##plot CI using geom_errorbar()

plot2 <- ggplot(ae_freq, aes(x = reorder(AETERM, prop), y = prop*100)) +
         geom_point(size = 3) +
         geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.2) +
         coord_flip() +  # Flip coordinates to make it vertical
         scale_y_continuous(labels = function(x) paste0(x, "%")) +  # Add % to labels
         labs(
         title = "Top 10 Most Frequent Adverse Events",
         subtitle = paste0("n= ", total_subjects, " subjects; 95% Clopper-Pearson CIs"),
         x = "",
         y = "Percentage of Patients(%)"
         ) +
         theme(
         plot.title = element_text(hjust = 0, size = 14),
         plot.subtitle = element_text(hjust = 0, size = 12),
         panel.background = element_rect(fill = "gray95"), # include gray background
         panel.grid.major = element_line(color = "white"),# White minor gridlines
         axis.title.x = element_text(hjust = 0.6) # to align axis title a bit more closely to sample
         )


print (plot2)


## Save plot
  ggsave(
     filename = "top10_ae_incidence.png",
     plot = plot2,
     width = 10,
     height = 6,
     dpi = 300
     )

cat("\n✓ Plot 2 saved as: top10_ae_incidence.png\n\n")





#------------------------------------------------------------------------------
# End of Script
#------------------------------------------------------------------------------

cat("\n================================================================================\n")
cat("Script completed successfully!\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("Author: Adashi Odama\n")
cat("\nOutputs created:\n")
cat("  - ae_severity_by_treatment.png\n")
cat("  - top10_ae_incidence.png\n")
cat("================================================================================\n")

# Stop logging
sink()

cat("Log file saved as:", log_file, "\n")
