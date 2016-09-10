#Data preparation for LDA JAGs scripts for code debuging...
print(paste("Starting at", Sys.time()))

library(rjags)
library(plyr)
library(tm)

source(file="../base/config.R")

args = commandArgs(trailingOnly = TRUE)

###############################################################################

train.path = "../../data/allrecipes_cake_muffin_cheesecak_sweet_potato_salsa_caramel_burger.tsv"
test.path = ifelse (length(args)>=2, args[[2]], train.path)
prediction.file = ifelse (length(args)>=3, args[[3]], "../../data/prediction.tsv")
train.features.path = "/tmp/train_features.tsv"
test.features.path = "/tmp/test_features.tsv"
selected.output = ifelse (length(args)>=4, args[[4]], "fat")

K = 3
n.iter = 100
burn.in = 3
n.adapt = 100
aggregator = median


###############################################################################

d1 = read.csv(train.path, sep="\t")
print(paste("train dims=", dim(d1)))
head(d1, 3)

if (test.path==train.path) {
  d2 = data.frame()  
} else {
  d2 = read.csv(test.path, sep="\t")
}
print(paste("test dims=", dim(d2)))
head(d2, 3)


#select only small subset!
d2 = d1[1:500,]
d1 = d1[1:1000,]

d = rbind(d1, d2)
documents = d$title
#documents = documents[1:100]

n1 = dim(d1)[1]
n2 = dim(d2)[1]
