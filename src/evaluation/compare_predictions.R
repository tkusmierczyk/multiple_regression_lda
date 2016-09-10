
paste(">>> Evaluates predict1ions quality")
args = commandArgs(TRUE)

test = ifelse (length(args)>=1, args[[1]], "../../data/allrecipes.tsv")
predict1 = ifelse (length(args)>=2, args[[2]], "../../data/predictions.tsv")
predict2 = ifelse (length(args)>=3, args[[3]], "../../data/predictions.tsv")


outputs = c("kcal", "fat", "cholesterol", "carbohydrates", "proteins", "sugars", "sodium")
if (length(args)>=4) outputs = strsplit(args[[4]], ",")

print(paste("test =", test))
print(paste("predict1 =", predict1))
print(paste("predict2 =", predict2))
print(paste("output cols =", paste(outputs, collapse = ",")))

###############################################################################

test = read.table(test, header=1)
cat("Loaded ",dim(test)[1], "rows from testing file\n")

predict1 = read.table(predict1, header=1)
cat("Loaded ",dim(predict1)[1], "rows from prediction file\n")

predict2 = read.table(predict2, header=1)
cat("Loaded ",dim(predict2)[1], "rows from prediction file\n")


###############################################################################

m = match(predict1$href, test$href)
m = m[!is.na(m)]
test = test[m, ]

m = match(test$href, predict1$href)
m = m[!is.na(m)]
predict1 = predict1[m, ]
predict2 = predict2[m, ]

cat(dim(test)[1], "rows matched\n")

if (sum(as.character(predict1$href)!=as.character(test$href))) {
  head(predict1)
  head(test)
  stop("sum(as.character(predict1$href)!=as.character(test$href))")
}

if (sum(as.character(predict2$href)!=as.character(test$href))) {
  head(predict2)
  head(test)
  stop("sum(as.character(predict2$href)!=as.character(test$href))")
}


###############################################################################

#keep only columns present in all files:
outputs = intersect(outputs, colnames(predict1))
outputs = intersect(outputs, colnames(predict2))
print(paste("kept output cols =", paste(outputs, collapse = ",")))

###############################################################################

#predict1ion's must be postivie
predict1[predict1<0] = 0
predict2[predict2<0] = 0

###############################################################################

smape = function(predict1ed, test) {
  predict1ed = predict1ed[test!=0]
  test = test[test!=0]
  
  mean( 2 * abs(predict1ed-test)/(abs(predict1ed)+abs(test)) )
} 

###############################################################################

library(hydroGOF)

ixs1 = c()
ixs2 = c()
for (i in 1:dim(test)[1]) {

  errs = c()
  for (col in outputs) {
    err = smape(predict1[i, col], test[i, col])
    errs = c(errs, err)
  }
  err1 = mean(errs[!is.na(errs)])
  
  errs = c()
  for (col in outputs) {
    err = smape(predict2[i, col], test[i, col])
    errs = c(errs, err)
  }
  err2 = mean(errs[!is.na(errs)])  
  

  if (err1<err2) {
    ixs1 = c(ixs1, i)
  } else {
    ixs2 = c(ixs2, i)
  }
}

cat(length(ixs1), "rows where first performs better")
head(test[ixs1,], 20)

cat(length(ixs2), "rows where second performs better")
head(test[ixs2,], 20)
