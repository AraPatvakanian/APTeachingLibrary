* Ara Patvakanian
* 2025.09.26
* APTeachingLibrary | TimeSeriesEconometrics | run_LPs_example.do

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
foreach vv of varlist log_employment log_PCEPIX log_corporate_bonds log_SP500 log_house_prices GZCS {
foreach hh of numlist 0/16 {
	if "`vv'" == "GZCS" gen `vv'_`hh'q = F`hh'.`vv' // Specification #1
	else gen `vv'_`hh'q = F`hh'.`vv' - L1.`vv' // Specification #3: Cumulative Response
	
	// Specification #2: gen `vv'_`hh'q = F`hh'.vv - F`=`hh'-1'.vv
}
}

keep if inrange(date,`start_dates',`end_dates')
replace NOT_MP = . if date>`end_dates'-16 // Cutting the shocks in 2015:Q4

* Step #2. Run the LPs (Regression in a For-Loop with LHS Changing); Save Coefficients/SEs
foreach vv of varlist log_employment log_PCEPIX log_corporate_bonds log_SP500 log_house_prices GZCS {
	preserve
	
	foreach hh of numlist 0/16 {
		qui regress `vv'_`hh'q NOT_MP `controls', robust
		qui gen B_`hh' = _b[NOT_MP]
		qui gen SE_`hh' = _se[NOT_MP]
	}

	qui keep in 1
	qui keep date *B_* *SE_*
	qui reshape long B_ SE_, i(date) j(horizons)
	rename *_ *
	qui drop date

	* Step #3. Generate Confidence Bands & Graph
	gen U95 = B + 1.96*SE
	gen L95 = B - 1.96*SE
	gen U90 = B + 1.68*SE
	gen L90 = B - 1.68*SE
	gen U68 = B + 1*SE
	gen L68 = B - 1*SE

	tw rarea U95 L95 horizons, lwidth(0) color(gs8%25) /// Larger bands / lighter
	|| rarea U68 L68 horizons, lwidth(0) color(gs6%25) /// Smaller bands / darker
	|| line B horizons, lcolor(red) lwidth(thick) ///
		yline(0, lcolor(`text_color') lpattern(dash)) ///
		name("`vv'", replace)
	
	restore
}
