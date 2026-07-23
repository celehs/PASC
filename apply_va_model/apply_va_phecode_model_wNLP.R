library(dplyr)
rm(list=ls())

### import pt data
my_patient_data <- read.csv(file="./fake_patient_data.csv") ### EDIT TO PATH TO PATIENT DATA OBJECT. 

### import feature names ###
indir = "./xgboost_model_files" ### EDIT TO DIRECTORY CONTAINING XGBOOST MODEL FILES
fnames = c("xgb.model.port.clean.PheCode_12_inpat.Rdata", 
           "xgb.model.port.clean.PheCode_12_outpat.Rdata", 
           "xgb.model.port.clean.PheCode_3_allpat.Rdata",
           "xgb.model.port.clean.PheCodeNLP_12_inpat.Rdata", 
           "xgb.model.port.clean.PheCodeNLP_12_outpat.Rdata", 
           "xgb.model.port.clean.PheCodeNLP_3_allpat.Rdata"
)
feature.names = list()
for (i in 1:length(fnames)) {
  f = file.path(indir, fnames[i])
  m_name = sub(".Rdata", "", fnames[i])
  m_name = sub("xgb.model.port.clean.", "", m_name)
  load(f)
  feature.names[[m_name]] = xx$feature_names
}

#### import the xgboost jsons ####
library(xgboost)
indir = "./xgboost_model_files" ### EDIT TO DIRECTORY CONTAINING XGBOOST MODEL FILES
fnames = c(
  "PheCode_12_inpat.json", 
  "PheCode_12_outpat.json", 
  "PheCode_3_allpat.json",
  "PheCodeNLP_12_inpat.json", 
  "PheCodeNLP_12_outpat.json", 
  "PheCodeNLP_3_allpat.json"
  )
xgb.model = list()
for (i in 1:length(fnames)) {
    f = file.path(indir, fnames[i])
    m_name = sub(".json", "", fnames[i])
    m = xgb.load(f)
    xgb.model[[m_name]] = m
}

### apply xgboost models to pt data to get xgboost scores
xgb.pred0=NULL
for (i in 1:length(xgb.model)){
    m = xgb.model[[i]]
    m_name = names(xgb.model)[[i]]
    # print(m_name)

    ### get correct feature list
    feature.sel.keep <- feature.names[[i]] 
    if(grepl("allpat", m_name)){
        feature.sel.keep=c("inpat", feature.sel.keep)
    }
    dtest = xgb.DMatrix(
      data=data.matrix(my_patient_data[,which(colnames(my_patient_data) %in% feature.sel.keep)]),
      label=my_patient_data[,"u099.flag"]
    )
    xgb.pred0=cbind(xgb.pred0, predict(m, dtest))
}
colnames(xgb.pred0) = ls(xgb.model)


### clean up dataset for application of regression model

### variables needed:
## - patient_num: patient ID
## - u099.flag: 0/1 flag to indicate presence of u099 icd code
## - period12: 1=pre u09.9 period, 0=post u09 period.
## - inpat: 0/1 flag to indicate inpatient(1) vs outpatient(0)
xgb.pred = data.frame(patient_num = my_patient_data$patient_num,
                      u099.flag = my_patient_data$u099.flag,
                      period12 = my_patient_data$period12,
                      inpat = my_patient_data$inpat,
                      xgb.pred0)


## "cohort alignment step": align the xgboost scores based on inpat/outpat status, infection period
##  aligned xgboost score is called "model.score"
dat.ssl <- data.frame(
  U099_Count = my_patient_data$U099_Count,
  xgb.pred
)
dat.ssl <- dat.ssl %>% 
  mutate(model.score = case_when(
    u099.flag==1 & period12==1 & inpat==1 ~ PheCode_12_inpat,
    u099.flag==1 & period12==1 & inpat==0 ~ PheCode_12_outpat,
    u099.flag==1 & period12==0 ~ PheCode_3_allpat,
    u099.flag==0 & period12==1 & inpat==1 ~ PheCodeNLP_12_inpat,
    u099.flag==0 & period12==1 & inpat==0 ~ PheCodeNLP_12_outpat,
    u099.flag==0 & period12==0 ~ PheCodeNLP_3_allpat
  ))

## Application of regression model
dat.ssl$ssl_who=g.logit(-2.7593102+1.4905589*period12+0.9853423*log(dat.ssl$U099_Count+1)+0.3281200*dat.ssl$model.score)


