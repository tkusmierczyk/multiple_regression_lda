
paste(">>> Filters nutrients data read from TSV file.")
args = commandArgs(TRUE)

#input.path = "../../data/raw/kochbar.tsv"
input.path  = ifelse (length(args)>=1, args[[1]],  "../../data/allrecipes.tsv")
output.path  = ifelse (length(args)>=2, args[[2]], input.path)

print("Parameters:")
print(paste("input.path =", input.path))
print(paste("output.path =", output.path))

#######################################################################

d = read.table(input.path, sep="\t", header=T, na.strings=c("NA", "NULL", "?"))


#replaces values>max with NAs
filter.values = function (d, col.name, max) {
  if (!(col.name %in% names(d))) {
    return (d)
  }
  d[[col.name]][ d[[col.name]]>max ] = NA
  return (d)
}

d = filter.values(d, "kcal", 2500)
d = filter.values(d, "fat", 150)
d = filter.values(d, "cholesterol", 500)
d = filter.values(d, "carbohydrates", 350)
d = filter.values(d, "proteins", 150)
d = filter.values(d, "sugars", 150)
d = filter.values(d, "sodium", 6000)


#################################################


d = d[complete.cases(d), ]
print(paste("output size =", dim(d)[1]))
write.table(d, output.path, row.names = F, col.names = T, sep="\t")
