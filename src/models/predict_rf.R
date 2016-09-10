
#DBG
#train = "~/tmp/train_lm_8009.tsv"
#train.features = "~/tmp/train_features_lm_8009.tsv"
#test = "~/tmp/test_lm_8009.tsv"
#test.features = "~/tmp/test_features_lm_8009.tsv"
#prediction.file = "~/tmp/predictions.tsv"


paste(">>> Predicts outputs with RandomForests")
source(file="../models_common/parsing_args.R")
source(file="../models_common/data_loading.R")
source(file="../models_common/features_filtering.R")


#####################################################################################
#####################################################################################

library(randomForest)
#library(miscTools)



predicted = c()
for (col.name in outputs) {
  print(paste("predicting for", col.name))
  
  ###########################################################
  
  start = Sys.time()
  formula = as.formula(paste(col.name, "~."))
  #train.frame = cbind(train[col.name], train.features)
  #l1 = randomForest(formula, data=train.frame, 
  #                  ntree=20)
  l1 = do.call(randomForest, 
               c(list(formula=formula, data=cbind(train[col.name], train.features)), train.params))
  
  cat("Building time:", as.numeric(Sys.time()-start,units="secs"),"s\n")
  l2 = l1; l2$call = c(list(formula=formula, train.params))
  print(l2)
  summary(l1)
  
  start = Sys.time()
  test.frame  = cbind(test[col.name], test.features)
  #p = predict(l1, newdata=test.frame)
  p = do.call(predict, c(list(object=l1, newdata=test.frame), predict.params))
  cat("Prediction time:", as.numeric(Sys.time()-start,units="secs"),"s\n")
  
  ###########################################################
  
  predicted = cbind(predicted, p)
}
colnames(predicted) = outputs

#####################################################################################

write.table(predicted, prediction.file, sep="\t", row.names = F, col.names = T)
