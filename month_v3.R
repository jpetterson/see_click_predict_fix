library(doMC)
registerDoMC()
source('common.R')
source('gbm_common.R')

expn <- 23
load('out/data1e.Rd')
system(sprintf('mkdir -p %s', out.dir(expn)))


# split the training set in two
set.seed(1)
idxs1    <- sort(sample(nrow(d), 0.5*nrow(d)))
idxs2    <- setdiff(1:nrow(d), idxs1)

# 1. train with training_set_split_1 + test set 
# 2. compute predictions for training_set_split_2
# 3. train with training_set_split_2 + test set 
# 4. compute predictions for training_set_split_1

cols          <- c('istest', 'latitude', 'longitude', 'source', 'has.descr', 'clean.summary2', 'clean.tag_type', 'city', 'wday', 'hour', 'summary.nchar', 'description.nchar', 'summary.nword', 'description.nword', 'summary.ncaps', 'summary.nexcl', 'description.ncaps', 'description.nexcl')
d$istest      <- 0
d.test$istest <- 1

d.train1 <- rbind(d[idxs1, cols], d.test[, cols])
d.train2 <- rbind(d[idxs2, cols], d.test[, cols])

set.seed(2)
idxs     <- sample(nrow(d.train1))
d.train1 <- d.train1[idxs,]
idxs     <- sample(nrow(d.train2))
d.train2 <- d.train2[idxs,]
rm(idxs)

y.train1 <- d.train1$istest
y.train2 <- d.train2$istest

d.train1$istest <- NULL
d.train2$istest <- NULL

save(idxs1, idxs2, file=sprintf('%s/idxs.Rd', out.dir(expn)))

foreach(i = 1:2) %dopar% {
	if (i==1) {
		model1 <- gbm.fit(d.train1, y.train1, distribution='bernoulli', n.trees=10000, interaction.depth=20, verbose=T)
		save(model1, file=sprintf('%s/model1.Rd', out.dir(expn)))
	} else {
		model2 <- gbm.fit(d.train2, y.train2, distribution='bernoulli', n.trees=10000, interaction.depth=20, verbose=T)
		save(model2, file=sprintf('%s/model2.Rd', out.dir(expn)))
	}
}

load(sprintf('%s/model1.Rd', out.dir(expn)))
load(sprintf('%s/model2.Rd', out.dir(expn)))
cols <- c('latitude', 'longitude', 'source', 'has.descr', 'clean.summary2', 'clean.tag_type', 'city', 'wday', 'hour', 'summary.nchar', 'description.nchar', 'summary.nword', 'description.nword', 'summary.ncaps', 'summary.nexcl', 'description.ncaps', 'description.nexcl')
p2   <- predict(model1, d[idxs2, cols], n.trees=10000)
p1   <- predict(model2, d[idxs1, cols], n.trees=10000)

p        <- rep(NA, nrow(d))
p[idxs1] <- p1
p[idxs2] <- p2

# convert to probabilities
w <- 1/(1+exp(-p))

save(w, file = 'out/w_per_month_v3.Rd')


