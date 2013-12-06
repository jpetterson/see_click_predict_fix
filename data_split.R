d.train      <- d[d$month>='2012-10' & d$month<='2013-03',]
d.valid      <- d[d$month=='2013-04',]
d.trainvalid <- rbind(d.train, d.valid)

