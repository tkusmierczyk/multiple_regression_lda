
require.columns = function(d, columns) {
  for (c in setdiff(columns, colnames(d))) {
    d[,c] = NA
  }
  return (d)
}
