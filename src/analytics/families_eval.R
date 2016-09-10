source(file="../base/config.R")
source(file="../base/preprocessing.R")


d1 = read.table("../../data/allrecipes.tsv", header=1)
summary(d1)
#d1$src = as.factor("allrecipes")

d2 = read.table("../../data/allrecipes_family_features.tsv", header=1)
drop.features.columns = c("href")
d2 = d2[ , !(names(d2) %in% drop.features.columns)]
summary(d2)

#######################################################################

d3 = d2
d3[d3>0] = 1 #binarized
summary(d3)

#######################################################################

print("Families use stats")
families_use = colSums(d3)
summary(families_use)
hist(families_use, xlim=c(0,20), breaks=max(families_use)*2)

ordered = names(families_use)[order(families_use, decreasing=T)]
print("Most popular families")
head(ordered, 20)
print("Least popular families")
tail(ordered, 20)


#######################################################################


library(ggplot2)
library(grid)
library(gridExtra)



# d1 - contains otputs, d3 - contains families data
plot.family.outputs = function(d1, d3, family) {
  plots = list()
  for (column in outputs) {

    d = as.data.frame( cbind( d1[[column]], d3[[family]] ) )
    colnames(d) = c(column, family)
    family.d = d[d[[family]]>0, ]
    family.d[[family]] = as.factor(family)
    d[[family]] = as.factor("all") 
    d = rbind(d, family.d)
    
    p = ggplot(d, aes_string(x=column, fill=family)) +  geom_density(alpha=0.3, lwd=0)
    plots[[column]] = p
  }
  dp = as.data.frame( list(x=c(0), y=c(0)) )
  plots[["title"]] = ggplot(dp)+annotate("text", x = 0, y = 0, label = family,size=20)+
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

do.call("grid.arrange", c(plot.family.outputs(d1, d3, "muffin"), ncol=2))
do.call("grid.arrange", c(plot.family.outputs(d1, d3, ordered[1]), ncol=2))
do.call("grid.arrange", c(plot.family.outputs(d1, d3, ordered[2]), ncol=2))
do.call("grid.arrange", c(plot.family.outputs(d1, d3, ordered[3]), ncol=2))


do.call("grid.arrange", c(plot.family.outputs(d1, d3, ordered[2000]), ncol=2))
do.call("grid.arrange", c(plot.family.outputs(d1, d3, ordered[2001]), ncol=2))

