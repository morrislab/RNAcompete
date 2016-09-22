
args <- commandArgs(TRUE)

infile <- args[1]
outfile <- args[2]

print(infile)
print(outfile)

library(ggplot2)

df<-read.table(infile,header=T)

png(filename = outfile, width = 320, height = 320)
ggplot(df, aes(setA, setB)) + geom_point() + theme(axis.title.x = element_text(size=16), axis.title.y = element_text(size=16))
dev.off()
