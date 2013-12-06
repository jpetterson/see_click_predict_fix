source('gbm_common.R')
source('subs.R')
source('common.R')


#    2
# ----

load('out/data1.Rd')
source('data_split.R')

expn    <- 2 # was 1 originally
cols    <- c('latitude', 'longitude', 'source', 'has.descr', 'clean.summary', 'clean.tag_type', 'city', 'wday', 'hour')
x.train <- d.train[, cols]
x.valid <- d.valid[, cols]
y.train <- d.train[, labels]
y.valid <- d.valid[, labels]

train.gbms(10000, 1000, c(1, 2, 3, 4, 8, 20), labels, y.train, x.train, expn)


r  <- test.gbms(expn, y.valid)
r2 <- foreach(rs = split(r, r$label), .combine=rbind) %do% { rs[which.min(rs$rmse),] }
save(r, r2, file=sprintf('%s/results1.Rd', out.dir(expn)))
#  expn      label n.trees depth      rmse
#    2 l_comments    2200     3 0.2059995
#    2    l_views    2000    20 0.6080177
#    2    l_votes   10000    20 0.1582544


# train final models
y.train <- d.trainvalid[, labels]
x.train <- d.trainvalid[, cols]
x.test  <- d.test[, cols]
ps      <- train.final(y.train, x.train, x.test, d.test$id, expn, r2)
save.subs(ps, expn)






#    8
# ----

load('out/data1c.Rd')
source('data_split.R')

expn    <- 8
cols    <- c('latitude', 'longitude', 'source', 'has.descr', 'clean.summary', 'clean.tag_type', 'city', 'wday', 'hour', 'summary.nchar', 'description.nchar', 'summary.nword', 'description.nword', 'summary.ncaps', 'summary.nexcl', 'description.ncaps', 'description.nexcl')

x.train <- d.train[, cols]
x.valid <- d.valid[, cols]
y.train <- d.train[, labels]
y.valid <- d.valid[, labels]

train.gbms(10000, 1000, c(1, 2, 3, 4, 8, 20), labels, y.train, x.train, expn)

r  <- test.gbms(expn, y.valid)
r2 <- foreach(rs = split(r, r$label), .combine=rbind) %do% { rs[which.min(rs$rmse),] }
save(r, r2, file=sprintf('%s/results1.Rd', out.dir(expn)))

#  expn      label n.trees depth      rmse
#     8 l_comments    2800     3 0.2043018
#     8    l_views    2000    20 0.6092114
#     8    l_votes   10000    20 0.1565878
 
# train final models
y.train <- d.trainvalid[, labels]
x.train <- d.trainvalid[, cols]
x.test  <- d.test[, cols]
ps      <- train.final(y.train, x.train, x.test, d.test$id, expn, r2)
save.subs(ps, expn)



#   12
# ----

load('out/data1c.Rd')
load('out/w_per_month.Rd')

d.train      <- d[d$month<='2013-03',]
d.valid      <- d[d$month=='2013-04',]
d.trainvalid <- rbind(d.train, d.valid)

w.train      <- w.per.month.valid[d.train$month]
w.trainvalid <- w.per.month.test[d.trainvalid$month]

expn    <- 12
cols    <- c('latitude', 'longitude', 'source', 'has.descr', 'clean.summary', 'clean.tag_type', 'city', 'wday', 'hour', 'summary.nchar', 'description.nchar', 'summary.nword', 'description.nword', 'summary.ncaps', 'summary.nexcl', 'description.ncaps', 'description.nexcl')

x.train <- d.train[, cols]
x.valid <- d.valid[, cols]
y.train <- d.train[, labels]
y.valid <- d.valid[, labels]

train.gbms(10000, 1000, c(1, 2, 3, 4, 8, 20), labels, y.train, x.train, expn, w.train)

r  <- test.gbms(expn, y.valid)
r2 <- foreach(rs = split(r, r$label), .combine=rbind) %do% { rs[which.min(rs$rmse),] }
save(r, r2, file=sprintf('%s/results1.Rd', out.dir(expn)))

# expn      label n.trees depth      rmse
#   12 l_comments    3000     3 0.2041439
#   12    l_views    1800    20 0.5970724
#   12    l_votes   10000    20 0.1557468


# train final models
y.train <- d.trainvalid[, labels]
x.train <- d.trainvalid[, cols]
x.test  <- d.test[, cols]
ps      <- train.final(y.train, x.train, x.test, d.test$id, expn, r2, w.trainvalid)
save.subs(ps, expn)




#   17
# ----

load('out/data1c.Rd')
load('out/w_per_month_v2.Rd')

d.train      <- d[d$month<='2013-03',]
d.valid      <- d[d$month=='2013-04',]
d.trainvalid <- rbind(d.train, d.valid)

w.train      <- w.per.month.valid[d.train$month]
w.trainvalid <- w.per.month.test[d.trainvalid$month]

expn    <- 17
cols    <- c('latitude', 'longitude', 'source', 'has.descr', 'clean.summary', 'clean.tag_type', 'city', 'wday', 'hour', 'summary.nchar', 'description.nchar', 'summary.nword', 'description.nword', 'summary.ncaps', 'summary.nexcl', 'description.ncaps', 'description.nexcl')

x.train <- d.train[, cols]
x.valid <- d.valid[, cols]
y.train <- d.train[, labels]
y.valid <- d.valid[, labels]

train.gbms(10000, 1000, c(1, 2, 3, 4, 8, 20), labels, y.train, x.train, expn, w.train)

r  <- test.gbms(expn, y.valid)
r2 <- foreach(rs = split(r, r$label), .combine=rbind) %do% { rs[which.min(rs$rmse),] }
save(r, r2, file=sprintf('%s/results1.Rd', out.dir(expn)))

# expn      label n.trees depth      rmse
#   17 l_comments    2800     3 0.2047560
#   17    l_views    2200    20 0.6185350
#   17    l_votes   10000    20 0.1552667

# train final models
y.train <- d.trainvalid[, labels]
x.train <- d.trainvalid[, cols]
x.test  <- d.test[, cols]
ps      <- train.final(y.train, x.train, x.test, d.test$id, expn, r2, w.trainvalid)
save.subs(ps, expn)








#   21
# ----

load('out/data1c.Rd')

d.train      <- d[d$month<='2013-03',]
d.valid      <- d[d$month=='2013-04',]
d.trainvalid <- rbind(d.train, d.valid)

load('out/20/w_partsize_1000_sigma_0.010000.Rd')
w.train      <- w

load('out/20/final/w_partsize_1000_sigma_0.010000.Rd')
w.trainvalid <- w


expn    <- 21
cols    <- c('latitude', 'longitude', 'source', 'has.descr', 'clean.summary', 'clean.tag_type', 'city', 'wday', 'hour', 'summary.nchar', 'description.nchar', 'summary.nword', 'description.nword', 'summary.ncaps', 'summary.nexcl', 'description.ncaps', 'description.nexcl')

x.train <- d.train[, cols]
x.valid <- d.valid[, cols]
y.train <- d.train[, labels]
y.valid <- d.valid[, labels]

train.gbms(10000, 1000, c(1, 2, 3, 4, 8, 20), labels, y.train, x.train, expn, w.train)

r  <- test.gbms(expn, y.valid)
r2 <- foreach(rs = split(r, r$label), .combine=rbind) %do% { rs[which.min(rs$rmse),] }
save(r, r2, file=sprintf('%s/results1.Rd', out.dir(expn)))

# train final models
y.train <- d.trainvalid[, labels]
x.train <- d.trainvalid[, cols]
x.test  <- d.test[, cols]
ps      <- train.final(y.train, x.train, x.test, d.test$id, expn, r2, w.trainvalid)
save.subs(ps, expn)

# expn      label n.trees depth      rmse
#   21 l_comments    3200     2 0.2049813
#   21    l_views    2000     2 0.6361030
#   21    l_votes   10000    20 0.1581779




#   22
# ----

load('out/data1c.Rd')

d.train      <- d[d$month<='2013-03',]
d.valid      <- d[d$month=='2013-04',]
d.trainvalid <- rbind(d.train, d.valid)

load('out/20/w_partsize_1000_sigma_1.280000.Rd')
w.train      <- w

load('out/20/final/w_partsize_1000_sigma_1.280000.Rd')
w.trainvalid <- w


expn    <- 22
cols    <- c('latitude', 'longitude', 'source', 'has.descr', 'clean.summary', 'clean.tag_type', 'city', 'wday', 'hour', 'summary.nchar', 'description.nchar', 'summary.nword', 'description.nword', 'summary.ncaps', 'summary.nexcl', 'description.ncaps', 'description.nexcl')

x.train <- d.train[, cols]
x.valid <- d.valid[, cols]
y.train <- d.train[, labels]
y.valid <- d.valid[, labels]

train.gbms(10000, 1000, c(1, 2, 3, 4, 8, 20), labels, y.train, x.train, expn, w.train)

r  <- test.gbms(expn, y.valid)
r2 <- foreach(rs = split(r, r$label), .combine=rbind) %do% { rs[which.min(rs$rmse),] }
save(r, r2, file=sprintf('%s/results1.Rd', out.dir(expn)))

# train final models
y.train <- d.trainvalid[, labels]
x.train <- d.trainvalid[, cols]
x.test  <- d.test[, cols]
ps      <- train.final(y.train, x.train, x.test, d.test$id, expn, r2, w.trainvalid)
save.subs(ps, expn)

# expn      label n.trees depth      rmse
#   22 l_comments    3000     2 0.2054250
#   22    l_views    2000    20 0.6575297
#   22    l_votes   10000    20 0.1592616




#   24
# ----

load('out/data1c.Rd')
expn    <- 24
cols    <- c('latitude', 'longitude', 'source', 'has.descr', 'clean.summary', 'clean.tag_type', 'city', 'wday', 'hour', 'summary.nchar', 'description.nchar', 'summary.nword', 'description.nword', 'summary.ncaps', 'summary.nexcl', 'description.ncaps', 'description.nexcl')

load(sprintf('%s/results1.Rd', out.dir(12))) # reuse previous selection, it doesn't seem to be sensitive to these parameters
load('out/w_per_month_v3.Rd')

# train final models
y.train <- d[, labels]
x.train <- d[, cols]
x.test  <- d.test[, cols]
ps      <- train.final(y.train, x.train, x.test, d.test$id, expn, r2, w)
save.subs(ps, expn)




#   25
# ----

load('out/data1c.Rd')
source('data_split.R')

expn    <- 25
cols    <- c('latitude', 'longitude')

x.train <- d.train[, cols]
x.valid <- d.valid[, cols]
y.train <- d.train[, labels]
y.valid <- d.valid[, labels]

train.gbms(10000, 1000, c(1, 2, 3, 4), labels, y.train, x.train, expn)

r  <- test.gbms(expn, y.valid)
r2 <- foreach(rs = split(r, r$label), .combine=rbind) %do% { rs[which.min(rs$rmse),] }
save(r, r2, file=sprintf('%s/results1.Rd', out.dir(expn)))
#  expn      label n.trees depth      rmse
#    25 l_comments    6000     4 0.2128327
#    25    l_views    2400     4 0.7107416
#    25    l_votes    6000     4 0.2027241


# train final models
y.train <- d.trainvalid[, labels]
x.train <- d.trainvalid[, cols]
x.test  <- d.test[, cols]
ps      <- train.final(y.train, x.train, x.test, d.test$id, expn, r2)
save.subs(ps, expn)






# 27-30: one model for each city
# ------------------------------

load('out/data1c.Rd')
source('data_split.R')

cities <- unique(d$city)
cols   <- c('latitude', 'longitude', 'source', 'has.descr', 'clean.summary', 'clean.tag_type', 'city', 'wday', 'hour', 'summary.nchar', 'description.nchar', 'summary.nword', 'description.nword')

foreach(i = 1:length(cities)) %dopar% {
	city   <- cities[i]
	expn   <- 26+i
	idxs.t <- which(d.train$city==city)
	idxs.v <- which(d.valid$city==city)

	x.train <- d.train[idxs.t, cols]
	y.train <- d.train[idxs.t, labels]

	train.gbms(10000, 1000, c(1, 2, 3, 4, 8, 20), labels, y.train, x.train, expn)
}


for(i in 1:length(cities)) {
	city   <- cities[i]
	expn   <- 26+i
	idxs.t <- which(d.train$city==city)
	idxs.v <- which(d.valid$city==city)

	x.valid <- d.valid[idxs.v, cols]
	y.valid <- d.valid[idxs.v, labels]

	r  <- test.gbms(expn, y.valid)
	r2 <- foreach(rs = split(r, r$label), .combine=rbind) %do% { rs[which.min(rs$rmse),] }
	save(r, r2, file=sprintf('%s/results1.Rd', out.dir(expn)))
}

# train final models
foreach(i = 1:length(cities)) %dopar% {
	city   <- cities[i]
	expn   <- 26+i
	idxs.t <- which(d.trainvalid$city==city)
	idxs.v <- which(d.test$city==city)

	load(sprintf('%s/results1.Rd', out.dir(expn)))
	
	x.train <- d.trainvalid[idxs.t, cols]
	y.train <- d.trainvalid[idxs.t, labels]
	x.test  <- d.test[idxs.v, cols]
	ps      <- train.final(y.train, x.train, x.test, d.test$id[idxs.v], expn, r2)

	# fill other cities' predictions with zeroes
	ps2             <- merge(d.test[, c('id', 'source')], ps, all.x=T)
	ps2$source      <- NULL # source was added because merge requires more than one column
	ps2[is.na(ps2)] <- 0

	idxs <- match(d.test$id, ps2$id)
	ps2  <- ps2[idxs,]

	save.subs(ps2, expn)
}

