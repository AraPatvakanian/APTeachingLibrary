* Ara Patvakanian
* 2025.09.26
* APTeachingLibrary | TimeSeriesEconometrics | run_LPs_template.do

* Local Projections Training
* In this training, we will be replicating the local projections that I showed 
* in the slides. We estimate the response of the outcome variables to monetary
* policy (demand-side) and oil supply news (supply-side) shocks.
* The data we will use is a mix of macro and financial variables.
* 
* We estimate 6 sets of LPs (1 for each variable) over 4 years (H = 16 since  
* the data is quarterly). We include 1 year of lags (p = 4).
* 
* NOT_MP: Monetary policy shock from Nunes, Ozdagli, & Tang (2022)
* 	Raises 1-year Treasury yield by 1 percentage point on impact.
* 	In the sample file, I show you how to rescale it to instead raise the 
* 	1-year bond yield by 0.25 basis points on impact.
* K_OSN: Oil supply news shock from Kaenzig (2021)
* 	Raises the real price of oil by 10% on impact.

*** Settings ***
include "Code/configure_settings.do"
set graphics on

*** Options ***
local horizons 				16 // "H" 4 years
local start_dates			`=tq(1985q1)'
local end_dates 			`=tq(2019q4)'
local controls		 		"L(1/4).(log_employment log_PCEPIX log_corporate_bonds log_SP500 log_house_prices GZCS)"


use "Data/macro_financial_LPs_Q.dta", clear

* Step #1. Construct LHS Variable

* Step #2. Run the LPs (Regression in a For-Loop with LHS Changing), Save Coefficients/SEs

* Step #3. Generate Confidence Bands & Graph
