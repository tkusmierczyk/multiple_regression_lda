#!/usr/bin/Rscript
print(paste("Starting at", Sys.time()))

library(rjags)
library(plyr)
library(tm)

source(file="../base/config.R")

###############################################################################

args = commandArgs(trailingOnly = TRUE)

train.path = ifelse (length(args)>=1, args[[1]], "../../data/allrecipes.tsv")

outputs = ifelse (length(args)>=2, args[[2]], "kcal,fat,carbohydrates,proteins,sugars,sodium,cholesterol")
outputs = strsplit(outputs, ",")[[1]]

K         = ifelse(length(args)>=3, as.numeric(args[[3]]), 10)
n.iter    = ifelse(length(args)>=4, as.numeric(args[[4]]), 1000)
burn.in   = ifelse(length(args)>=5, as.numeric(args[[5]]), round(n.iter/3))
n.adapt   = ifelse(length(args)>=6, as.numeric(args[[6]]), burn.in)

aggregator   = match.fun(ifelse(length(args)>=7, args[[7]], aggregator))

model.file   = ifelse(length(args)>=8, args[[8]], 'lda_reg.bugs')

###############################################################################

print("Parameters:")
print(paste("[01] train.path =", train.path))
print(paste("[02] outputs =", paste(outputs, collapse=",")))
print(paste("[03] K =", K))
print(paste("[04] n.iter =", n.iter))
print(paste("[05] burn.in =", burn.in))
print(paste("[06] n.adapt =", n.adapt))
print("[07] aggregator ="); print(aggregator)
print(paste("[08] model.file =", model.file)); 

print("-----------------------------------------------------------------------")
###############################################################################

d1 = read.csv(train.path, sep="\t")
print(paste("train dims=", dim(d1)))
head(d1, 2)
head(d1[,outputs], 3)
documents = d1$title

###############################################################################

source("../models_common/lda_tdm.R")

###############################################################################


genLDA = function(lda.data, K = 10, n.adapt = 1000, alpha.Words = 0.1, alpha.Topics = 0.1) {
  mtdm  = lda.data$mtdm
  words = lda.data$words  
  out   = lda.data$out
  
  word = do.call(rbind.fill.matrix,
                 lapply(1:ncol(mtdm), function(i) t(rep(1:length(mtdm[,i]), mtdm[,i]))))
  
  N = ncol(mtdm)                 #Number of documents
  Nwords = length(words)         #Number of terms
  Nouts = dim(out)[2]             #Number of outputs
  alphaTopics = rep(alpha.Topics, K)      #Hyperprior on topics
  alphaWords = rep(alpha.Words, Nwords)  #Hyperprior on words
  
  wordtopic = matrix(NA, nrow(word), ncol(word))
  doclengths = rowSums(!is.na(word))
  topicdist = matrix(NA, N, K)
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
                  worddist = topicwords,
                  out = out,
                  Nouts = Nouts)
  
  cat("using model.file =", model.file, "\n")
  jags = jags.model(model.file,
                    data = dataList, n.adapt=n.adapt)  

  return (jags)
}


print("extracts outputs")
out = d1[,outputs]
head(out)

lda.data = list(mtdm=mtdm, words=words, out=out)
lda.observe = c('worddist', 'topicdist', "intercept", "weight", "tau")
source("../models_common/lda_sampling.R")

###############################################################################

source("../models_common/lda_diagnostics.R")

###############################################################################

print("JAGS Done.")


