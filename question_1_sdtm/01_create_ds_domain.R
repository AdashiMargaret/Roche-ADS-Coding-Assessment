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


#---1. Generate OAK ID variables to link raw data to SDTM

raw_ds <- raw_ds %>%
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "raw_ds"
  )
print (raw_ds)


#-- 2. Define VISITNUM Lookup Table ---
### Making a personal lookup table for the purpose of this assessment

unique(raw_ds$INSTANCE)

visitnum_lookup <- data.frame(
  INSTANCE = c(
    "Screening 1", "Baseline",
    "Week 2", "Week 4", "Week 6", "Week 8",
    "Week 12", "Week 16", "Week 20", "Week 24", "Week 26",
    "Ambul Ecg Removal", "Retrieval",
    "Unscheduled 1.1", "Unscheduled 4.1", "Unscheduled 5.1",
    "Unscheduled 6.1", "Unscheduled 8.2", "Unscheduled 13.1"
  ),
  VISITNUM = c(
    -28, 1, 2, 4, 6, 8, 12, 16, 20, 24, 26,
    888, 9000,
    99, 99, 99, 99, 99, 99
  )
)

### Join VISITNUM to ds_raw
raw_ds <- raw_ds %>%
  left_join(visitnum_lookup, by = "INSTANCE")

### Verify mapping & no missing visitnum
raw_ds %>%
  select(INSTANCE, VISITNUM) %>%
  distinct() %>%
  arrange(VISITNUM) %>%
  print(n = 25)

#----3. Map Basic Variables (No Controlled Terminology needed)

### STUDYID - Study Identifier
STUDYID <- assign_no_ct(
  raw_dat = raw_ds,
  raw_var = "STUDY",
  tgt_var = "STUDYID",
  id_vars = oak_id_vars()
)

### USUBJID - Unique Subject Identifier
USUBJID <- assign_no_ct(
  raw_dat = raw_ds,
  raw_var = "PATNUM",
  tgt_var = "USUBJID",
  id_vars = oak_id_vars()
)

### VISIT - Visit Name
VISIT <- assign_no_ct(
  raw_dat = raw_ds,
  raw_var = "INSTANCE",
  tgt_var = "VISIT",
  id_vars = oak_id_vars()
)

### DSTERM - Reported Term for Disposition
DSTERM <- assign_no_ct(
  raw_dat = raw_ds,
  raw_var = "IT.DSTERM",
  tgt_var = "DSTERM",
  id_vars = oak_id_vars()
)


# Preview
print(head(STUDYID))
print(head(USUBJID))
print(head(VISIT))
print(head(DSTERM))












