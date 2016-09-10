source(file="../base/config.R")
source(file="../base/preprocessing.R")


d1 = read.table("../../data/allrecipes.tsv", header=1)
summary(d1)
d1$src = as.factor("allrecipes")
d1 = require.columns(d1, outputs)

d2 = read.table("../../data/kochbar.tsv", header=1)
summary(d2)
d2$src = as.factor("kochbar")
d2 = require.columns(d2, outputs)

#######################################################################################################################


word.stats = function(titles) {
  titles = as.character(titles)
  titles = strsplit(titles, " ")
  words = unlist(titles)
  w2c = table(words)
  hist(w2c, breaks=length(w2c), xlim=c(0, 100))
  w2c = w2c[order(w2c)]
  cat(length(w2c),"words\n")
  print(tail(w2c, 10))
  print(head(w2c, 10))
  return (w2c)
}

w2c = word.stats(d1$title)
w2c = word.stats(d2$title)


#######################################################################################################################
library(ggplot2)


ggplot(d1, aes(x = d1[["kcal"]])) + geom_histogram(binwidth=10) + coord_cartesian(xlim=c(0,2500))
ggplot(d1, aes(x = d1[["fat"]])) + geom_histogram(binwidth=1) + coord_cartesian(xlim=c(0,150))
ggplot(d1, aes(x = d1[["cholesterol"]])) + geom_histogram(binwidth=3) + coord_cartesian(xlim=c(0,500))
ggplot(d1, aes(x = d1[["carbohydrates"]])) + geom_histogram(binwidth=2) + coord_cartesian(xlim=c(0,350))
ggplot(d1, aes(x = d1[["proteins"]])) + geom_histogram(binwidth=1) + coord_cartesian(xlim=c(0,150))
ggplot(d1, aes(x = d1[["sugars"]])) + geom_histogram(binwidth=1) + coord_cartesian(xlim=c(0,150))
ggplot(d1, aes(x = d1[["sodium"]])) + geom_histogram(binwidth=20) + coord_cartesian(xlim=c(0,6000))



plot(d1[["fat"]], d1[["proteins"]])
ggplot(d1, aes(x = kcal, y = fat)) + geom_point(size=0.1) + 
  geom_smooth(method=lm) + coord_cartesian(xlim=c(0,1000), ylim=c(0,100))

ggplot(d1, aes(x = cholesterol, y = fat)) + geom_point(size=0.5) + 
  geom_smooth(method=lm) + coord_cartesian(xlim=c(0,500), ylim=c(0,100))

#######################################################################################################################


#output corelations
m1 = cor(d1[outputs], method="pearson")
m2 = cor(d2[outputs], method="pearson")
m2[is.na(m2)] = 0

library(corrplot)

par(mfrow=c(1,2))
corrplot(m1, method = "square", tl.col="black", shade.lwd=0, main="allrecipes")
corrplot(m2, method = "square", tl.col="black", shade.lwd=0, main="kochbar")

pdf("../../results/analytics/outputs_corr.pdf",  width=6, height=5.25)
rownames(m1)[rownames(m1)=="carbohydrates"] = "carbo"
colnames(m1)[colnames(m1)=="carbohydrates"] = "carbo"
corrplot(m1, method = "square", tl.col="black", shade.lwd=0, tl.cex=1.8, 
         cl.cex=1.3, cl.offset=0.25, mar = c(0,0,0,0), cl.align.text="l")
dev.off()


#######################################################################################################################

shared.cols = intersect(colnames(d1), colnames(d2))
d = rbind(d1[,shared.cols], d2[,shared.cols])

dev.off()
ggplot(d, aes(x = fat, fill = src)) + geom_density(alpha=0.3, lwd=0) 
ggplot(d, aes(x = carbohydrates, fill = src)) + geom_density(alpha=0.3, lwd=0) 
ggplot(d, aes(x = proteins, fill = src)) + geom_density(alpha=0.3, lwd=0) 
ggplot(d, aes(x = kcal, fill = src)) + geom_density(alpha=0.3, lwd=0) 

#+ ggtitle(criterion)+ coord_cartesian(ylim=c(0, 0.05)) #+ facet_grid(country ~ .)

