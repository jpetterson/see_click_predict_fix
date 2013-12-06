library(doMC)
registerDoMC()
source('gbm_common0.R')
source('subs.R')
source('common.R')


#    1
# ----

load('out/data0.Rd')
expn    <- 1
out.dir <- sprintf('out/gbm/%d', expn)
cols    <- c('latitude', 'longitude', 'source', 'has.descr', 'clean.summary', 'clean.tag_type', 'city', 'week')
x.train <- d.train[, cols]
x.valid <- d.valid[, cols]

train.gbms(10000, 1000, c(1, 2, 3, 4, 5, 6, 7, 8, 16, 20), labels, d.train, x.train, out.dir, expn)
r <- test.gbms(out.dir)
save(r, file=sprintf('%s/results1.Rd', out.dir))


# best result for each label
r2 <- foreach(rs = split(r, r$label), .combine=rbind) %do% { rs[which.min(rs$rmse),] }
r2$label <- as.character(r2$label)

# expn      label n.trees depth      rmse
#    1 l_comments    2200     3 0.2059886
#    1    l_views    4800     2 0.5729111
#    1    l_votes    6400    20 0.1474236


# train final models
x.train <- d.trainvalid[, cols]
x.test  <- d.test[, cols]
train.final(out.dir, d.trainvalid, x.train, x.test, expn, r2)

# build submission files
ps <- build.sub(out.dir, expn, r2)
save.subs(ps, expn)

