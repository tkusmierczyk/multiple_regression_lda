

paste(">>> Predicts outputs with LM")


source(file="../models_common/parsing_args.R")
source(file="../models_common/data_loading.R")
source(file="../models_common/features_filtering.R")

#####################################################################################
#####################################################################################

predicted = c()
for (col.name in outputs) {
  print(paste("predicting for", col.name))
  
  ###########################################################
  
  start = Sys.time()
  formula = as.formula(paste(col.name, "~."))  
  #train.frame = cbind(train[col.name], train.features)
  #l1 = lm(formula, data=train.frame)
  l1 = do.call(lm, c(list(formula=formula, 
                          data=cbind(train[col.name], train.features)), train.params))
  cat("Building time:", as.numeric(Sys.time()-start,units="secs"),"s\n")
  summary(l1)
  
  start = Sys.time()
  test.frame  = cbind(test[col.name], test.features)
  #p = predict(l1, newdata=test.frame)
  p = do.call(predict.lm, c(list(object=l1, newdata=test.frame), predict.params))
  cat("Prediction time:", as.numeric(Sys.time()-start,units="secs"),"s\n")
  
  ###########################################################
    
  predicted = cbind(predicted, p)
}
colnames(predicted) = outputs

#####################################################################################

write.table(predicted, prediction.file, sep="\t", row.names = F, col.names = T)
