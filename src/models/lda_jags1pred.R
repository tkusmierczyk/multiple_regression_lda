#!/usr/bin/Rscript
print(paste("Starting at", Sys.time()))

library(rjags)
library(plyr)
library(tm)

model.file = "lda_reg1.bugs"
source(file="../base/config.R")
source(file="../models_common/lda_single_params.R")
source(file="../models_common/lda_load_train_test.R")
source(file="../models_common/lda_tdm.R")

###############################################################################


genLDA = function(lda.data, K = 10, n.adapt = 1000, alpha.Words = 0.1, alpha.Topics = 0.1) {
  mtdm  = lda.data$mtdm
  words = lda.data$words  
  out   = lda.data$out
  
  word = do.call(rbind.fill.matrix,
                 lapply(1:ncol(mtdm), function(i) t(rep(1:length(mtdm[,i]), mtdm[,i]))))
  
  N = ncol(mtdm)                 #Number of documents
  Nwords = length(words)         #Number of terms
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
                  out = out)
  
  cat("using model.file =", model.file, "\n")
  jags = jags.model(model.file,
                    data = dataList, n.adapt=n.adapt)
  return (jags)
}

###########################


print("extracts output")
out = d[,selected.output] # 

print("NA for tests")
if (n2>0) {
  out[(n1+1):(n1+n2)] = NA
}

#print("znorm over output")
#m = mean(out[!is.na(out)])
#s = sd(out[!is.na(out)])
#out = (out-m)/s #znorm


lda.data = list(mtdm=mtdm, words=words, out=out)
lda.observe = c('worddist', 'topicdist', 'intercept', 'weight', "out", "tau")
source("../models_common/lda_sampling.R")

###############################################################################

predicted.train.out = apply(samples$out[(1):(n1), , 1], c(1), aggregator)

predicted.out = samples$out[(n1+1):(n1+n2),  , 1]
predicted.out = as.data.frame(apply(predicted.out, c(1), aggregator))
colnames(predicted.out) = c(selected.output)
predicted.out$href = d2$href

###############################################################################


source("../models_common/lda_diagnostics.R")
source("../models_common/lda_diagnostics_weights1.R")

###############################################################################


cat("Writing to",prediction.file,"\n")
write.table(predicted.out, prediction.file, sep="\t", row.names = F, col.names = T)

###############################################################################

print("JAGS Done.")


