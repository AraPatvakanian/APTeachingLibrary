# Ara Patvakanian
# 2025.08.06
# APTeachingLibrary | TimeSeriesEconometrics | time_series_models.r

# Settings
# IRkernel::installspec(name = 'RA_training_TS')
rm(list=ls())
# setwd("") # Working Directory Here
library(ggplot2)
set.seed(1)
source("Code/define_formatting.r")

# Paths
figures = "Figures/"

# Random Walks
n = 1000
t = 1:n
y_0 = 1
epsilon1 = rnorm(n, mean = 0, sd = 0.05)
epsilon2 = rnorm(n, mean = 0, sd = 1)

RW = rep(NA,n)
RWD = rep(NA,n)

RW[1] = y_0
RWD[1] = y_0

for (ii in 2:n) {
  RW[ii] = RW[ii-1] + epsilon1[ii]
  RWD[ii] = 0.05 + RWD[ii-1] + epsilon2[n+1-ii]
}

DF_RWs = data.frame(time=t,RW=RW,RWD=RWD)

pdf(paste0(figures,"RW.pdf"), width = 1920/72, height = 1080/72)
ggplot(DF_RWs, aes(x=time,y=RW)) +
  geom_line(linewidth=2,color=color_blue) +
  labs(x="Time",y="Value") +
  scale_y_continuous(limits=c(floor(min(RW)),ceiling(max(RW))),labels = function(x) sprintf("%3.2g", x)) +
  nice
invisible(dev.off())

pdf(paste0(figures,"RWD.pdf"), width = 1920/72, height = 1080/72)
ggplot(DF_RWs, aes(x=time,y=RWD)) +
  geom_line(linewidth=2,color=color_orange) +
  scale_y_continuous(limits=c(floor(min(RWD)),ceiling(max(RWD))),labels = function(x) sprintf("%3.2g", x)) +
  labs(x="Time",y="Value") +
  nice
invisible(dev.off())

# Stationary vs. Non-Stationary Data
t=1:n; y_0 = 0
epsilon = rnorm(n, mean = 0, sd = 1)
epsilon_shifted = rnorm(n, mean = 0, sd = 2)

trend = rep(NA,n)
step = rep(NA,n)
variance = rep(NA,n)

trend[1] = y_0
step[1] = y_0
variance[1] = y_0

for (ii in 2:n) {
  trend[ii] = 0.07 + trend[ii-1] + epsilon[ii]
  
  if (ii<n/2) {
    step[ii] = epsilon[ii]
    variance[ii] = epsilon[ii]
  } else if (ii>=n/2) {
    step[ii] = 3 + epsilon[ii]
    variance[ii] = epsilon_shifted[ii]
  }
}

DF = data.frame(time=t,epsilon=epsilon,trend=trend,step=step,variance=variance)
pdf(paste0(figures,"stationary.pdf"), width = 1200/72, height = 1080/72)
ggplot(DF, aes(x=time,y=epsilon)) +
  geom_line(linewidth=2,color=color_blue) +
  scale_y_continuous(limits=c(floor(min(epsilon)),ceiling(max(epsilon))),labels = function(x) sprintf("%3.2g", x)) +
  labs(x="Time",y="Value") +
  nice
invisible(dev.off())
pdf(paste0(figures,"trend.pdf"), width = 1200/72, height = 1080/72)
ggplot(DF, aes(x=time,y=trend)) +
  geom_line(linewidth=2,color=color_orange) +
  scale_y_continuous(limits=c(floor(min(trend)),ceiling(max(trend))),labels = function(x) sprintf("%3.2g", x)) +
  labs(x="Time",y="Value") +
  nice
invisible(dev.off())
pdf(paste0(figures,"step.pdf"), width = 1200/72, height = 1080/72)
ggplot(DF, aes(x=time,y=step)) +
  geom_line(linewidth=2,color=color_orange) +
  scale_y_continuous(limits=c(floor(min(step)),ceiling(max(step))),labels = function(x) sprintf("%3.2g", x)) +
  labs(x="Time",y="Value") +
  nice
invisible(dev.off())
pdf(paste0(figures,"variance.pdf"), width = 1200/72, height = 1080/72)
ggplot(DF, aes(x=time,y=variance)) +
  geom_line(linewidth=2,color=color_orange) +
  scale_y_continuous(limits=c(floor(min(variance)),ceiling(max(variance))),labels = function(x) sprintf("%3.2g", x)) +
  labs(x="Time",y="Value") +
  nice
invisible(dev.off())

# Fit AR(1) Process; Calculate & Plot IRF
# First generate a true model over T = 100 periods with coefficient = 0.9
rm(list = setdiff(ls(),c("figures","nice","color_blue","color_orange","dark_gray","light_gray")))
T = 500
phi = 0.9
mu = 0 # Unconditional mean of AR(1) process
theta = (1-phi)*mu
y = rep(NA,T)
y[1] = 0 # Initialize
epsilon = rnorm(T,mean=0,sd=1)
for (ii in 2:T) {
  y[ii] = theta + y[ii-1]*phi + epsilon[ii]
}

DF_AR1 = data.frame(time=1:T,AR1=y)
pdf(paste0(figures,"AR1.pdf"), width = 1920/72, height = 1080/72)
ggplot(DF_AR1, aes(x=time,y=AR1)) +
  geom_line(linewidth=2,color=color_blue) +
  scale_y_continuous(limits=c(floor(min(y)),ceiling(max(y))),labels = function(x) sprintf("%3.2g", x)) +
  labs(x="Time",y="Value") +
  nice
invisible(dev.off())

# Fit AR(1) model
y_lagged = y[1:T-1]
AR1 = lm(y[2:T]~y_lagged)
summary(AR1) # Estimate is 0.9052 with standard error 0.019

# Check Autocorrelation of Residuals
phi_hat = AR1[["coefficients"]][["y_lagged"]]
epsilons = y[2:T]-phi_hat*y[1:T-1]
ACF=acf(epsilons,lag.max=25)
DF_AR1_ACF = data.frame(lag=0:25,ACF=ACF[["acf"]])
pdf(paste0(figures,"AR1_ACF.pdf"), width = 1200/72, height = 1080/72)
ggplot(DF_AR1_ACF, aes(x=lag,y=ACF)) +
  geom_hline(yintercept=0.1,linetype="dashed",color=dark_gray,linewidth=1) +
  geom_hline(yintercept=-0.1,linetype="dashed",color=dark_gray,linewidth=1) +
  geom_bar(stat="identity",position="identity",
           color=color_blue,fill=color_blue,width=0.5) +
  scale_y_continuous(limits=c(-.15,1),labels = function(x) sprintf("%3.2g", x)) +
  scale_x_continuous(breaks=seq(0,25,5)) +
  labs(x="Lag",y="Autocorrelation") +
  nice
invisible(dev.off())

# Calculate IRF over H=10 periods using estimate
H = 100
IRF = rep(NA,H)

IRF[1] = 1 # Set shock of 1 in first period
for (ii in 2:H) {
  IRF[ii] = IRF[ii-1]*phi_hat
}

DF_AR1_IRF = data.frame(time=1:H,IRF=IRF)
pdf(paste0(figures,"AR1_IRF.pdf"), width = 1920/72, height = 1080/72)
ggplot(DF_AR1_IRF, aes(x=time,y=IRF)) +
  geom_line(linewidth=2,color=color_blue) +
  scale_y_continuous(limits=c(floor(min(IRF)),ceiling(max(IRF))),labels = function(x) sprintf("%3.2g", x)) +
  labs(x="Time",y="Impulse Response") +
  nice
invisible(dev.off())
# With a coefficient of 0.95, it takes ~40-50 periods for the impulse of a 1 unit shock in y to diminish to the unconditional mean.
# Note that if you wish to produce a forecast for the next 10 periods, the IRF scaled to the last value in the vector y is the exact forecast produced by the AR(1) process.

