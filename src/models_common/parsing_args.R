
source(file="../base/parsing.R")
source(file="../base/config.R")

args = commandArgs(TRUE)


train = ifelse (length(args)>=1, args[[1]], "../../data/train.tsv")
train.features = ifelse (length(args)>=2, args[[2]], "../../data/train_features.tsv")
test = ifelse (length(args)>=3, args[[3]], "../../data/test.tsv")
test.features = ifelse (length(args)>=4, args[[4]], "../../data/test_features.tsv")

prediction.file = ifelse (length(args)>=5, args[[5]], "../../data/prediction.tsv")

#n.trees=1000,shrinkage=0.05,cv.folds=5,interaction.depth=4,n.minobsinnode=5
params = ifelse(length(args)>=6, args[[6]], "")
params = strsplit(params, ";")
train.params = list()
if(length(params[[1]])>0) 
  train.params = parse.list(params[[1]][1])
predict.params  = list()
if (length(params[[1]])>1)
  predict.params = parse.list(params[[1]][2])

if (length(args)>=7) outputs = strsplit(args[[7]], ",")

###############################################################################

print("Parameters:")
print(paste("train =", train))
print(paste("train.features =", train.features))
print(paste("test =", test))
print(paste("test.features =", test.features))

print(paste("prediction.file =", prediction.file))

print(paste("train.params =")); train.params
print(paste("predict.params =")); predict.params

print(paste("output cols =", paste(outputs, collapse = ",")))

print("--------------------------------------------------------------")


