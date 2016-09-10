#!/usr/bin/Rscript
print(paste("Starting at", Sys.time()))

library(rjags)
library(plyr)
library(tm)

source(file="../base/config.R")


args = commandArgs(trailingOnly = TRUE)

#DBG
#train.path = "../../data/allrecipes_cake_muffin_cheesecak_sweet_potato_salsa_caramel_burger.tsv"

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


train.mtdm = mtdm[, 1:n1]
train.words = rowSums(train.mtdm)
train.words = names(train.words[train.words>0])
train.mtdm = train.mtdm[train.words, ]
cat(length(train.words),"/",length(words)," words in the training set (", dim(train.mtdm)[2], "docs )\n")

test.mtdm = mtdm[, (n1+1):(n1+n2)] 
test.mtdm = test.mtdm[train.words,] #only train words available in test
cat(sum(rowSums(test.mtdm)>0),"/",length(train.words)," ( all =", length(words),") words in the test set (",dim(test.mtdm)[2],"docs )\n")

words = train.words

###############################################################################

#training:
genLDA = function(lda.data, K = 10, n.adapt = 1000, alpha.Words = 0.1, alpha.Topics = 0.1) {
  mtdm = lda.data$mtdm
  words = lda.data$words  
  word = do.call(rbind.fill.matrix, lapply(1:ncol(mtdm), function(i) t(rep(1:length(mtdm[,i]), mtdm[,i]))))
  
  N = ncol(mtdm)                 #Number of documents
  Nwords = length(words)         #Number of terms
  alphaTopics = rep(alpha.Topics, K)      #Hyperprior on topics
  alphaWords = rep(alpha.Words, Nwords)  #Hyperprior on words
  ## For each word in a document, we sample a topic
  wordtopic = matrix(NA, nrow(word), ncol(word))
  ## Length of documents needed for indexing in JAGS
  doclengths = rowSums(!is.na(word))
  ## How much we believe each document belongs to each of K topics
  topicdist = matrix(NA, N, K)
  ## How much we believe each word belongs to each of K topics
  if ("worddist" %in% names(lda.data)) {
    cat("Using infered previously topicwords (worddist)\n")
    topicwords = lda.data$worddist
  } else {
    topicwords = matrix(NA, K, Nwords)
  }
  

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
  
  cat("Loading model from",lda.data$model.path,"\n")
  jags = jags.model(lda.data$model.path,
                    data = dataList, n.adapt=n.adapt)
  return (jags)
}


###############################################################################

cat("Model training...\n")
lda.data = list(model.path="lda.bugs", mtdm=train.mtdm, words=words)
lda.observe = c('worddist', 'topicdist')
source("../models_common/lda_sampling.R")

train.features = samples$topicdist[1:n1, , , 1]
train.features = apply(train.features, c(1,2), aggregator)

source("../models_common/lda_diagnostics.R")

###############################################################################

cat("Infering topics for test...\n")
worddist = apply(samples$worddist[1:K, 1:length(train.words), , 1], c(1,2), aggregator)
lda.data = list(model.path="lda_noworddist.bugs", mtdm=test.mtdm, words=words, worddist=worddist) 
lda.observe = c('topicdist')
source("../models_common/lda_sampling.R")

test.features = samples$topicdist[, , , 1]
test.features = apply(test.features, c(1,2), aggregator)

###############################################################################

pid = paste(format(Sys.time(), "%Y%m%d_%H%M%S"), as.character(Sys.getpid()), sep="_")
path = paste("samples_test_", pid, ".RData", sep="")
cat("Saving test samples to ",path,"\n")
save(samples, file=path)

###############################################################################

path = paste("lda_diagnostics_", pid, "_test.pdf", sep="")
cat("Lda trace diagnotics (",path,")\n")
pdf(path)

diagnostics(trace=samples$topicdist[1,1,,1], label="topicdist[doc=1,topic=1]")
diagnostics(trace=samples$topicdist[10,1,,1], label="topicdist[doc=10,topic=1]")

diagnostics(trace=samples$topicdist[1,2,,1], label="topicdist[doc=1,topic=2]")
diagnostics(trace=samples$topicdist[10,2,,1], label="topicdist[doc=10,topic=2]")

diagnostics(trace=samples$topicdist[1,K,,1], label=paste("topicdist[doc=1,topic=K=",K,"]", sep=""))
diagnostics(trace=samples$topicdist[10,K,,1], label=paste("topicdist[doc=10,topic=K=",K,"]", sep=""))


dev.off()

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



print("JAGS Done.")



