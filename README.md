# Roche Analytical Data Science Programmer Coding Assessment

Solutions to the Roche ADS Programmer Coding Assessment covering Pharmaverse (R) and GenAI (Python) topics.

---

## Progress

| # | Question | Status |
|---|----------|--------|
| 1 | SDTM DS Domain Creation | ✅ Complete |
| 2 | ADaM ADSL Dataset Creation | ✅ Complete |
| 3 | TLG – Adverse Events Reporting | ✅ Complete
| 4 | GenAI Clinical Data Assistant   | 🔄 In Progress |

---
 
## Repository Structure

```
roche-ads-coding-assessment/
├── question_1_sdtm/          # Q1: SDTM DS Domain Creation
│   ├── 01_create_ds_domain.R             # DS dataset creation script
│   ├── 01_create_ds_domain.log           # Execution log
│   └── output/
│       ├── ds_domain.rds                 # DS dataset with labels (R format)
│       └── ds_domain.csv                 # DS dataset (CSV format)
├── question_2_adam/          # Q2: ADaM ADSL Dataset Creation
│   ├── create_adsl.R                     # ADSL dataset creation script
│   ├── create_adsl.log                   # Execution log
│   ├── adsl.rds                          # ADSL dataset with labels (R format)
│   └── adsl.csv                          # ADSL dataset (CSV format)
├── question_3_tlg/           # Q3: TLG - Adverse Events Reporting
│   ├── 01_create_ae_summary_table.R      # AE summary table script
│   ├── 01_create_ae_summary_table.log    # Table creation log
│   ├── ae_summary_table.html             # AE summary table (HTML)
│   ├── 02_create_visualizations.R        # AE visualizations script
│   ├── 02_create_visualizations.log      # Visualization creation log
│   ├── ae_severity_by_treatment.png      # Plot 1: Severity distribution
│   └── top10_ae_incidence.png            # Plot 2: Top 10 AEs with 95% CI
├── question_4_python/        # Q4: GenAI Clinical Data Assistant
└── README.md                 # Project documentation
```

---

## Question 1: SDTM DS Domain Creation (`question_1_sdtm/`) ✅

**Objective:** Create an SDTM Disposition (DS) domain dataset from raw clinical trial eCRF data using the `{sdtm.oak}` package.

| File | Description |
|------|-------------|
| `01_create_ds_domain.R` | Main script to create the DS domain |
| `sdtm_ct.csv` | Study controlled terminology lookup (external input) |
| `ds_domain.rds` | Output DS dataset (RDS format) |
| `ds_domain.csv` | Output DS dataset (CSV format) |
| `SDTM.DS.log.txt` | Log file confirming error-free execution |

**Inputs:**
- `pharmaverseraw::ds_raw` — raw eCRF disposition data
- `pharmaversesdtm::dm` — DM domain (for `RFSTDTC` used in study day derivation)
- `sdtm_ct.csv` — study controlled terminology file

**Output variables:** STUDYID, DOMAIN, USUBJID, DSSEQ, DSTERM, DSDECOD, DSCAT, VISITNUM, VISIT, DSDTC, DSSTDTC, DSSTDY

**Key packages:** `sdtm.oak`, `pharmaverseraw`, `pharmaversesdtm`, `dplyr`

**Approach:**

1. **Oak ID Variables** — `generate_oak_id_vars(pat_var = "PATNUM")` applied to raw data to generate `oak_id` linking keys.

2. **eCRF Derivation Logic (pre-mapping `mutate`):**
   - `DSTERM`: if `OTHERSP` is populated → use `OTHERSP`; else use `IT.DSTERM`
   - `DSDECOD`: if `OTHERSP` is populated → uppercase `OTHERSP`; else uppercase `IT.DSDECOD`
   - `DSCAT`:
     - `"PROTOCOL MILESTONE"` — when `IT.DSDECOD = "Randomized"`
     - `"OTHER EVENT"` — when `OTHERSP` is populated
     - `"DISPOSITION EVENT"` — all other records
   - `VISIT`: uppercase of `INSTANCE` for CT consistency

3. **VISITNUM** — derived using Study CT: a custom 22-entry lookup table (covering scheduled and unscheduled visits), left-joined by `INSTANCE`.

4. **USUBJID Fix** — raw `ds_raw` lacked the `"01-"` prefix present in parent dataset `dm`; resolved by constructing `USUBJID = paste0("01-", PATNUM)` pending raw data correction.

5. **Variable Mapping (`{sdtm.oak}` functions):**
   - `assign_no_ct()` → STUDYID, USUBJID, DSTERM, DSDECOD, VISIT
   - `hardcode_no_ct()` → DOMAIN (`"DS"`)
   - `assign_datetime()` → DSDTC (from `DSDTCOL` + `DSTMCOL`, format `"m-d-y" / "H:M"`), DSSTDTC (from `IT.DSSTDAT`, format `"m-d-y"`)

6. **Combine** — individual mapped datasets joined by `oak_id`; VISITNUM and DSCAT added via `mutate`.

7. **DSSEQ** — derived using `derive_seq(rec_vars = c("USUBJID", "DSSTDTC", "DSDECOD", "DSCAT"))`.

8. **DSSTDY** — derived using `derive_study_day()` against `RFSTDTC` from `dm`.

9. **Output** — final dataset selected to 12 required SDTM variables, saved as `.rds` and `.csv`; execution log written to `SDTM.DS.log.txt`.

---

## Question 2: ADaM ADSL Dataset Creation (`question_2_adam/`) ✅

**Objective:** Create an ADSL (Subject Level Analysis Dataset) from SDTM source data using the `{admiral}` package, with 4 custom derived variables.

| File | Description |
|------|-------------|
| `create_adsl.R` | Main script to create the ADSL dataset with step-by-step derivations |
| `adsl.rds` | Output ADSL dataset (R format with variable labels) |
| `adsl.csv` | Output ADSL dataset (CSV format) |
| `create_adsl.log` | Execution log with validation summary |

**Input datasets:** `pharmaversesdtm::dm`, `vs`, `ex`, `ds`, `ae`

**Custom derived variables (per assessment requirements):**

### 1. AGEGR9 & AGEGR9N - Age Grouping
- **Categories:** "<18", "18 - 50", ">50"
- **Numeric codes:** 1, 2, 3
- **Approach:** Created reusable custom functions `format_agegr9()` and `format_agegr9n()` for clean categorization
- **Results:** 305 subjects >50, 1 subject 18-50, 0 subjects <18

### 2. TRTSDTM & TRTSTMF - Treatment Start Datetime with Imputation Flag
- **TRTSDTM:** Datetime of first exposure with valid dose (EXDOSE > 0 or placebo)
- **TRTSTMF:** Time imputation flag with **special rule**
- **Complex Logic:** Flag is **NOT set** if only seconds were imputed
  - Flag set ("H") when hours/minutes imputed
  - Flag NOT set when only seconds imputed (original had HH:MM format)
- **Functions used:** `admiral::derive_vars_dtm()`, `admiral::derive_vars_merged()`
- **Results:** 254 subjects treated, all with TRTSTMF = "H" (entire time was missing in source data)

### 3. ITTFL - Intent-to-Treat Population Flag
- **Logic:** "Y" if subject was randomized (ARM populated with actual treatment), "N" otherwise

- **Clinical Decision:** Applied standard ITT definition
  - Screen failures receive "N" even though ARM is populated with "Screen Failure"
  - Rationale: ITT includes only randomized subjects; screen failures occur before randomization
  - Verified: Screen failures had no RFXSTDTC, no treatment in EX, no TRTSDTM
  
- **Results:** 254 "Y" (randomized), 52 "N" (screen failures)

### 4. LSTAVLDT - Last Known Alive Date
- **Logic:** Maximum date across 4 sources:
  1. VS (Vital Signs) - last date with valid result (VSSTRESN or VSSTRESC not missing)
  2. AE (Adverse Events) - last AE onset date
  3. DS (Disposition) - last disposition date
  4. EX (Exposure) - last treatment date (TRTEDT)
- **Approach:** 
  - Extracted dates from each source using `admiral::derive_vars_dt()`
  - Computed maximum using `pmax()` for efficiency (vs `rowwise()`)
  - Handled `-Inf` case when all sources missing using `is.finite()` check
- **Results:** 
  - VS dates: 254 subjects
  - AE dates: 224 subjects
  - DS dates: 306 subjects (all)
  - LSTAVLDT derived for all subjects with at least one source date

**Additional Standard Variables Derived:**
- TRTSDT, TRTEDT - Treatment start/end dates (from TRTSDTM/TRTEDTM)
- TRTEDTM - Treatment end datetime
- TRTDURD - Treatment duration using `admiral::derive_var_trtdurd()`
- TRT01P, TRT01A - Planned and actual treatment variables
- Variable labels for all custom derived variables using `labelled` package

**Key packages:** `admiral`, `pharmaversesdtm`, `dplyr`, `tidyr`, `lubridate`, `stringr`, `labelled`

**Programming Practices:**
- ✅ Incremental Git commits (8+ commits) showing step-by-step development
- ✅ Detailed inline comments explaining derivation logic and clinical rationale
- ✅ Applied clinical trial understanding (ITT population definition, screen failure handling)
- ✅ Comprehensive execution log with validation checks and frequency tables
- ✅ Variable labels for documentation and XPT compliance

**Validation Summary:**
- **Total Subjects:** 306 (254 treated, 52 screen failures)
- **Quality Checks:** All derivations validated, no errors in execution log
- **CDISC Compliance:** Followed ADaM IG standards for ADSL structure and variable naming

---
---

## Question 3: TLG - Adverse Events Reporting ✅ COMPLETE

### Overview
Created Tables, Listings, and Graphs (TLG) for adverse events analysis using pharmaverse packages.

### Deliverables

#### Task 1: Summary Table (gtsummary)
- **Script**: `question_3_tlg/01_create_ae_summary_table.R`
- **Output**: `question_3_tlg/ae_summary_table.html`
- **Log**: `question_3_tlg/01_create_ae_summary_table.log`

**Features:**
- Hierarchical table: System Organ Class (AESOC) → Reported Term (AETERM)
- Treatment columns: Placebo, Xanomeline High Dose, Xanomeline Low Dose, Overall
- Sorted by descending frequency
- Shows n (%) for each treatment group + Overall Column
- 217 subjects (85%) with at least one treatment-emergent AE

**Packages Used:** `{gtsummary}`, `{dplyr}`, `{gt}`

---

#### Task 2: Visualizations (ggplot2)
- **Script**: `question_3_tlg/02_create_visualizations.R`
- **Log**: `question_3_tlg/02_create_visualizations.log`

##### Plot 1: AE Severity Distribution by Treatment
- **Output**: `question_3_tlg/ae_severity_by_treatment.png`
- Stacked bar chart showing MILD, MODERATE, SEVERE distributions
- Bar chart colors consistent with sample: MILD (red), MODERATE (green), SEVERE (blue)
- Gray shaded background (gray90)

##### Plot 2: Top 10 Most Frequent AEs with 95% CI
- **Output**: `question_3_tlg/top10_ae_incidence.png`
- plot with 95% confidence intervals
- N = 225 subjects, Clopper CIs

**Packages Used:** `{ggplot2}`, `{dplyr}`

---

### Data Filtering
- **Safety Population**: `SAFFL == "Y"` (excludes screen failures)
- **Table**: Treatment-emergent AEs (`TRTEMFL == "Y"`)
- **Plots**: All AEs in safety population

### Key Learnings
- `tbl_hierarchical()` for nested SOC → Term tables
- `sort_hierarchical()` for frequency-based ordering
- `coord_flip()` for vertical forest plots
- Manual 95% CI calculation for proportions
- `scale_y_continuous()` for percentage formatting

---
---

## Question 4: GenAI Clinical Data Assistant (`question_4_python/`) *(Bonus)*

**Objective:** Build a Generative AI assistant that translates natural language questions into structured Pandas queries against the AE dataset.

| File | Description |
|------|-------------|
| `clinical_data_agent.py` | Main `ClinicalTrialDataAgent` class implementation |
| `test_queries.py` | Test script running 3 example queries |
| `adae.csv` | Input AE dataset |

**Key libraries:** `pandas`, `langchain` (or `anthropic`), `pydantic`
**Logic flow:** Natural language → LLM → Structured JSON (`target_column`, `filter_value`) → Pandas filter → Results

---

## Setup & Requirements

### R (Questions 1–3)
- R version 4.2.0 or above
- Install packages:
```r
install.packages(c("admiral", "sdtm.oak", "pharmaverseraw", "pharmaversesdtm",
                   "pharmaverseadam", "gtsummary", "ggplot2", "dplyr", "tidyr", "gt"))
```

### Python (Question 4)
- Python 3.8+
- Install dependencies:
```bash
pip install pandas langchain anthropic pydantic
```

---

## Development Approach

- **Version Control:** Incremental Git commits with clear, descriptive messages
- **Code Quality:** Detailed inline comments explaining derivation logic and clinical rationale
- **Documentation:** Comprehensive README, execution logs, and validation summaries
- **Clinical Understanding:** Applied real-world clinical trial knowledge (e.g., ITT population definition)
- **Best Practices:** Followed pharmaverse ecosystem patterns and CDISC standards (SDTM IG v3.4, ADaM IG)

---

## Notes
- All R scripts follow the [tidyverse style guide](https://style.tidyverse.org/)
- Log files serve as evidence of error-free execution
- RDS files preserve variable labels and R data types; CSV files for easy viewing
- CDISC standards (SDTM IG v3.4, ADaM IG) were referenced throughout
