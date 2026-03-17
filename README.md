# Roche Analytical Data Science Programmer Coding Assessment

Solutions to the Roche ADS Programmer Coding Assessment covering Pharmaverse (R) and GenAI (Python) topics.

---

## Progress

| # | Question | Status |
|---|----------|--------|
| 1 | SDTM DS Domain Creation | ✅ Complete |
| 2 | ADaM ADSL Dataset Creation | 🔄 In Progress |
| 3 | TLG – Adverse Events Reporting | 🔄 In Progress |
| 4 | GenAI Clinical Data Assistant *(Bonus)* | 🔄 In Progress |

---

## Repository Structure

```
roche-ads-coding-assessment/
├── question_1_sdtm/          # Q1: SDTM DS Domain Creation
├── question_2_adam/          # Q2: ADaM ADSL Dataset Creation
├── question_3_tlg/           # Q3: TLG - Adverse Events Reporting
├── question_4_python/        # Q4 (Bonus): GenAI Clinical Data Assistant
└── README.md
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

3. **VISITNUM** — derived via a custom 22-entry lookup table (covering scheduled and unscheduled visits), left-joined by `INSTANCE`.

4. **USUBJID Fix** — raw `ds_raw` lacked the `"01-"` prefix present in parent dataset `dm`; resolved by constructing `USUBJID = paste0("01-", PATNUM)` pending raw data correction.

5. **Variable Mapping (`{sdtm.oak}` functions):**
   - `assign_no_ct()` → STUDYID, USUBJID, DSTERM, DSDECOD, VISIT
   - `hardcode_no_ct()` → DOMAIN (`"DS"`)
   - `assign_datetime()` → DSDTC (from `DSDTCOL` + `DSTMCOL`, format `"m-d-y" / "H:M"`), DSSTDTC (from `IT.DSSTDAT`, format `"m-d-y"`)

6. **Combine** — individual mapped datasets joined by `oak_id`; VISITNUM and DSCAT added via `mutate`.

7. **DSSEQ** — derived using `derive_seq(rec_vars = c("USUBJID", "DSSTDTC"))`.

8. **DSSTDY** — derived using `derive_study_day()` against `RFSTDTC` from `dm`.

9. **Output** — final dataset selected to 12 required SDTM variables, saved as `.rds` and `.csv`; execution log written to `SDTM.DS.log.txt`.

---

## Question 2: ADaM ADSL Dataset Creation (`question_2_adam/`)

**Objective:** Create an ADSL (Subject Level Analysis Dataset) from SDTM source data using the `{admiral}` package.

| File | Description |
|------|-------------|
| `create_adsl.R` | Main script to create the ADSL dataset |
| `adsl.rds` | Output ADSL dataset |
| `create_adsl.log` | Log file confirming error-free execution |

**Input datasets:** `pharmaversesdtm::dm`, `vs`, `ex`, `ds`, `ae`
**Custom derived variables:** AGEGR9, AGEGR9N, TRTSDTM, TRTSTMF, ITTFL, LSTAVLDT
**Key packages:** `admiral`, `pharmaversesdtm`, `dplyr`, `tidyr`

---

## Question 3: TLG - Adverse Events Reporting (`question_3_tlg/`)

**Objective:** Create a summary table and visualizations for adverse events using `{gtsummary}` and `{ggplot2}`.

| File | Description |
|------|-------------|
| `01_create_ae_summary_table.R` | Script to create TEAE summary table |
| `02_create_visualizations.R` | Script to create AE visualizations |
| `ae_summary_table.html` | Output summary table |
| `ae_severity_by_treatment.png` | Plot 1: AE severity distribution by treatment arm |
| `top10_ae_incidence.png` | Plot 2: Top 10 most frequent AEs with 95% CI |
| `*.log` | Log files confirming error-free execution |

**Input datasets:** `pharmaverseadam::adae`, `pharmaverseadam::adsl`
**Key packages:** `gtsummary`, `ggplot2`, `dplyr`

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

## Notes
- All R scripts follow the [tidyverse style guide](https://style.tidyverse.org/)
- Log files serve as evidence of error-free execution
- CDISC standards (SDTM IG v3.4, ADaM IG) were referenced throughout
