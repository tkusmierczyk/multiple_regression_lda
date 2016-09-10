source(file="../base/config.R")
source(file="../base/preprocessing.R")

data.path = "../../data/allrecipes.tsv"

############################################################################################

d1 = read.table(data.path, header=1)
summary(d1)
#d1$src = as.factor("allrecipes")
#d1 = require.columns(d1, outputs)

############################################################################################

#library(SnowballC)
library(tm)

#corpus
corp = Corpus(VectorSource(d1$title))

#building document-word matrix of counts
dtm <- DocumentTermMatrix(corp)
freq.terms <- findFreqTerms(dtm, 10)
inspect(dtm[1:10, freq.terms[1:10]]) #preview matrix

############################################################################################

#count words
count.words = function(dtm, words) {
  counts = c()
  for (word.no in 1:length(freq.terms)) {
    if (word.no %% 100==0) print(paste("count.words:", word.no, "/", length(freq.terms)))
    word = freq.terms[word.no]
    counts = c(counts, sum(as.matrix(dtm[, word])))
  }
  names(counts) = words
  return (counts)
}

word.counts = count.words(dtm, freq.terms)

############################################################################################

library(FNN)
corKL = function(word.signal, signal) { 
  signal.0 = signal[word.signal==0]
  signal.1 = signal[word.signal>0]
  KL.divergence(signal.0, signal.1) 
}

library(entropy)
corKL2 = function(word.signal, signal) {
  signal.0 = as.numeric(signal[word.signal==0])
  signal.1 = as.numeric(signal[word.signal>0])
  2^KL.empirical(signal.0, signal.1, unit="log2")
}

library(FSelector)
corIG = function(word.signal, signal)
    information.gain(signal~word.signal, list(word.signal=word.signal, signal=signal))[[1]]


#select most correlated words
#http://blog.datadive.net/selecting-good-features-part-i-univariate-selection/
calc.correlations = function(dtm, freq.terms, signal, calc.cor=corIG) {
  correlations = c()
  for (word.no in 1:length(freq.terms)) {
    if (word.no %% 100==0) print(paste("correlation:", word.no, "/", length(freq.terms)))
    word = freq.terms[word.no]
    word.signal = c(as.matrix(dtm[, word]))
    correlation = calc.cor(word.signal, signal)
    correlations = c(correlations, correlation)
  }
  names(correlations) = freq.terms
  correlations = correlations[order(abs(correlations), decreasing=T)]
  return (correlations)
}

######################

corr = list()
for (column in outputs) {
  print(paste("Processing", column))
  corr[[column]] = calc.correlations(dtm, freq.terms, d1[[column]])
}
save(corr, file="../../results/analytics/corr.RData")
load("../../results/analytics/corr.RData")

############################################################################################

#topk words per outputs
topk = 5
top = c()
for (column in outputs) {
  cat(column, " & ", paste(names(corr[[column]][1:topk]), sep=", ", collapse=", "), "\\\\ \n")
}

############################################################################################

#calculate how many words in topk are shared between outputs
topk = 100
top = c()
for (column in corr) {
  top = c(top, names(column[1:topk]))
}
cat("num outputs=", length(corr))
top = sort(table(top), decreasing = T)
print(top[1:60])
print(length(top))
print(sum(top>=7))
#cat(round(length(top)/topk*100,2), "% are shared among all the outputs")

############################################################################################

#correlations of word info gains
corr.m = c()
for (column in outputs) {
  column.values = corr[[column]][names(corr[[1]])]
  corr.m = cbind(corr.m, column.values)
}
colnames(corr.m) = outputs

#output corelations
m1 = cor(corr.m, method="spearman")

library(corrplot)
pdf("../../results/analytics/words_corr.pdf",  width=6, height=5.25)
rownames(m1)[rownames(m1)=="carbohydrates"] = "carbo"
colnames(m1)[colnames(m1)=="carbohydrates"] = "carbo"
corrplot(m1, method = "square", tl.col="black", shade.lwd=0, tl.cex=1.8, 
         cl.cex=1.3, cl.offset=0.25, mar = c(0,0,0,0), cl.align.text="l")
dev.off()

############################################################################################
#word usage influence

correlations = corr$fat

print("Are correlaions anyhow influenced by word usage?")
plot(word.counts[names(correlations)], abs(correlations), xlim=c(0,1000), pch="x")
#Test for association between paired samples
cor.test(word.counts[names(correlations)], abs(correlations), method="pearson") #alternative hypothesis: true correlation is not equal to 0
cor.test(word.counts[names(correlations)], abs(correlations), method="spearman")
cor.test(word.counts[names(correlations)], abs(correlations), method="kendall")

############################################################################################
#difference between distributions

library(ggplot2)
library(grid)
library(gridExtra)


plot.word.outputs = function(word, binary=T) {
#  limits = c(1250, 75, 150, 60, 75, 3000, 200)
  limits = c(1000, 60, 150, 40, 75, 1500, 200)
  
  plots = list()
  i = 1
  for (column in outputs) {
    if (binary) {
      d1[["flag"]] =  c(as.matrix(dtm[, word])) > 0 #T/F
      d1[["flag"]][d1[["flag"]]==T] = "y"
      d1[["flag"]][d1[["flag"]]==F] = "n"
      d1[["flag"]] = as.factor(d1[["flag"]])
    } else {
      d1[["flag"]] = as.factor( c(as.matrix(dtm[, word])) ) #word count
    }
    p = ggplot(d1) + 
      geom_density(aes_string(x=column, fill="flag"), color=NA, alpha=0.3, lwd=0)+ 
      coord_cartesian(xlim = c(0, limits[i])) +
      theme_bw() + theme(text = element_text(size=14)) +
      guides(fill=guide_legend(title="used")) + theme(legend.position="none")
    
    plots[[column]] = p
    
    i = i + 1
  }
  dp = as.data.frame( list(x=c(0), y=c(0)) )
  plots[["title"]] = ggplot(dp) + #annotate("text", x = 0, y = 0, label = word, size=8)+
    theme(axis.line=element_blank(),
                                                                                                  axis.text.x=element_blank(),
                                                                                                  axis.text.y=element_blank(),
                                                                                                  axis.ticks=element_blank(),
                                                                                                  axis.title.x=element_blank(),
                                                                                                  axis.title.y=element_blank(),
                                                                                                  legend.position="none",
                                                                                                  panel.background=element_blank(),
                                                                                                  panel.border=element_blank(),
                                                                                                  panel.grid.major=element_blank(),
                                                                                                  panel.grid.minor=element_blank(),
                                                                                                  plot.background=element_blank())
  return(plots)    
}

pdf("../../results/analytics/sample_outputs.pdf",  width=8, height=4.5)
do.call("grid.arrange", c(plot.word.outputs("frost", T), ncol=3))
dev.off()


do.call("grid.arrange", c(plot.word.outputs(7, T), ncol=2))
do.call("grid.arrange", c(plot.word.outputs(freq.terms[7], T), ncol=2))
do.call("grid.arrange", c(plot.word.outputs(names(top[1]), T), ncol=2))
do.call("grid.arrange", c(plot.word.outputs("chicken", T), ncol=2))



#grid.arrange(p[outputs], ncol=length(outputs))

#ggtitle(paste(criterion, "(#recipes containing =", sum(d1[,criterion]>0), ")"))
#coord_cartesian(ylim=c(0, 0.05), xlim=c(0,80))


#criterion = names(correlations)[1]
#d1[,criterion] = c(as.matrix(dtm[, criterion]))
#p2 = ggplot(d1, aes(x=fat, fill = as.factor(d1[,criterion]))) + geom_density(alpha=0.3, lwd=0) + 
#  ggtitle(paste(criterion, "(#recipes containing =", sum(d1[,criterion]>0), ")"))+ 
#  coord_cartesian(ylim=c(0, 0.05), xlim=c(0,80))

#plot5 <- grid.arrange(p1, p2, heights=c(3/4, 1/4), ncol=1, nrow=2)



#criterion = names(correlations)[1500]
#d1[,criterion] = c(as.matrix(dtm[, criterion]))
#ggplot(d1, aes(x=fat, fill = as.factor(d1[,criterion]))) + geom_density(alpha=0.3, lwd=0) + 
#  ggtitle(paste(criterion, "(#recipes containing =", sum(d1[,criterion]>0), ")"))+ 
#  coord_cartesian(ylim=c(0, 0.05), xlim=c(0,80))



