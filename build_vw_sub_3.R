source('subs.R')

load('subs/02.Rd')
p               <- read.table('out/3/final/prediction_views')$V1
ps$num_views    <- expm1(p) 
ps$num_votes    <- 0
ps$num_comments <- 0
save.subs(ps, 3)


