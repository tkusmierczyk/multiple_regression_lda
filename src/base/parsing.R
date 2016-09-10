
parse.list = function(txt="name1=value1,name2=2") {
  l = list()
  ps = strsplit(txt, ",")
  ps = strsplit(ps[[1]], "=")
  for (p in ps) {
    name = p[1]
    value = as.numeric(p[2])
    if (is.na(value)) value = p[2]
    l[[name]] = value
  }
  return (l)
}