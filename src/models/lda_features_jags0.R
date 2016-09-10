#!/usr/bin/Rscript
print(paste("Starting at", Sys.time()))

library(rjags)
library(plyr)
library(tm)

source(file="../base/config.R")


args = commandArgs(trailingOnly = TRUE)

#DBG
#train.path = "../../data/allrecipes_cake_muffin_cheesecak_sweet_potato_salsa_caramel_burger.tsv"
#test.path = train.path
#train.features.path = "/tmp/train_features.tsv"
#test.features.path = "/tmp/test_features.tsv"

train.path = ifelse (length(args)>=1, args[[1]], "../../data/allrecipes.tsv")
test.path = ifelse (length(args)>=2, args[[2]], train.path)

train.features.path = ifelse (length(args)>=3, args[[3]], paste(train.path, "_lda0_features", sep=""))
test.features.path = ifelse (length(args)>=4, args[[4]], paste(test.path, "_lda0_features", sep=""))

K         = ifelse(length(args)>=5, as.numeric(args[[5]]), 10)
n.iter    = ifelse(length(args)>=6, as.numeric(args[[6]]), 1000)
burn.in   = ifelse(length(args)>=7, as.numeric(args[[7]]), round(n.iter/3))
n.adapt   = ifelse(length(args)>=8, as.numeric(args[[8]]), burn.in)

aggregator   = match.fun(ifelse(length(args)>=9, args[[9]], aggregator))
print("aggregator ="); print(aggregator)


###############################################################################

print("Parameters:")
print(paste("train.path =", train.path))
print(paste("test.path =", test.path))

print(paste("train.features.path =", train.features.path))
print(paste("test.features.path =", test.features.path))

print("Settings:")
print(paste("K =", K))
print(paste("n.iter =", n.iter))
print(paste("burn.in =", burn.in))
print(paste("n.adapt =", n.adapt))

print("-----------------------------------------------------------------------")
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

###############################################################################

d = rbind(d1, d2)
documents = d$title
#documents = documents[1:100]

n1 = dim(d1)[1]
n2 = dim(d2)[1]

###############################################################################

source("../models_common/lda_tdm.R")

###############################################################################


## Take in the term document matrix, words, and number of clusters (K)
## Return a JAGS model, which we'll burn in and sample later
genLDA = function(lda.data, K = 10, n.adapt = 1000, alpha.Words = 0.1, alpha.Topics = 0.1) {
  
  mtdm = lda.data$mtdm
  words = lda.data$words  
  
  ## Here we translate all documents into a numbered matrix, so JAGS can understand it
  ## Each row is a document, it's columns are filled with numbers
  ## Each unique number represents a word in that document
  ## The number of columns is the maximum length of all documents
  ## Unused columns are filled with "NA"
  word = do.call(rbind.fill.matrix,
                  lapply(1:ncol(mtdm), function(i) t(rep(1:length(mtdm[,i]), mtdm[,i]))))
  
  N = ncol(mtdm)                 #Number of documents
  Nwords = length(words)         #Number of terms
  alphaTopics = rep(alpha.Topics, K)      #Hyperprior on topics
  alphaWords = rep(alpha.Words, Nwords)  #Hyperprior on words
  ## These hyperpriors are set such that we can give weights such as (1,0,0) to topics.
  ## If we had 3 topics and used an alpha of (100, 100, 100), we'd
  ## only expect relatively even mixture weights on the
  ## topics. This isn't what we generally want. We'd like documents
  ## to be able to belong to mostly one topic.
  
  ## For each word in a document, we sample a topic
  wordtopic = matrix(NA, nrow(word), ncol(word))
  ## Length of documents needed for indexing in JAGS
  doclengths = rowSums(!is.na(word))
  ## How much we believe each document belongs to each of K topics
  topicdist = matrix(NA, N, K)
  ## How much we believe each word belongs to each of K topics
  topicwords = matrix(NA, K, Nwords)
  
  ## All the parameters to be passed to JAGS
  dataList = list(alphaTopics = alphaTopics,
                   alphaWords = alphaWords,
                   topicdist = topicdist,
                   wordtopic = wordtopic,
                   word = word,
                   Ndocs = N,
                   Ktopics = K,
                   length = doclengths,
                   Nwords = Nwords,
                   worddist = topicwords)
  
  jags = jags.model('lda.bugs',
             data = dataList, n.adapt=n.adapt)
  return (jags)
}


###############################################################################

lda.data = list(mtdm=mtdm, words=words)
lda.observe = c('worddist', 'topicdist')
source("../models_common/lda_sampling.R")

###############################################################################




train.features = samples$topicdist[1:n1, , , 1]
train.features = apply(train.features, c(1,2), aggregator)

if (n2<=0) {
  test.features = data.frame()
} else {
  test.features = samples$topicdist[(n1+1):(n1+n2), , , 1]
  test.features = apply(test.features, c(1,2), aggregator)
}

###############################################################################

if (dim(train.features)[1]>0) {
  print(paste("train.path dims=", dim(train.features)))
  print(paste("train.features.path =", train.features.path))
  write.table(train.features, train.features.path, row.names = F, col.names = T, sep="\t")
}

if (dim(test.features)[1]>0) {
  print(paste("test.path dims=", dim(test.features)))
  print(paste("test.features.path =", test.features.path))
  write.table(test.features, test.features.path, row.names = F, col.names = T, sep="\t")
}

###############################################################################


source("../models_common/lda_diagnostics.R")

# print("JAGS Done.")


 