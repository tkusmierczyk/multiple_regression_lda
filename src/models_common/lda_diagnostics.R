
print("Running JAGS diagnostics.")

pid = paste(format(Sys.time(), "%Y%m%d_%H%M%S"), as.character(Sys.getpid()), sep="_")

## better to store what we have :)
source(file="../models_common/lda_store_samples.R")


##############################

n1 = ifelse(exists("d1"), dim(d1)[1], 0)
n2 = ifelse(exists("d2"), dim(d2)[1], 0)   

##############################

## Try visualizing topics as word clouds
library(wordcloud)

## Take a look at how topics are distinguished
## For each word, show it's association with topics
wordsToClusters = function(samples, words) {
  sampleTW = samples$worddist
  
  colnames(sampleTW) = words
  sTW = summary(sampleTW, FUN = mean)$stat
  sTW[,order(colSums(sTW))]
  t(sweep(sTW,2,colSums(sTW), '/'))
}

path = paste("lda_topics_", pid, ".tsv", sep="")
cat("Word to clusters distribution (",path,")\n")
w2c = wordsToClusters(samples, words)
head(w2c)
write.table(t(w2c), path, sep="\t", row.names = F)

##############################

## Lets assign topics to the documents
## We sample from "topicdist" and pick the topic with highest weight
labelDocuments = function(samples) {
  marginal.weights = summary(samples$topicdist, FUN = mean)$stat
  best.topic = apply(marginal.weights, 1, which.max)
  best.topic
}

path = paste("best_topic_", pid, ".tsv", sep="")
cat("Best document topics assignment (",path,")\n")
ld = labelDocuments(samples)
ld = as.matrix(ld)
colnames(ld) = c("best_topic")
write.table(ld, path, sep="\t", row.names = F)

path = paste("topic2docs_", pid, ".tsv", sep="")
cat("Topic to documents (",path,")\n")
topic2docs = split(documents, labelDocuments(samples))
topic2docs = as.matrix(unlist(lapply(topic2docs, function(v) { paste(as.character(v), collapse=", ") } )))
colnames(topic2docs) = c("topic_docs")
write.table(topic2docs, path, sep="\t", row.names = F)

##############################


## Try visualizing topics as word clouds

genWordCloud = function(sampleTW, words, columnNumber,...) {
  freq = t(summary(sampleTW, FUN = mean)$stat)[,columnNumber]
  wordcloud(words[order(freq)],freq[order(freq)],...)
}


path = paste("topic_clouds_", pid, ".pdf", sep="")
cat("Topic word clouds (",path,")\n")
sampleTW = samples$worddist
colnames(sampleTW) = words
pdf(path, height=K, width=7)
par(mfrow=c(ceiling(K/3),3))
for(i in 1:K)
  genWordCloud(sampleTW, words, i, min.freq = 0.01)
dev.off()


##############################
##############################

library(coda)

monotone <- function(vec) {
  a <- T
  
  if(length(vec) == 1) {
    return(a)
  }
  
  for(i in 2:length(vec)) {
    if(vec[i] > vec[i-1]) {
      a <- F
      break;
    }
  }

  return(a)
}

geyer <- function(vec) {
  g <- c()
  res <- 1
  
  for(i in 1:(length(vec)/2 - 1)) {
    g <- c(g, 
           autocorr(vec, lags = 2*i) + autocorr(vec, lags = 2*i + 1))
    if(monotone(g) == F || g[i] < 0) {
      break
    }
  }
  if(i==1) {
    res <- 1
  }
  else{
    res <- i-1
  }
  return(res)
}


ess <- function(mcmc, M) {
  m <- geyer(mcmc)
  y <- M / (1 + 2 * sum(autocorr(mcmc, lag = 1:(2*m +1))))
  return(y)
}

approx.mode.bak = function(trace) {
  d<-density(trace)
  plot(d)
  i<-which.max(d$y)
  return (trace[i])
}

approx.mode = function(trace, num.breaks=NA) {
  if (is.na(num.breaks)) {
    num.breaks = max(ceiling(length(trace)/30), 10)
  }
  l = min(trace)-0.00001
  r = max(trace)+0.00001
  breaks = l + (r-l)/num.breaks * 1:num.breaks
  breaks = c(l, breaks)
  counts = hist(trace, breaks, plot=F)$counts
  i = which.max(counts)
  left = breaks[i]
  right = breaks[i+1]
  median(trace[trace>left & trace<right])
}

diagnostics = function(trace, label="") {
  mcmc.obj = as.mcmc(trace)
  ess.str = paste("ess=",round(ess(mcmc.obj, n.iter),3), "/", n.iter)
  par(mfrow=c(3,1))
  #plot(trace, type="l")
  traceplot(mcmc.obj, main=paste("trace of", label, "[",ess.str,"]"), auto.layout=F);
  densplot(mcmc.obj, main=paste("density of", label), auto.layout=F); 
  abline(v = median(trace), col="red")
  abline(v = mean(trace), col="blue")
  abline(v = approx.mode(trace), col="green")
  autocorr.plot(mcmc.obj, main=paste("autocorr of", label), auto.layout=F, lag.max=100); 
  #print(label)
  #print(ess.str)
  #print(geweke.diag(mcmc.obj)); 
}


path = paste("lda_diagnostics_", pid, ".pdf", sep="")
cat("Lda trace diagnotics (",path,")\n")
pdf(path)

diagnostics(trace=samples$topicdist[1,1,,1], label="topicdist[doc=1,topic=1]")
diagnostics(trace=samples$topicdist[10,1,,1], label="topicdist[doc=10,topic=1]")

diagnostics(trace=samples$topicdist[1,2,,1], label="topicdist[doc=1,topic=2]")
diagnostics(trace=samples$topicdist[10,2,,1], label="topicdist[doc=10,topic=2]")

diagnostics(trace=samples$topicdist[1,K,,1], label=paste("topicdist[doc=1,topic=K=",K,"]", sep=""))
diagnostics(trace=samples$topicdist[10,K,,1], label=paste("topicdist[doc=10,topic=K=",K,"]", sep=""))


diagnostics(trace=samples$worddist[1,1,,1], label="worddist[topic=1,word=1]")
diagnostics(trace=samples$worddist[1,10,,1], label="worddist[topic=1,word=10]")

diagnostics(trace=samples$worddist[2,1,,1], label="worddist[topic=2,word=1]")
diagnostics(trace=samples$worddist[2,10,,1], label="worddist[topic=2,word=10]")

diagnostics(trace=samples$worddist[K,1,,1], label=paste("worddist[topic=K=",K,",word=1]", sep=""))
diagnostics(trace=samples$worddist[K,10,,1], label=paste("worddist[topic=K=",K,",word=10]", sep=""))

dev.off()



##############################
##############################

