#!/usr/bin/Rscript
args <- commandArgs(TRUE)
infile <- args[1]
data<-read.table(infile,sep="\t")
pearson_correlation<-cor(data[,1],data[,2],use="pairwise.complete.obs")
print(pearson_correlation)