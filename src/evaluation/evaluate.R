
paste(">>> Evaluates predictions quality")
args = commandArgs(TRUE)

test = ifelse (length(args)>=1, args[[1]], "../../data/allrecipes.tsv")
predict = ifelse (length(args)>=2, args[[2]], "../../data/predictions.tsv")

outputs = c("kcal", "fat", "cholesterol", "carbohydrates", "proteins", "sugars", "sodium")
if (length(args)>=3) outputs = strsplit(args[[3]], ",")

print(paste("test =", test))
print(paste("predict =", predict))
print(paste("output cols =", paste(outputs, collapse = ",")))

###############################################################################

test = read.table(test, header=1)
cat("Loaded ",dim(test)[1], "rows from testing file\n")
predict = read.table(predict, header=1)
cat("Loaded ",dim(predict)[1], "rows from prediction file\n")

###############################################################################

m = match(predict$href, test$href)
m = m[!is.na(m)]
test = test[m, ]

m = match(test$href, predict$href)
m = m[!is.na(m)]
predict = predict[m, ]

cat(dim(test)[1], "rows matched\n")

if (sum(as.character(predict$href)!=as.character(test$href))) {
  head(predict)
  head(test)
  stop("sum(as.character(predict$href)!=as.character(test$href))")
}

###############################################################################

#keep only columns present in both files:
outputs = intersect(outputs, colnames(predict))
print(paste("kept output cols =", paste(outputs, collapse = ",")))

###############################################################################

#prediction's must be postivie
predict[predict<0] = 0

###############################################################################

mape = function(predicted, test) {
  predicted = predicted[test!=0]
  test = test[test!=0]
  mean(abs(predicted-test)/test)
} 


smape = function(predicted, test) {
  predicted = predicted[test!=0]
  test = test[test!=0]
  
  mean( 2 * abs(predicted-test)/(abs(predicted)+abs(test)) )
} 

###############################################################################

library(hydroGOF)

errs = c()
for (col in outputs) {
  m = mean(test[[col]])
  err = rmse(predict[[col]], test[[col]])
  print(paste("rmse of",col,"=",round(err,3), " mean =", round(m,3), " err/mean[%] =", round(err/m*100,3)))
  errs = c(errs, err/m)
}
print(paste("[**] rmse/mean avg over outputs = ", round(100*mean(errs),2), "[%]"))

errs = c()
for (col in outputs) {
  m = mean(test[[col]])
  err = mae(predict[[col]], test[[col]])
  print(paste("mae of",col,"=",round(err,3), " mean =", round(m,3), " err/mean[%] =", round(err/m*100,3)))
  errs = c(errs, err/m)
}
print(paste("[**] mae/mean avg over outputs = ", round(100*mean(errs),2), "[%]"))


errs = c()
for (col in outputs) {
  m = mean(test[[col]])
  err = mape(predict[[col]], test[[col]])
  print(paste("mape corrected[%] of",col,"=",round(100*err,3)))
  errs = c(errs, err)
}
print(paste("[**] mape corrected avg over outputs = ", round(100*mean(errs),2), "[%]"))


errs = c()
for (col in outputs) {
  m = mean(test[[col]])
  err = smape(predict[[col]], test[[col]])
  print(paste("smape [%] of",col,"=",round(100*err,3)))
  errs = c(errs, err)
}
print(paste("[**] smape avg over outputs = ", round(100*mean(errs),2), "[%]"))

