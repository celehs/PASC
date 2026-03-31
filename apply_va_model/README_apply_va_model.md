# How to apply VA trained model (PheCode only)
To apply the LATCH phenotype for Long Covid, you may either 1) train your own model or 2) apply the VA trained model. Below are the steps for option 2), applying the VA trained model.

### Files needed from Github download:
* trained xgboost tree models:
	* `PheCode_12_inpat.json`
	* `PheCode_12_outpat.json`
	* `PheCode_3_allpat.json`
* codified feature names:
	* `xgb.model.port.clean.PheCode_12_inpat.Rdata`
	* `xgb.model.port.clean.PheCode_12_outpat.Rdata`
	* `xgb.model.port.clean.PheCode_3_allpat.Rdata`
* `apply_va_phecode_model.R` - template code to apply the model to your patient data

### Data needed from your patient population:
Your patient EHR feature data should be formatted in a table with the following columns: 
* `patient_num`: patient ID
* `u099.flag`: 0/1 flag to indicate presence of u099 icd code ever in EHR data
* `period12`: 1=pre u09.9 period, 0=post u09 period
* `inpat`: 0/1 flag to indicate inpatient(1) vs outpatient(0) at the time of SARS-CoV-2 infection (-7 to +14 days)
* 357 phecode features as listed in the codified features `.Rdata` objects. More info below. 

#### Curating PheCode (version 1.2) Features
Feature names follow the format `m_X041` or `n_X840.3` in the .Rdata objects listed above under "codified feature names".
* The number after "X" indicates the PheCode number (e.g., PheCode 041, PheCode 840.3)
* For ICD codes mapped to each PheCode, refer to the PheWAS catalog: https://phewascatalog.org/phewas/#phe12

**Feature Type Prefixes:**
* **`n_`** — Count of distinct dates a new-onset feature appears post-COVID-19 (0-6 months after infection)
  * *Example:* If PheCode 008.5 appears on 3 different dates → `n_X008.5 = 3`
* **`m_`** — Number of months (within 0-6 month window) in which a new-onset feature was observed at least once
  * *Example:* After infection in Oct 2022, PheCode 008.5 observed in Nov 2022, Jan 2023, and March 2023 → `m_X008.5 = 3`

### Using the code template
To run the `apply_va_phecode_model.r` script:
* install R packages `dplyr` and `xgboost`
* modify the paths in the script commented with "EDIT" flags to point to the correct paths and align model object names. 
* run the R code. 




