#------------------------------------------------------------------------------
# Question 1: SDTM DS Domain Creation using {sdtm.oak}
# Description: Create SDTM.DS(Disposition) using {sdtm.oak} package
# Author: Adashi Odama
# Date  : 03/16/2026
#------------------------------------------------------------------------------

#Install and load important packages

install.packages(c("sdtm.oak", "pharmaverseraw","pharmaversesdtm", "dplyr", "tidyr"))

library(sdtm.oak)
library(pharmaverseraw)
library(pharmaversesdtm)
library(dplyr)

#import raw dataset
raw_ds <- pharmaverseraw::ds_raw

#view dataset
print(raw_ds)

#Read in Study CT
study_ct <- read.csv("sdtm_ct.csv", stringsAsFactors = FALSE)

#Check data formats
print(str(raw_ds))
print(head(study_ct))














