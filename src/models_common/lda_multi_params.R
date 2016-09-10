
args = commandArgs(trailingOnly = TRUE)

train.path      = ifelse (length(args)>=1, args[[1]], "../../data/allrecipes.tsv")
test.path       = ifelse (length(args)>=2, args[[2]], train.path)
prediction.file = ifelse (length(args)>=3, args[[3]], "../../data/prediction.tsv")



K         = ifelse(length(args)>=4, as.numeric(args[[4]]), 10)
n.iter    = ifelse(length(args)>=5, as.numeric(args[[5]]), 1000)
burn.in   = ifelse(length(args)>=6, as.numeric(args[[6]]), round(n.iter/3))
n.adapt   = ifelse(length(args)>=7, as.numeric(args[[7]]), burn.in)

aggregator   = match.fun(ifelse(length(args)>=8, args[[8]], aggregator))

outputs = ifelse (length(args)>=9, args[[9]], "kcal,fat,carbohydrates,proteins,sugars,sodium,cholesterol")
outputs = strsplit(outputs, ",")[[1]]

model.file   = ifelse(length(args)>=10, args[[10]], model.file)


###############################################################################

print("Parameters:")
print(paste("[01]. train.path =", train.path))
print(paste("[02]. test.path =", test.path))
print(paste("[03]. prediction.file =", prediction.file))

print(paste("[04]. K =", K))
print(paste("[05]. n.iter =", n.iter))
print(paste("[06]. burn.in =", burn.in))
print(paste("[07]. n.adapt =", n.adapt))

print("[08]. aggregator ="); print(aggregator)
print(paste("[09]. outputs =", paste(outputs, collapse = ",")))
print(paste("[10]. model.file =", model.file)); 

print("-----------------------------------------------------------------------")

