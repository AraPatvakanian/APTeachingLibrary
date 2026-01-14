* Ara Patvakanian
* 2025.09.15
* APTeachingLibrary | TimeSeriesEconometrics | run_LPs.do

* Runs Local Projections
* In this training, we will be replicating the local projections that I showed 
* in the slides. We estimate the response of the outcome variables to monetary
* policy (demand-side) and oil supply news (supply-side) shocks.
* 
* The data we will use is a mix of macro and financial variables pulled from open-source
* data. Switch \`refresh_data\` runs get_time_series.do, which then gets merged with 
* the follwoing monetary policy and oil supply news shocks.
* 	— NOT_MP: Monetary Policy Shocks from Nunes, Ozdagli, & Tang (2022)
* 		Raises 1-year Treasury yield by 1 percentage point on impact.
* 		I show you how to rescale it to instead raise the 1-year bond yield by
* 		0.25 basis points on impact. This series is not included because the paper has
*		not yet been published and the series has not yet been made open-source.
* 	— K_OSN: Oil Supply News Shocks from Känzig (2021)
* 		Raises the real price of oil by 10% on impact.
* 
* We estimate 6 sets of LPs (1 for each variable) over 4 years (H = 16 since  
* the data is quarterly). We include 1 year of lags (p = 4).

*** Settings ***
include "Code/configure_settings.do"
set graphics on // Switch These Off for Speed
set output proc // error

*** Options ***
local horizons 				16
local start_dates			`=tq(1985q1)'
local end_dates 			`=tq(2019q4)'
local impulse_variables		"NOT_MP K_OSN"
local response_variables	"log_employment log_PCEPIX log_corporate_bonds log_SP500 log_house_prices GZCS"
local control_lags			4
local response_lags 		0
local impulse_lags 			0
local specification 		"c.L(1/`control_lags').(`response_variables')"

*** Switches ***
local refresh_data 			1
local run_LPs				1
local combine_LPs			1

if `refresh_data' {
	* Quarterly series data
	do "retrieve_time_series.do"
	use "${data}/macro_financial_Q.dta", clear
	tempfile temp
	save `temp'
	
	* Merge with MP shocks from Nunes, Ozdagli, & Tang 2022 aggregated to quarterly frequency
	import delimited using "${data}/shocks/AJRshocks_04172024.csv", clear
	gen date_q = qofd(date(date,"DMY",2019))
	drop date
	format date_q %tq
	rename (ff4_id ff4id_resid mp gkmp) (FF4_ID FF4_IDR NOT_MP NOT_MP_GK)
	keep date_q NOT_MP
	collapse (sum) NOT_MP, by(date_q)
	label var NOT_MP "Nunes, Ozdagli, & Tang (2022) Monetary Policy Shock"
	
	* Rescale by multiplying by 4
	foreach vv of varlist NOT_MP {
		qui replace `vv' = 4*`vv'
		di as result "MP shocks rescaled by dividing LHS variable by 4 (multiplying MP shock by 4)"
	}
	
	rename date_q date
	merge 1:1 date using `temp', nogen
	
	* Take log-differences & preserve labels
	foreach vv of varlist SP500 house_prices corporate_bonds PCEPIX employment {
		gen log_`vv' = log(`vv')*100
		label variable log_`vv' "`:variable label `vv''"
	}
	save `temp', replace
	
	* Merge with OSN shocks from Kaenzig 2021 aggregated to quarterly frequency
	* GitHub: https://github.com/dkaenzig/oilsupplynews
	import excel "${data}/shocks/oilSupplyNewsShocks_2024M12.xlsx", clear firstrow sheet("Monthly")
	gen date = qofd(dofm(monthly(Date,"YM")))
	format date %tq
	rename (Oilsupplysurpriseseries Oilsupplynewsshock) (K_OSN_surprise K_OSN)
	order date K_OSN_surprise K_OSN
	keep date K_OSN
	collapse (sum) K_OSN, by(date)
	label var K_OSN "Kaenzig (2021) Oil Supply News Shock"
	merge 1:1 date using `temp', nogen
	
	tsset date
	compress
	save "${data}/macro_financial_LPs_Q.dta", replace
}

if `run_LPs' {
	use "${data}/macro_financial_LPs_Q.dta", clear
	
	foreach ss of numlist `start_dates' {
	foreach ee of numlist `end_dates' {
	foreach xx of numlist `horizons' {
		local SSS = "`=year(dofq(`ss'))'"
		local EEE = "`=year(dofq(`ee'))'"
		local SS = `ss'+`control_lags' // Start of LHS
		local EE = `ee'-`horizons' // End of LHS
		di as result %tm `ss'
		di as result %tm `ee'
		di as result %tm `SS'
		di as result %tm `EE'
	foreach mm of varlist `impulse_variables' {
	foreach rr of varlist `response_variables' {
		local graph_title : variable label `rr'
       
		* Skip If Shock Not Defined Before Sample Date
        qui levelsof `mm' if date == `ss', local(check_shock)
		if "`check_shock'" == "" continue
		
		* Lags of Response Variable
		if `response_lags' > 0 local rr_lags "L(1/`response_lags').`rr' "
		else local rr_lag ""
		
        * Lags of Impulse Variable
        if `impulse_lags' > 0 local mm_lags "L(1/`impulse_lags').`rr' "
        else local mm_lag ""
		
		* Generate Response at Different Horizons (LHS)
		* Note: You can do this in the actual regressions, but for the sake of computational
		* efficiency you should do it outside of the LPs.
		preserve
		foreach hh of numlist 0/`xx' {
			foreach vv of varlist log_employment log_PCEPIX log_corporate_bonds log_SP500 log_house_prices {
				qui gen DF_`vv'_`hh' = F`hh'.`vv' - L1.`vv' if L1.`vv' != . // "Specification #3": Cumulative effects
			}
			qui gen DF_GZCS_`hh' = F`hh'.GZCS if L1.GZCS != . // "Specification #1"
		}
		
		di as result "Specification: DF_`rr'_hh `mm' `mm_lag' `rr_lag' `specification'"
		* Estimate the LPs
		foreach hh of numlist 0/`xx' {
			// qui regress DF_`rr'_`hh' `mm' `mm_lag' `rr_lag' `specification' ///
			//	if inrange(date,`SS',`EE'), robust coeflegend
			qui newey DF_`rr'_`hh' `mm' `mm_lag' `rr_lag' `specification' ///
				if inrange(date,`SS',`EE'), level(95) lag(5) // coeflegend
			
			qui gen B_`hh' = _b[c.`mm']
			qui gen SE_`hh' = _se[c.`mm']
		}
		
		qui keep if _n==1
		qui keep date B_* SE_*
		qui reshape long B_ SE_, i(date) j(horizons)
		rename *_ *
		qui drop date
		
		* Confidence Intervals
		* SD*1 = 68%, SD*1.65 = 90%, SD*1.96 = 95%
		qui gen L68 = B - SE
		qui gen U68 = B + SE
		qui gen L90 = B - 1.65*SE
		qui gen U90 = B + 1.65*SE
		qui gen L95 = B - 1.96*SE
		qui gen U95 = B + 1.96*SE
		
		local series_min = 0
		local series_max = 0
		foreach vv of varlist L68 U68 L90 U90 B {
			qui summ `vv', meanonly
			if `r(min)' < `series_min' local series_min `r(min)'
			if `r(max)' > `series_max' local series_max `r(max)'
		}
		local bound = 0.5
		gen date = horizons
		include "Code/format_axes.do"
		
		di as result "`graph_title'"
		label var B "Estimate"
		label var L68 "68% confidence interval"
		label var U68 "68% confidence interval"
		label var L90 "90% confidence interval"
		label var U90 "90% confidence interval"
		label var L95 "95% confidence interval"
		label var U95 "95% confidence interval"
		
		tw rarea U68 L68 horizons, lwidth(0) color(gs8%25) ///
		|| rarea U90 L90 horizons, lwidth(0) color(gs6%25) ///
		/* || rarea U95 L95 horizons, lwidth(0) color(gs4%25) */ ///
		|| line B horizons, lcolor(red) lwidth(thick) ///
			yline(0, lcolor(`text_color') lpattern(dash)) ///
			yscale(range(`L',`U') lstyle(none)) ///
			ylabel(`L'(`S')`U', labsize(small) labcolor(`text_color') labgap(tiny) angle(0) noticks) ///
			xscale(range(0/`xx') lcolor(`tick_color')) ///
			xlabel(0(2)`xx', labsize(small) labcolor(`text_color') labgap(tiny) angle(0) noticks) ///
			xtick(0(2)`xx', tlcolor(`tick_color') tlength(2) tp(i) axis(1)) ///
			xmtick(0(1)`xx', `tick_options' axis(1)) ///
			legend(on order(3 2 1) rows(1) `legend_options') ///
			title("`graph_title'", size(small) color("`text_color'") position(11)) ///
			xtitle("Quarters after the shock", size(small) color("`text_color'")) ///
			ytitle("Percentage points", size(small) color("`text_color'")) ///
			plotregion(`plot_region') graphregion(`graph_region') `graph_size' ///
			name("`rr'_`mm'_`xx'", replace) // _`SSS'_`EEE'
		graph export "${figures}/local_projections/intermediates/`rr'_`mm'_`xx'_`SSS'_`EEE'.pdf", replace
		graph save "${figures}/local_projections/temp/`rr'_`mm'_`xx'_`SSS'_`EEE'.gph", replace // For combining
		
		restore
	}
	}
	graph close
	}
	}
	}
}

if `combine_LPs' {
	use "${data}/macro_financial_LPs_Q.dta", clear
	
	foreach ss of numlist `start_dates' {
	foreach ee of numlist `end_dates' {
	foreach xx of numlist `horizons' {
		local SSS = "`=year(dofq(`ss'))'"
		local EEE = "`=year(dofq(`ee'))'"
		local SS = `ss'+`control_lags'
		local EE = `ee'-`horizons'
	foreach mm of varlist `impulse_variables' {
		cap graph drop *
		graph use "${figures}/local_projections/temp/log_employment_`mm'_`xx'_`SSS'_`EEE'", nodraw name(F1)
		graph use "${figures}/local_projections/temp/log_PCEPIX_`mm'_`xx'_`SSS'_`EEE'", nodraw name(F2)
		graph use "${figures}/local_projections/temp/log_corporate_bonds_`mm'_`xx'_`SSS'_`EEE'", nodraw name(F3)
		graph use "${figures}/local_projections/temp/log_SP500_`mm'_`xx'_`SSS'_`EEE'", nodraw name(F4)
		graph use "${figures}/local_projections/temp/log_house_prices_`mm'_`xx'_`SSS'_`EEE'", nodraw name(F5)
		graph use "${figures}/local_projections/temp/GZCS_`mm'_`xx'_`SSS'_`EEE'", nodraw name(F6)
		
		grc1leg2 F1 F2 F3 F4 F5 F6, ///
			iscale(.8) ysize(9) xsize(16) imargin(l=4 b=4 r=4 t=4) ytsize(vlarge) ///
			rows(2) title("") xcommon graphon ///
			/* loff */ legendfrom(F1) position(7) legscale(*.65) ///
			name("`mm'_`xx'_`SSS'_`EEE'", replace) 
		graph export "${figures}/local_projections/combined_`mm'_`SSS'_`EEE'_`xx'.pdf", replace
	}
	}
	}
	}
}
