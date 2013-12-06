source('subs.R')
source('common.R')


#   15
# ----

expn <- 15
load('subs/01.Rd')
ps[,-1] <- expm1(1)
save.subs(ps, expn)

