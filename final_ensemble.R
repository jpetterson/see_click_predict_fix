library(reshape2)
library(doMC)
registerDoMC()
source('subs.R')

labels <- c('num_comments', 'num_views', 'num_votes')

get.ids <- function() {
	load('subs/02.Rd')
	ps[,1]
}

get.sub <- function(id) {
	load(sprintf('subs/%02d.Rd', id))
	log1p(ps[,labels])
}

get.subs <- function(ids, descr=NULL) {
	subs <- foreach(id = ids, .combine=cbind) %dopar% {
		get.sub(id)
	}

	#list(P1 = as.matrix(subs[, seq(1, ncol(subs), 3)]), P2 = as.matrix(subs[, seq(2, ncol(subs), 3)]), P3 = as.matrix(subs[, seq(3, ncol(subs), 3)]))
	P1 <- as.matrix(subs[, seq(1, ncol(subs), 3)])
        P2 <- as.matrix(subs[, seq(2, ncol(subs), 3)])
        P3 <- as.matrix(subs[, seq(3, ncol(subs), 3)])

        colnames(P1) <- descr
        colnames(P2) <- descr
        colnames(P3) <- descr

        list(P1=P1, P2=P2, P3=P3)
}

combine.multiple.models <- function(P1, P2, P3, l.scores, lambda=0) {
	n        <- nrow(P1)
	sum_ysqs <- (0.72238^2)*(3*n) # all zeros benchmark

	P1y1  <- sapply(1:ncol(P1), function(i) (sum_ysqs-(l.scores[1,i]^2)*3*n + sum(P1[,i]^2))/2 )
	P2y2  <- sapply(1:ncol(P2), function(i) (sum_ysqs-(l.scores[2,i]^2)*3*n + sum(P2[,i]^2))/2 )
	P3y3  <- sapply(1:ncol(P3), function(i) (sum_ysqs-(l.scores[3,i]^2)*3*n + sum(P3[,i]^2))/2 )

	k1 <- solve(t(P1) %*% P1 + lambda * diag(ncol(P1))) %*% P1y1
	k2 <- solve(t(P2) %*% P2 + lambda * diag(ncol(P2))) %*% P2y2
	k3 <- solve(t(P3) %*% P3 + lambda * diag(ncol(P3))) %*% P3y3

	best.rmse <- sqrt((sum_ysqs - 2 * (t(k1) %*% P1y1 + t(k2) %*% P2y2 + t(k3) %*% P3y3) + (t(k1) %*% t(P1) %*% P1 %*% k1 + t(k2) %*% t(P2) %*% P2 %*% k2 + t(k3) %*% t(P3) %*% P3 %*% k3))/(3*n))

	list(k1=k1, k2=k2, k3=k3, best.rmse=best.rmse)

}

build.ensemble.sub <- function(subs, m, filename) {
	comb.p           <- cbind(subs$P1 %*% m$k1, subs$P2 %*% m$k2, subs$P3 %*% m$k3)
	colnames(comb.p) <- labels
	comb.p           <- expm1(comb.p)
	comb.p[comb.p<0] <- 0
	comb.p           <- cbind(id = get.ids(), comb.p)
	write.csv(comb.p[,c('id', 'num_views', 'num_votes', 'num_comments')], filename, row.names=F, quote=F)
}

#----------------------------------------------------------------------------------------------------

ids   <- c(1, 2, 3, 4, 5, 8, 12, 13, 14, 15, 17, 19, 21, 22, 24, 25, 27, 28, 29, 30, 35, 36, 37, 38)
descr <- c('1_gbm',
	   '2_gbm',
	   '3_vw',
	   '4_vw',
	   '5_lr_base',
	   '8_gbm_1c',
	   '12_gbm_1c_weights',
	   '13_nn',
	   '14_rf',
	   '15_const',
	   '17_gbm_1c_weights2',
           '19_vw_finetunning',
	   '21_gbm_1c_weights_kmm_sigma_0.01',
	   '22_gbm_1c_weights_kmm_sigma_1.28',
	   '24_gbm_1c_weights3',
	   '25_gbm_only_lat_lon',
	   '27_gbm_richmond',
	   '28_gbm_new_haven',
	   '29_gbm_oakland',
	   '30_gbm_chicago',
           '35_vw_chicago',
           '36_vw_richmond',
           '37_vw_oakland',
           '38_vw_new_haven')

subs <- get.subs(ids, descr)

# for some models we only have results for 'views', so we use the constant submission for 'votes' and 'comments'
subs$P1[,'3_vw'] <- subs$P1[,'15_const']
subs$P3[,'3_vw'] <- subs$P3[,'15_const']

subs$P1[,'35_vw_chicago'] <- subs$P1[,'15_const']
subs$P3[,'35_vw_chicago'] <- subs$P3[,'15_const']

subs$P1[,'36_vw_richmond'] <- subs$P1[,'15_const']
subs$P3[,'36_vw_richmond'] <- subs$P3[,'15_const']

subs$P1[,'37_vw_oakland'] <- subs$P1[,'15_const']
subs$P3[,'37_vw_oakland'] <- subs$P3[,'15_const']

subs$P1[,'38_vw_new_haven'] <- subs$P1[,'15_const']
subs$P3[,'38_vw_new_haven'] <- subs$P3[,'15_const']

# these are the leaderboard scores for the above submissions
l.scores <- cbind(c(0.72090, 0.64733, 0.53406), # 1
		  c(0.72062, 0.59836, 0.53009), # 2
		  c(0.91510, 0.58796, 0.56229), # 3
		  c(0.72403, 0.58825, 0.53069), # 4
		  c(0.72067, 0.60600, 0.53223), # 5
		  c(0.72036, 0.59614, 0.52996), # 8
		  c(0.72041, 0.58846, 0.52963), # 12
		  c(0.72054, 0.60498, 0.53105), # 13
		  c(0.72043, 0.60140, 0.53024), # 14
		  c(0.91510, 0.76162, 0.56229), # 15
		  c(0.72038, 0.59114, 0.52971), # 17
		  c(0.72403, 0.58394, 0.53048), # 19
		  c(0.72035, 0.61134, 0.53031), # 21
		  c(0.72037, 0.61073, 0.53032), # 22
		  c(0.72031, 0.60796, 0.53024), # 24
		  c(0.72122, 0.63486, 0.53556), # 25
		  c(0.72219, 0.69655, 0.68794), # 27
		  c(0.72100, 0.67931, 0.71177), # 28
		  c(0.72187, 0.68401, 0.68805), # 29
		  c(0.72233, 0.71827, 0.62680), # 30
		  c(0.91510, 0.71162, 0.56229), # 35
		  c(0.91510, 0.69858, 0.56229), # 36
		  c(0.91510, 0.70528, 0.56229), # 37
		  c(0.91510, 0.71072, 0.56229)) # 38

m <- combine.multiple.models(subs$P1, subs$P2, subs$P3, l.scores, 1)
build.ensemble.sub(subs, m, 'subs/final.csv')

# ensure num_votes>=1
d    <- read.csv('subs/final.csv')
d$id <- as.integer(d$id)
d$num_votes[d$num_votes<1] <- 1
write.csv(d, 'subs/final.csv', row.names=F, quote=F)

