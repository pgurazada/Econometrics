#' ---
#' title: "Econometrics by example"
#' author: Pavan Gurazada
#' output: github_document
#' ---
#' last update: Fri Mar 09 10:50:26 2018

library(foreign)
library(tidyverse)
library(caret)
library(boot)
library(lme4)

set.seed(20130810)
theme_set(theme_minimal())

#' Though heavily biased towards Linear Regression, Econometrics deals with
#' specifying the regression problems rooted on economic theory. The regression
#' coefficient estimates and the sign of these estimates are derived from
#' theoretical considerations. This is a unique playground and several
#' interesting examples of economic problems are presented in this book, which
#' we intend to replicate in R

#' *Example 1*

cps_df <- read.dta("data/gujrati-example/Stata/Table1_1.dta")
glimpse(cps_df)

tr_rows <- createDataPartition(cps_df$wage, p = 0.8, list = FALSE)
train_cps <- cps_df[tr_rows, ]
test_cps <- cps_df[-tr_rows, ]

lm_cps <- train(wage ~ female + nonwhite + union + education + exper,
                data = train_cps,
                method = "lm",
                trControl = trainControl(method = "repeatedcv",
                                         number = 10, 
                                         repeats = 5))
summary(lm_cps)
#' Rubbish R^2 - features are missing

lm_cps2 <- train(wage ~ female + nonwhite + union + education + exper + female:nonwhite,
                 data = train_cps,
                 method = "lm",
                 trControl = trainControl(method = "repeatedcv",
                                         number = 10,
                                         repeats = 5))
summary(lm_cps2)

lm_cps3 <- train(wage ~ female + nonwhite + union + education + exper + 
                        female:education + female:exper + nonwhite:education,
                 data = train_cps,
                 method = "lm",
                 trControl = trainControl(method = "repeatedcv",
                                         number = 10,
                                         repeats = 5))
summary(lm_cps3)

#' *Example 2*

cd_usa <- read.dta("data/gujrati-example/Stata/Table2_1.dta")
glimpse(cd_usa)

summary(lm(lnoutput ~ lnlabor + lncapital, data = cd_usa))

#' This produces a highly explanatory model for the output of the state,
#' dependent on the labor and capital as inputs
#' 
#' Since the sample size is small, a bootstrap might be used to circomvent the 
#' requirement of normality for standard errors

lm_stat <- function(data, i) {
  lm_model <- lm(lnoutput ~ lnlabor + lncapital, data[i, ])
  return(coef(lm_model))
}

boot_cb <- boot(cd_usa, statistic = lm_stat, R = 1000)

#' Running the restricted version of the regression

summary(lm(lnoutlab ~ lncaplab, data = cd_usa))

summary(lm(outputstar ~ laborstar + capitalstar, data = cd_usa))
cd_model1 <- train(scale(output) ~ labor + capital, 
                   data = cd_usa,
                   method = "lm",
                   preProcess = c("center", "scale"),
                   trControl = trainControl(method = "boot", number = 100))
summary(cd_model1)

#' *Example 3*

gdp_us <- read.dta("data/gujrati-example/Stata/Table2_5.dta")
glimpse(gdp_us)

summary(lm(lnrgdp ~ time, data = gdp_us))
summary(lm(rgdp ~ time + time2, data = gdp_us))
summary(lm(lnrgdp ~ time + time2, data = gdp_us))

#' *Example 4*

food_expend <- read.dta("data/gujrati-example/Stata/Table2_8.dta")
glimpse(food_expend)

summary(lm(sfdho ~ lnexpend, data = food_expend))
summary(lm(sfdho ~ I(1/expend), data = food_expend))
summary(lm(sfdho ~ expend + expend2, data = food_expend))

#' When there is little to choose between these two models in terms of R^2,
#' cross-validation might provide an answer for which model to choose. The model
#' with better predictive power wins

tr_rows <- createDataPartition(food_expend$sfdho, p = 0.8, list = FALSE)
food_expend_train <- food_expend[tr_rows, ]
food_expend_test <- food_expend[-tr_rows, ]

food_model1 <- train(sfdho ~ lnexpend, 
                     data = food_expend_train,
                     method = "lm",
                     preProcess = c("center", "scale"),
                     trControl = trainControl(method = "repeatedcv", 
                                              number = 10, 
                                              repeats = 5))
food_model2 <- train(sfdho ~ I(1/expend), 
                     data = food_expend_train,
                     method = "lm",
                     preProcess = c("center", "scale"),
                     trControl = trainControl(method = "repeatedcv", 
                                              number = 10, 
                                              repeats = 5))

food_model1
food_model2

#' model 1 is better. When multiple models fit the data closely, I tend to lean
#' towards the model that offers a richer interpetation, even if it has lesser
#' predictive power

#' *Example 5*

corruption <- read.dta("data/gujrati-example/Stata/Table2_18.dta")
glimpse(corruption)

corruption_model1 <- train(index ~ country + gdp_cap,
                           data = corruption,
                           method = "rf")
corruption_model1

corruption_model2 <- train(index ~ country * gdp_cap,
                           data = corruption,
                           method = "rf")
corruption_model2

#' *Example 6* Relationship between Gross Private Investments (GPI) and Gross
#' Personal Savings (GPS). How much of the savings do people tend to invest?

si_usa <- read.dta("data/gujrati-example/Stata/Table3_6.dta")
glimpse(si_usa)

summary(lm(gpi ~ gps, data = si_usa))

#' 1981-82 was the worst recession for peace-time US. We can include this as a
#' structural dummy using the variable recession81 = 1 for observations beyond
#' 81 and 0 otherwise

summary(lm(gpi ~ gps + recession81, data = si_usa))
summary(lm(gpi ~ gps + recession81 + gpsrec81, data = si_usa))

#' Results dont tally with the book but an interesting application of dummy
#' variables to detect structural changes. This is especially true for
#' time-series

#' *Example 7*
#' Deseasonalizing trends with dummy variables

sales_df <- read.dta("data/gujrati-example/Stata/Table3_10.dta")
glimpse(sales_df)

sales_df <- rename(sales_df, q2 = d2, q3 = d3, q4 = d4)
glimpse(sales_df)

summary(sales_model <- lm(sales ~ q2 + q3 + q4, data = sales_df))

sales_df <- sales_df %>% 
              mutate(sales_adj = mean(sales) + residuals(sales_model))

dev.new()
ggplot(data = sales_df, aes(x = yearq, y = sales)) +
  geom_line(aes(linetype = "Original data")) +
  geom_line(aes(y = sales_adj, linetype = "Deseasonalized")) +
  labs(x = "Year",
       y = "Sales",
       linetype = "Sales")

#' As can be seen in the plot above, some of the variation in sales is
#' attributed to the variation due to the demand associated with change in
#' quarters. The underlying pattern beyond this seasonal variation can be
#' explored using this kind of a regression analysis.

summary(sales_model2 <- lm(sales ~ rpdi + conf + q2 + q3 + q4, 
                           data = sales_df))

sales_df <- sales_df %>% 
              mutate(sales_adj = mean(sales) + residuals(sales_model2))

dev.new()
ggplot(data = sales_df, aes(x = yearq)) +
  geom_line(aes(y = sales, linetype = "Original Data")) +
  geom_line(aes(y = sales_adj, linetype = "Deseasonalized")) +
  labs(x = "Year",
       y = "Sales",
       linetype = "Sales")

summary(sales_model3 <- lm(sales ~ rpdi + conf + q2 + q3 + q4 + 
                                   q2:rpdi + q3:rpdi + q4:rpdi +
                                   q2:conf + q3:conf + q4:conf,
                           data = sales_df))

#' From the above table, the lack of significance of the coefficients show that
#' there is no seasonal variation in rpdi and conf

summary(sales_model4 <- lm(log(sales) ~ rpdi + conf + q2 + q3 + q4, 
                           data = sales_df))

#' Verifying Frisch-Waugh theorem
#'
#' Regress sales, rdpi and conf individually on the dummy variables for the
#' quarters. This accounts for the variation in these variables that is
#' correlated with the variation in the quarters

summary(s1 <- lm(sales ~ q2 + q3 + q4, data = sales_df))
summary(s2 <- lm(rpdi ~ q2 + q3 + q4, data = sales_df))
summary(s3 <- lm(conf ~ q2 + q3 + q4, data = sales_df))

#' The residuals will compute the left over variation in the variables once the 
#' seasonal variation is accounted for

rs1 <- residuals(s1)
rs2 <- residuals(s2)
rs3 <- residuals(s3)

#' Now we can capture the variation in the "purer" variables by running a
#' regression on the residuals

summary(lm(rs1 ~ rs2 + rs3 - 1))
summary(lm(sales ~ rpdi + conf + q2 + q3 + q4, data = sales_df))

#' As can be seen from these regression outputs, the coefficients of rs2 and rs3
#' in the first regression and rpdi and conf in the second regression are the
#' same. This is nice since you do not need to account for seasonal variations
#' in the outcome and the predictors individually. Usage of dummies achieves two
#' tasks at once

summary(lm(sales ~ rpdi + conf + q2 + q3 + q4 + trend, data = sales_df))

#' *Example 8*
#' 

diabetes_data <- read.dta("data/gujrati-example/Stata/Table3_19.dta")
glimpse(diabetes_data)

summary(lm(diabetes ~ ban * sugar_sweet_cap, diabetes_data))

#' *Example 9*
#' Dependence of working women's hours of work; data is collected for 753 women
#' in 1975

wwmn_data <- read.dta("data/gujrati-example/Stata/Table4_4.dta")
glimpse(wwmn_data)

summary(w_model1 <- lm(hours ~ age + educ + exper + faminc + fathereduc + hage + 
                               heduc + hhours + hwage + kids618 + kidsl6 + wage 
                               + mothereduc + mtr + unemployment, 
                       data = wwmn_data))

w_corrs <- wwmn_data %>% select(-hours) %>% cor()

bad_preds <- findCorrelation(w_corrs, cutoff = 0.75, verbose = TRUE)

wwmn_cleaned <- wwmn_data %>% select(-hours) %>% 
                              select(-bad_preds) %>%
                              mutate(hours = wwmn_data$hours)
glimpse(wwmn_cleaned)

summary(w_model2 <- lm(hours ~ educ + exper + faminc + fathereduc + hage + 
                               heduc + hhours + hwage + kids618 + kidsl6 + wage 
                               + mothereduc + unemployment, 
                       data = wwmn_cleaned))

#' Often number of variables in econometric studies are handpicked and hence
#' multicollinearity should not be a reason for exclusion. There should be valid
#' arguments that drive that decision. This is a very subjective call dependent 
#' on the information available to the analyst

summary(w_model3 <- lm(hours ~ age + educ + exper + faminc + hhours + hwage + 
                               kidsl6 + wage + mtr + unemployment, 
                       data = wwmn_data))

#' *Example 10*

manpower <- read.dta("data/gujrati-example/Stata/Table4_11.dta")
glimpse(manpower)

x_corr <- manpower %>% select(-y) %>% cor()
findCorrelation(x_corr, cutoff = 0.75, verbose = TRUE, names = TRUE)

#' *Example 11*
#' What factors determine abortion rate across the 50 states in USA?
#' 
#' In this example heteroscedascity is examined. Basically, the assumption that 
#' the error variance across the observations is the same goes kaput.

abortion_df <- read.dta("data/gujrati-example/Stata/Table5_1.dta")
glimpse(abortion_df)

#' begin by adding everything into a linear model

summary(abort_model1 <- lm(abortion ~ religion + price + laws + funds + educ + income  + picket, 
                           data = abortion_df))

#' Common wisdom would dictate that parameters like income and funds (which make
#' the mechanics of abortion easier) should increase the abortion rate. The
#' results indicate that except income and picket nothing else is significant.
#' What is missing in this analysis is the effect of the state to which the
#' subject belongs to. Maybe that is a source of different groups of people?

dev.new()
qplot(residuals(abort_model1)^2, geom = "histogram") +
  labs(x = "Squared residuals",
       y = "Freuency",
       title = "Distribution of residuals for the abortion model")

#' This plot shows evidence of a heavy-tailed distribution. The residual vs
#' fitted values plot also shows systematic variation

dev.new()
qplot(residuals(abort_model1)^2, predict(abort_model1))

#' We can confirm our suspicions by running a regression of the squared
#' residuals on the predictors. We want all the coefficients in this regression
#' to be 0.

abortion_df <- abortion_df %>% 
                 mutate(resid2 = residuals(abort_model1)^2,
                        pred = predict(abort_model1),
                        pred2 = predict(abort_model1)^2)

summary(abort_err_mdl <- lm(resid2 ~ religion + price + laws + funds + educ + 
                                     income + picket, 
                            data = abortion_df))

#' Another approach is to regress the squared residuals on the fitted values,
#' which in a way captures the linear model in the previous snippet.

summary(abort_err_mdl2 <- lm(resid2 ~ pred + pred2, data = abortion_df))

#' Given that the error terms are not i.i.d., we can look to remedy these. A
#' popular method is logarithms

summary(abort_model2 <- lm(lnabortion ~ religion + price + laws + funds + educ +
                                        income + picket,
                           data = abortion_df))

abort_err_df <- abortion_df %>% 
                  mutate(resid2 = residuals(abort_model2)^2,
                         pred = predict(abort_model2),
                         pred2 = predict(abort_model2)^2)

summary(lm(resid2 ~ pred + pred2, data = abort_err_df))

#' The F-statistic from the above equation indicates that error variances are
#' equal.
#'
#' However, this raises a concern whether it is good to do such tremendous
#' assumptions to validate linear models. Does this engineering result in
#' improved predictive power?

tr_rows <- createDataPartition(abortion_df$lnabortion, p = 0.8, list = FALSE)
abortion_train <- abortion_df[tr_rows, ]
abortion_test <- abortion_df[-tr_rows, ]

model_lm <- train(abortion ~ religion + price + laws + funds + educ + income  + picket,
                  data = abortion_train,
                  method = "lm",
                  trControl = trainControl(method = "repeatedcv", 
                                           number = 10,
                                           repeats = 5))

model_rf <- train(abortion ~ state + religion + price + laws + funds + educ + income  + picket,
                  data = abortion_train,
                  method = "ranger",
                  trControl = trainControl(method = "repeatedcv", 
                                           number = 10,
                                           repeats = 5))

model_lm$results
model_rf$results

#' Random forests does not improve the accuracy remarkably. We can drop back
#' down to the normal linear model. The data seem to be woefully insufficient!

#' *Example 12*
#' Consumption function
#' What does the real consumption in a particular year depend on?

consumption_df <- read.dta("data/gujrati-example/Stata/Table6_1.dta")
glimpse(consumption_df)

summary(model_lm1 <- lm(lnconsump ~ lndpi + lnwealth + interest, data = consumption_df))

#' Time series plots needs to be checked for autocorrelation by default

dev.new()
qplot(consumption_df$year, residuals(model_lm1), geom = "line") +
  labs(x = "Year",
       y = "Residuals")

summary(model_lm2 <- lm(dlnconsump ~ dlndpi + dlnwealth + dinterest, data = consumption_df))

qplot(consumption_df$year[-1], residuals(model_lm2), geom = "line") +
  labs(x = "Year",
       y = "Residuals")
