
train = "~/tmp/train_lm_8009.tsv"
train.features = "~/tmp/train_features_lm_8009.tsv"
test = "~/tmp/test_lm_8009.tsv"
test.features = "~/tmp/test_features_lm_8009.tsv"
prediction.file = "~/tmp/predictions.tsv"

paste(">>> Predicts outputs with GBM")

source(file="../models_common/parsing_args.R")
predict.params$n.trees=1000

source(file="../models_common/data_loading.R")
source(file="../models_common/features_filtering.R")


#####################################################################################

library(gbm)

predicted = c()
for (col.name in outputs) {
  print(paste("predicting for", col.name))

  ###########################################################
  
  start = Sys.time()
  #train.frame = cbind(train[col.name], train.features)
  formula = as.formula(paste(col.name, "~."))
  #l1 = gbm(formula, data=train.frame, 
  #        n.trees=1000, shrinkage=0.05, cv.folds=5, interaction.depth=4, n.minobsinnode=5)
  l1 = do.call(gbm, 
               c(list(formula=formula, data=cbind(train[col.name], train.features)), train.params))
  cat("Building time:", as.numeric(Sys.time()-start,units="secs"),"s\n")
  #pretty.gbm.tree(l1, 1)
  summary(l1)
  
  start = Sys.time()
  test.frame  = cbind(test[col.name], test.features)
  #p = predict.gbm(l1, newdata=test.frame, 1000)
  p = do.call(predict.gbm, c(list(object=l1, newdata=test.frame), predict.params))
  cat("Prediction time:", as.numeric(Sys.time()-start,units="secs"),"s\n")
  
  ###########################################################
  
  predicted = cbind(predicted, p)
}


colnames(predicted) = outputs

#####################################################################################

write.table(predicted, prediction.file, sep="\t", row.names = F, col.names = T)
