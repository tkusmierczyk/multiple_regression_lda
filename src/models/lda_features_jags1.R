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

selected.output = ifelse (length(args)>=5, args[[5]], "fat")


K         = ifelse(length(args)>=6, as.numeric(args[[6]]), 10)
n.iter    = ifelse(length(args)>=7, as.numeric(args[[7]]), 1000)
burn.in   = ifelse(length(args)>=8, as.numeric(args[[8]]), round(n.iter/3))
n.adapt   = ifelse(length(args)>=9, as.numeric(args[[9]]), burn.in)


aggregator   = match.fun(ifelse(length(args)>=10, args[[10]], aggregator))
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

#print(paste("outputs =", outputs))
print(paste("selected.output =", selected.output))

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


genLDA = function(lda.data, K = 10, n.adapt = 1000, alpha.Words = 0.1, alpha.Topics = 0.1) {
  
  mtdm  = lda.data$mtdm
  words = lda.data$words  
  out  = lda.data$out
  
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
  
  jags = jags.model('lda_reg1.bugs',
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


lda.data = list(mtdm=mtdm, words=words, out = out)
lda.observe = c('worddist', 'topicdist', 'intercept', 'weight', "sd")
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


path = paste("lda_diagnostics_", pid, "_2.pdf", sep="")
cat("Lda trace diagnotics 2 (",path,")\n")
pdf(path)
diagnostics(trace=samples$intercept[1,,1], label="intercept")
for (i in 1:K) {
  diagnostics(trace=samples$weight[i,,1], label=paste("weight[topic=",i,"]", sep=""))
}
dev.off()


print("JAGS Done.")


