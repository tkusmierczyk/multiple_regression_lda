
source(file="../base/config.R")

paste(">>> Predicts outputs with training set means.")
args = commandArgs(TRUE)

train = ifelse (length(args)>=1, args[[1]], "../../data/train.tsv")
test = ifelse (length(args)>=2, args[[2]], "../../data/test.tsv")
prediction.file = ifelse (length(args)>=3, args[[3]], "../../data/prediction.tsv")

if (length(args)>=4) outputs = strsplit(args[[4]], ",")

print(paste("train =", train))
print(paste("test =", test))
print(paste("prediction.file =", prediction.file))
print(paste("output cols =", paste(outputs, collapse = ",")))


#####################################################################################


train = read.table(train, header=1)
cat(dim(train)[1], "rows loaded from training file\n")

test = read.table(test, header=1)
cat(dim(test)[1], "rows loaded from testing file\n")

#####################################################################################

#keep only these outputs that are also prestend in the training
outputs = intersect(outputs, colnames(train))
print(paste("kept output cols =", paste(outputs, collapse = ",")))

#####################################################################################


#means = colMeans(train[ , sapply(train[1,],is.numeric)])
#means = means[outputs]
means = colMeans(train[ , outputs])
#library(matrixStats)
#means = colMedians(as.matrix(train[ , outputs]))
print(means)

test.size = dim(test)[1]
predicted = rep(means, test.size)
predicted = matrix(predicted, nrow = test.size, byrow = TRUE)
colnames(predicted) = outputs

#####################################################################################

write.table(predicted, prediction.file, sep="\t", row.names = F, col.names = T)
