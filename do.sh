# Initial preprocessing
# =====================

# this code has a bug and was superseed by preprocess.R below; I'm keeping it here, however, as the resulting models where
# used in the ensemble (file gbm0.R below); this file produces the dataset 'd0'
R --vanilla < preprocess0.R 

# fixed preprocessing code (produces the datasets d1, d1b, d1c, d1d and d1e) 
R --vanilla < preprocess.R

# build a model to predict from which month the data is, as a way of reweighing training set instances
R --vanilla < month.R

# second iteration of month.R:
# - it seems the model in month.R is heavily biased by the frequencies of instances in each month
# - so we'll do it again, but this time reweighting the instances to compensate for that
R --vanilla < month_v2.R

# third iteration of month.R:
# - build a model to predict whether the instance is from the training or the test set
R --vanilla < month_v3.R

# KMM ("Correcting Sample Selection Bias by Unlabeled Data", NIPS 2006)
R --vanilla < kmm.R


# Word2vec
# ========

# save descriptions (after removing punctuation) to a text file
R --vanilla < preprocess_for_word2vec.R

# generate a feature vector for each word using word2vec 
word2vec -train out/word2vec/descriptions.txt -output out/word2vec/vectors.txt -cbow 0 -size 200 -window 5 -negative 0 -hs 1 -sample 1e-3 -threads 12

# combine these word feature vectors to produce one feature vector per instance (produces dataset d2)
R --vanilla < preprocess_with_word2vec.R





# GBMs
# ====

# this code uses the 'd0' dataset, which had a bug; it was superseeded by gbm.R below, but I'm keeping the code as the resuling mode
# was part of the final ensemble
R --vanilla < gbm0.R 


# this code produces all remaining GBM based models
R --vanilla < gbm.R




# vowpal wabbit
# =============

# reformat files for vowpal wabbit
R --vanilla < preprocess_for_vw.R

# and split files by city 
ruby split_by_city.rb


# hyperparameter selection for vowpal wabbit was not completely automated,
# so we are going to list only the final parameters 

# 3
vw -d out/vw/views_trainvalid.vw --l1 1.0e-04 -c --loss_function squared --random_seed 0 --keep c --keep m    -f out/3/final/model_views --readable_model out/3/final/model_views.txt --passes 99 --save_per_pass
vw -d out/vw/views_test.vw       --l1 1.0e-04 -c --loss_function squared --random_seed 0 --keep c --keep m -t -i out/3/final/model_views -p out/3/final/prediction_views
R --vanilla < build_vw_sub_3.R

# 4 (L1 regularisation)
vw -d out/vw/votes_trainvalid.vw    --l1 1.0e-06 -c --loss_function squared --random_seed 0 --keep c --keep m --keep t --keep d --keep w  -f out/4/model.featureset_cmtdw_final_true_l1_1.0e-06_model_votes_numpasses_209_ --readable_model out/4/model.featureset_cmtdw_final_true_l1_1.0e-06_model_votes_numpasses_209_.txt --passes 209; vw -d out/vw/votes_test.vw    --l1 1.0e-06 -c --loss_function squared --random_seed 0 --keep c --keep m --keep t --keep d --keep w  -t -i out/4/model.featureset_cmtdw_final_true_l1_1.0e-06_model_votes_numpasses_209_ -p out/4/predictions.featureset_cmtdw_final_true_l1_1.0e-06_model_votes_numpasses_209_
vw -d out/vw/comments_trainvalid.vw --l1 0.0001  -c --loss_function squared --random_seed 0 --keep c --keep m --keep t --keep d           -f out/4/model.featureset_cmtd_final_true_l1_0.0001_model_comments_numpasses_0_  --readable_model out/4/model.featureset_cmtd_final_true_l1_0.0001_model_comments_numpasses_0_.txt  --passes 0  ; vw -d out/vw/comments_test.vw --l1 0.0001  -c --loss_function squared --random_seed 0 --keep c --keep m --keep t --keep d           -t -i out/4/model.featureset_cmtd_final_true_l1_0.0001_model_comments_numpasses_0_  -p out/4/predictions.featureset_cmtd_final_true_l1_0.0001_model_comments_numpasses_0_
vw -d out/vw/views_trainvalid.vw    --l1 0.0001  -c --loss_function squared --random_seed 0 --keep c --keep m                             -f out/4/model.featureset_cm_final_true_l1_0.0001_model_views_numpasses_109_     --readable_model out/4/model.featureset_cm_final_true_l1_0.0001_model_views_numpasses_109_.txt     --passes 109; vw -d out/vw/views_test.vw    --l1 0.0001  -c --loss_function squared --random_seed 0 --keep c --keep m                             -t -i out/4/model.featureset_cm_final_true_l1_0.0001_model_views_numpasses_109_     -p out/4/predictions.featureset_cm_final_true_l1_0.0001_model_views_numpasses_109_
R --vanilla < build_vw_sub_4.R


# 19 (L1 regularisation, different learning rates
vw -d out/vw/votes_trainvalid.vw    --l1 1.0e-06 --learning_rate 0.125 -c --loss_function squared --random_seed 0 --keep c --keep m --keep d           -f out/19/model.featureset_cmd_final_true_l1_1.0e-06_lr_0.125_model_votes_numpasses_1_   --readable_model out/19/model.featureset_cmd_final_true_l1_1.0e-06_lr_0.125_model_votes_numpasses_1_.txt   --passes 1  ; vw -d out/vw/votes_test.vw    --l1 1.0e-06 --learning_rate 0.125 -c --loss_function squared --random_seed 0 --keep c --keep m --keep d           -t -i out/19/model.featureset_cmd_final_true_l1_1.0e-06_lr_0.125_model_votes_numpasses_1_   -p out/19/predictions.featureset_cmd_final_true_l1_1.0e-06_lr_0.125_model_votes_numpasses_1_ 
vw -d out/vw/views_trainvalid.vw    --l1 0.0     --learning_rate 0.125 -c --loss_function squared --random_seed 0 --keep c --keep m --keep t --keep w  -f out/19/model.featureset_cmtw_final_true_l1_0.0_lr_0.125_model_views_numpasses_999_    --readable_model out/19/model.featureset_cmtw_final_true_l1_0.0_lr_0.125_model_views_numpasses_999_.txt    --passes 999; vw -d out/vw/views_test.vw    --l1 0.0     --learning_rate 0.125 -c --loss_function squared --random_seed 0 --keep c --keep m --keep t --keep w  -t -i out/19/model.featureset_cmtw_final_true_l1_0.0_lr_0.125_model_views_numpasses_999_    -p out/19/predictions.featureset_cmtw_final_true_l1_0.0_lr_0.125_model_views_numpasses_999_
vw -d out/vw/comments_trainvalid.vw --l1 0.0001  --learning_rate 0.35  -c --loss_function squared --random_seed 0 --keep c --keep m --keep t --keep d  -f out/19/model.featureset_cmtd_final_true_l1_0.0001_lr_0.35_model_comments_numpasses_0_ --readable_model out/19/model.featureset_cmtd_final_true_l1_0.0001_lr_0.35_model_comments_numpasses_0_.txt --passes 0  ; vw -d out/vw/comments_test.vw --l1 0.0001  --learning_rate 0.35  -c --loss_function squared --random_seed 0 --keep c --keep m --keep t --keep d  -t -i out/19/model.featureset_cmtd_final_true_l1_0.0001_lr_0.35_model_comments_numpasses_0_ -p out/19/predictions.featureset_cmtd_final_true_l1_0.0001_lr_0.35_model_comments_numpasses_0_
R --vanilla < build_vw_sub_19.R


# 35-38 (L1 regularisation, different learning rates, one model per city)
vw -d out/vw/views_trainvalid_chicago.vw   --l1 1.0e-05 --learning_rate 0.03125      -c --loss_function squared --random_seed 0 --keep m  -f out/35/model.city_chicago_featureset_m_final_true_l1_1.0e-05_lr_0.03125_model_views_numpasses_0_        --readable_model out/35/model.city_chicago_featureset_m_final_true_l1_1.0e-05_lr_0.03125_model_views_numpasses_0_.txt        --passes 0; vw -d out/vw/views_test_chicago.vw   --l1 1.0e-05 --learning_rate 0.03125      -c --loss_function squared --random_seed 0 --keep m  -t -i out/35/model.city_chicago_featureset_m_final_true_l1_1.0e-05_lr_0.03125_model_views_numpasses_0_        -p out/35/predictions.city_chicago_featureset_m_final_true_l1_1.0e-05_lr_0.03125_model_views_numpasses_0_
vw -d out/vw/views_trainvalid_new_haven.vw --l1 1.0e-05 --learning_rate 0.0009765625 -c --loss_function squared --random_seed 0 --keep m  -f out/35/model.city_new_haven_featureset_m_final_true_l1_1.0e-05_lr_0.0009765625_model_views_numpasses_3_ --readable_model out/35/model.city_new_haven_featureset_m_final_true_l1_1.0e-05_lr_0.0009765625_model_views_numpasses_3_.txt --passes 3; vw -d out/vw/views_test_new_haven.vw --l1 1.0e-05 --learning_rate 0.0009765625 -c --loss_function squared --random_seed 0 --keep m  -t -i out/35/model.city_new_haven_featureset_m_final_true_l1_1.0e-05_lr_0.0009765625_model_views_numpasses_3_ -p out/35/predictions.city_new_haven_featureset_m_final_true_l1_1.0e-05_lr_0.0009765625_model_views_numpasses_3_
vw -d out/vw/views_trainvalid_oakland.vw   --l1 1.0e-05 --learning_rate 0.0009765625 -c --loss_function squared --random_seed 0 --keep m  -f out/35/model.city_oakland_featureset_m_final_true_l1_1.0e-05_lr_0.0009765625_model_views_numpasses_3_   --readable_model out/35/model.city_oakland_featureset_m_final_true_l1_1.0e-05_lr_0.0009765625_model_views_numpasses_3_.txt   --passes 3; vw -d out/vw/views_test_oakland.vw   --l1 1.0e-05 --learning_rate 0.0009765625 -c --loss_function squared --random_seed 0 --keep m  -t -i out/35/model.city_oakland_featureset_m_final_true_l1_1.0e-05_lr_0.0009765625_model_views_numpasses_3_   -p out/35/predictions.city_oakland_featureset_m_final_true_l1_1.0e-05_lr_0.0009765625_model_views_numpasses_3_
vw -d out/vw/views_trainvalid_richmond.vw  --l1 0.0001  --learning_rate 0.0009765625 -c --loss_function squared --random_seed 0 --keep m  -f out/35/model.city_richmond_featureset_m_final_true_l1_0.0001_lr_0.0009765625_model_views_numpasses_2_   --readable_model out/35/model.city_richmond_featureset_m_final_true_l1_0.0001_lr_0.0009765625_model_views_numpasses_2_.txt   --passes 2; vw -d out/vw/views_test_richmond.vw  --l1 0.0001  --learning_rate 0.0009765625 -c --loss_function squared --random_seed 0 --keep m  -t -i out/35/model.city_richmond_featureset_m_final_true_l1_0.0001_lr_0.0009765625_model_views_numpasses_2_   -p out/35/predictions.city_richmond_featureset_m_final_true_l1_0.0001_lr_0.0009765625_model_views_numpasses_2_
R --vanilla < build_vw_sub_35.R




# linear regression
# =================

R --vanilla < preprocess_for_linear.R # produces datasets d3 and d4
R --vanilla < linear.R


# neural networks
# ===============

R --vanilla < nn.R


# random forests
# ==============

R --vanilla < rf.R


# submission of a constant
# ========================

R --vanilla < constants.R


# final ensemble
# ==============

R --vanilla < final_ensemble.R

