
paste(">>> Selects a subset of rows from the families.")
args = commandArgs(TRUE)

data.path       = ifelse(length(args)>=1, args[[1]],  "../../data/allrecipes.tsv")
families.path   = ifelse(length(args)>=2, args[[2]],  "../../data/allrecipes_family_features.tsv")
family.names    = ifelse(length(args)>=3, args[[3]],  "cake,muffin,cheesecak,sweet_potato,salsa,caramel,burger")
output.path     = ifelse(length(args)>=4, args[[4]], 
                         paste(gsub(".tsv", "", data.path), "_", substr(gsub(",", "_", family.names), 1, 50), ".tsv", sep=""))

family.names = strsplit(family.names, ",")[[1]]

print("Parameters:")
print(paste("data.path =", data.path))
print(paste("families.path =", families.path))
print(paste("family.names =", family.names))
print(paste("output.path =", output.path))

#######################################################################


d1 = read.table(data.path, header=1)
summary(d1)
#d1$src = as.factor("allrecipes")

d2 = read.table(families.path, header=1)
summary(d2)


#######################################################################

selected = rep(FALSE, dim(d2)[1])
for (family.name in family.names) {
  if (family.name %in% names(d2)) {
    family.selected = d2[[family.name]]>0
    selected = selected | family.selected
  } else {
    warning(paste("column <", family.name, "> not in data frame columns"))
  }
}

#######################################################################

d = d1[selected, ]
print(paste("output.path =", output.path))
print(paste("output size =", dim(d)[1]))
write.table(d, output.path, row.names = F, col.names = T, sep="\t")


