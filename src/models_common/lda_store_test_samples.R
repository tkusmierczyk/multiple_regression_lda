
pid = paste(format(Sys.time(), "%Y%m%d_%H%M%S"), as.character(Sys.getpid()), sep="_")
path = paste("samples_test_", pid, ".RData", sep="")
cat("Saving test samples to ",path,"\n")
save(samples, file=path)
