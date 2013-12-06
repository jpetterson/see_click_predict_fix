library(doMC)
registerDoMC()

# read word to vector mappings
v           <- read.table('out/word2vec/vectors.txt', skip=1, stringsAsFactors=F)
names(v)    <- c('word', sprintf('v%d', 1:(ncol(v)-1)))
rownames(v) <- v$word

# read descriptions
desc <- readLines('out/word2vec/descriptions.txt')

dvec <- foreach (i = 1:length(desc), .combine=rbind) %dopar% {
	colMeans(v[strsplit(desc[i], ' ')[[1]], -1], na.rm=T)
}
save(dvec, file='out/word2vec/descriptions_vec.Rd')



load(file='out/data1.Rd')
n1 <- nrow(d)
n2 <- nrow(d.test)

d$description      <- desc[1:n1]
d.test$description <- desc[(n1+1):(n1+n2)]

d      <- cbind(d, dvec[1:n1,])
d.test <- cbind(d.test, dvec[(n1+1):(n1+n2),])

save(d, d.test, file='out/data2.Rd')

