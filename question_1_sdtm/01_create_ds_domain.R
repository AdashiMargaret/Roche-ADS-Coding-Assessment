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

#Read in Study CT---
study_ct <- read.csv("sdtm_ct.csv", stringsAsFactors = FALSE)

#Bringing in Demographics (DM)

dm <- pharmaversesdtm::dm 

#Check data formats
print(str(raw_ds))
print(head(study_ct))


#---1. Generate OAK ID variables to link raw data to SDTM---

raw_ds <- raw_ds %>%
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "raw_ds"
  )
print (raw_ds)




# ---2.Derive DSTERM, DSDECOD and DSCAT based on eCRF logic ---
### DSTERM  - IF OTHERSP not null → OTHERSP, ELSE IT.DSTERM
### DSDECOD - IF OTHERSP not null → OTHERSP, ELSE IT.DSDECOD
### DSCAT   - IF DSDECOD = "Randomized"      → "PROTOCOL MILESTONE"
#           ELSE IF OTHERSP not null        → "OTHER EVENT"
#           ELSE                            → "DISPOSITION EVENT"
raw_ds <- raw_ds %>%
  mutate(
    DSTERM_raw = case_when(
      !is.na(OTHERSP) & OTHERSP != "" ~ OTHERSP,
      TRUE                             ~ IT.DSTERM
    ),
    DSDECOD_raw = case_when(
      !is.na(OTHERSP) & OTHERSP != "" ~ toupper(OTHERSP), #To match some DSDECOD values in CT
      TRUE                             ~ toupper(IT.DSDECOD)
    ),
    DSCAT = case_when(
      IT.DSDECOD == "Randomized"       ~ "PROTOCOL MILESTONE",
      !is.na(OTHERSP) & OTHERSP != "" ~ "OTHER EVENT",
      TRUE                             ~ "DISPOSITION EVENT"
    ), 
    VISIT_raw = toupper(INSTANCE) # To match VISIT CT
  )

### Verify all three
raw_ds %>%
  select(IT.DSTERM, IT.DSDECOD, OTHERSP, DSTERM_raw, DSDECOD_raw, DSCAT) %>%
  distinct() %>%
  print(n = 30)



#--- 3.Define complete VISITNUM lookup table (based on CT file) ---
### Some unscheduled visits not included in CT so hardcoding to maintain consistency

unique(raw_ds$INSTANCE)

visitnum_lkp <- data.frame(
  INSTANCE = c(
    "Screening 1", "Screening", "Screening 2", "Baseline",
    "Week 2", "Week 4", "Week 6", "Week 8",
    "Week 12", "Week 16", "Week 20", "Week 24", "Week 26",
    "Ambul Ecg Removal", "Retrieval",
    "Unscheduled 1.1", "Unscheduled 4.1", "Unscheduled 5.1",
    "Unscheduled 6.1", "Unscheduled 8.2", "Unscheduled 13.1"
  ),
  VISITNUM = c(
    1,1, 2, 3,
    4, 5, 7, 8, 9, 10, 11, 12, 13,
    6, 201,
    1.1, 4.1, 5.1,
    6.1, 8.2, 13.1
  )
)

raw_ds <- raw_ds %>%
  left_join(visitnum_lkp, by = "INSTANCE")

### Verify
raw_ds %>%
  select(INSTANCE, VISITNUM) %>%
  distinct() %>%
  arrange(VISITNUM) %>%
  print(n = 25)


# ---4.  Map Variables ---


### STUDYID - Study Identifier (no CT needed)
STUDYID <- assign_no_ct(
  raw_dat = raw_ds,
  raw_var = "STUDY",
  tgt_var = "STUDYID",
  id_vars = oak_id_vars()
)

### USUBJID - Unique Subject Identifier (no CT needed)

###Noticed a prefix "01" before the PATNUM in DM that is not present in raw DS. Under the assumption
### that this is a raw data issue which is common, will be adding the prefix to DS to match parent dataset DM
##Until raw data is hopefully fixed after issue is logged and sent for resolution ----

raw_ds <- raw_ds %>%
  mutate(USUBJID_fmt = paste0("01-", PATNUM))

USUBJID <- assign_no_ct(
  raw_dat = raw_ds,
  raw_var = "USUBJID_fmt",
  tgt_var = "USUBJID",
  id_vars = oak_id_vars()
)

### DSTERM - Reported Term (no CT, uses eCRF derived column)
DSTERM <- assign_no_ct(
  raw_dat = raw_ds,
  raw_var = "DSTERM_raw",
  tgt_var = "DSTERM",
  id_vars = oak_id_vars()
)

### DSDECOD - Preferred Term with some values in CT all capitalized so did it for all
DSDECOD <- assign_no_ct(
  raw_dat = raw_ds,
  raw_var = "DSDECOD_raw",
  tgt_var = "DSDECOD",
  id_vars = oak_id_vars()
)

### VISIT - uppercase of INSTANCE (no CT needed)
VISIT <- assign_no_ct(
  raw_dat = raw_ds,
  raw_var = "VISIT_raw",
  tgt_var = "VISIT",
  id_vars = oak_id_vars()
)


### DOMAIN - hardcoded to "DS"
DOMAIN <- hardcode_no_ct(
  raw_dat = raw_ds,
  raw_var = "PATNUM",
  tgt_var = "DOMAIN",
  tgt_val = "DS",
  id_vars = oak_id_vars()
)




print(head(STUDYID))
print(head(USUBJID))
print(head(DSTERM))
print(head(DOMAIN))
print(head(VISIT))
print(head(VISITNUM))
print(head(DSDECOD))
print(head(DSCAT))


# ---5. Datetime Derivations----

### DSDTC - Date/Time of Collection (date + time combined)
DSDTC <- assign_datetime(
  raw_dat = raw_ds,
  raw_var = c("DSDTCOL", "DSTMCOL"),
  tgt_var = "DSDTC",
  raw_fmt = c("m-d-y","H:M"),
  raw_unk = c("UN", "UNK"),
  id_vars = oak_id_vars()
)


### DSSTDTC - Start Date/Time of Disposition Event
DSSTDTC <- assign_datetime(
  raw_dat = raw_ds,
  raw_var = c("IT.DSSTDAT"),
  tgt_var = "DSSTDTC",
  raw_fmt = c("m-d-y"),
  raw_unk = c("UN", "UNK"),
  id_vars = oak_id_vars()
)

print(head(DSDTC))
print(head(DSSTDTC))



#---6. Combine Datasets---

ds <- STUDYID %>%
  left_join(DOMAIN,   by = "oak_id") %>%
  left_join(USUBJID,  by = "oak_id") %>%
  left_join(DSTERM,   by = "oak_id") %>%
  left_join(DSDECOD,  by = "oak_id") %>%
  left_join(VISIT,    by = "oak_id") %>%
  left_join(VISITNUM, by = "oak_id") %>%
  left_join(DSDTC,    by = "oak_id") %>%
  left_join(DSSTDTC,  by = "oak_id") %>%
  
 mutate(VISITNUM = ifelse(
   raw_ds$VISITNUM == floor(raw_ds$VISITNUM),
   as.integer(raw_ds$VISITNUM),
   raw_ds$VISITNUM
 ),
    DSCAT = raw_ds$DSCAT) %>%
  
# --- 7. Derive DSSEQ ---
   derive_seq(
    tgt_var = "DSSEQ",
    rec_vars = c("USUBJID", "DSSTDTC")) %>%
  
# --- 8. Derive DSSTDY ---
  derive_study_day(
    sdtm_in = .,
    dm_domain = dm,
    tgdt = "DSSTDTC",
    refdt = "RFSTDTC",
    study_day_var = "DSSTDY") %>%
  
# --- 9. Select final SDTM variables ---
  select(
    "STUDYID", "DOMAIN", "USUBJID", "DSSEQ",
    "DSTERM", "DSDECOD", "DSCAT",
    "VISITNUM", "VISIT",
    "DSDTC", "DSSTDTC", "DSSTDY"
  )

# Preview
print(head(ds))
