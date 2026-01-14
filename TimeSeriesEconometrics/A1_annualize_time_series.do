* Ara Patvakanian
* 2025.09.17
* APTeachingLibrary | TimeSeriesEconometrics | annualize_time_series.do

* Annualizes Time Series
* This file includes sample code used to annualize and normalize time series.
*	— PCEPI: PCE Price Index
*		Source: U.S. Bureau of Economic Analysis
*		Retrieved from: FRED — PCEPI
*	— UR: Unemployment Rate
*		Source: U.S. Bureau of Labor Statistics
*		Retrieved from: FRED — UNRATE
*	— FFR: Federal Funds Effective Rate
*		Source: Federal Reserve Board of Governors
*		Retrieved from: FRED — FEDFUNDS
*	— GDP: Real Gross Domestic Product
*		Source: U.S. Bureau of Economic Analysis
*		Retrieved from: FRED — GDPC1

*** Settings ***
include "Code/configure_settings.do"
set graphics on

*** PCE Inflation, UR, & FFR (Frequency: Monthly) ***
import fred PCEPI UNRATE FEDFUNDS, clear
gen date = mofd(daten)
format date %tm
order date, first
drop daten datestr
tsset date
keep if inrange(date,`=tm(1979m6)',`=tm(2025m9)')
rename (UNRATE FEDFUNDS) (UR FFR)

label var PCEPI "PCE price index"
label var UR "Unemployment rate"
label var FFR "Federal funds rate"

tw line UR FFR date, ///
	lcolor("`blue'" "`orange'") lwidth(medthick ..) ///
	yscale(range(-2.5,20) lstyle(none)) xscale(lcolor(`tick_color')) ///
	ylabel(0(5)20, labsize(small) labcolor(`text_color') labgap(tiny) angle(0) noticks) ///
	xlabel(`=tm(1980m1)'(60)`=tm(2025m1)', format(%tmCCYY) labsize(small) ///
		labcolor(`text_color') labgap(tiny) angle(0) noticks) ///
	xtick(`=tm(1980m1)'(60)`=tm(2025m1)', tlcolor(`tick_color') tlength(2) tp(i) axis(1)) ///
	xmtick(`=tm(1980m1)'(12)`=tm(2025m1)', tlcolor(`tick_color') tlength(1) tp(i) axis(1)) ///
	legend(on order(1 2) rows(1) ///
		size(*1) symxsize(medium) color("`text_color'") region(lstyle(none)) bplace(left)) ///
	title("", size(medlarge) color("`text_color'") position(11)) ///
	xtitle("", size(*1) color("`text_color'")) ///
	ytitle("Percent", size(*1) color("`text_color'")) ///
	plotregion(`plot_region') graphregion(`graph_region') `graph_size' ///
	name("UR_FFR", replace)
graph export "Figures/UR_FFR.pdf", replace

regress UR FFR if inrange(date,`=tm(1980m1)',`=tm(2025m7)'), robust

tsset date // Monthly
gen PCE_12m = ((PCEPI/L12.PCEPI)-1)*100         	// Annual
gen PCE_1m = ((PCEPI/L1.PCEPI)^(12)-1)*100      	// 1-month annualized 
gen PCE_3m = ((PCEPI/L3.PCEPI)^(4)-1)*100       	// 3-month annualized 
gen PCE_dlog_3m = (log(PCEPI)-log(L3.PCEPI))*4*100 	// 3-month annualized using log-differences

* Notice that the two lines start to diverge when we are further away from 0.
tw line PCE_3m PCE_dlog_3m date, ///
	lcolor("`blue'%50" "`orange'%50") lwidth(medthick ..) ///
	yscale(range(-10,15) lstyle(none)) xscale(lcolor(`tick_color')) ///
	ylabel(-10(5)15, labsize(small) labcolor(`text_color') labgap(tiny) angle(0) noticks) ///
	xlabel(`=tm(1980m1)'(60)`=tm(2025m1)', format(%tmCCYY) labsize(small) ///
		labcolor(`text_color') labgap(tiny) angle(0) noticks) ///
	xtick(`=tm(1980m1)'(60)`=tm(2025m1)', tlcolor(`tick_color') tlength(2) tp(i) axis(1)) ///
	xmtick(`=tm(1980m1)'(12)`=tm(2025m1)', tlcolor(`tick_color') tlength(1) tp(i) axis(1)) ///
	legend(on order(1 "Three-month (actual)" 2 "Three-month (log-difference)") rows(1) ///
		size(*1) symxsize(medium) color("`text_color'") region(lstyle(none)) bplace(left)) ///
	title("PCE Inflation", size(medlarge) color("`text_color'") position(11)) ///
	xtitle("", size(*1) color("`text_color'")) ///
	ytitle("Percent", size(*1) color("`text_color'")) ///
	plotregion(`plot_region') graphregion(`graph_region') `graph_size' ///
	name("PCE_actual_vs_dlog_3m", replace)
graph export "Figures/PCE_actual_vs_dlog_3m.pdf", replace

*** Real GDP (Frequency: Quarterly) ***
import fred GDPC1, clear
gen date = qofd(daten)
format date %tq
order date, first
drop daten datestr
tsset date
keep if inrange(date,`=tq(1979q2)',`=tq(2025q2)')
rename (date GDPC1) (date_q GDP)

label var GDP "Real GDP"

tsset date_q // Quarterly
foreach hh of numlist 1 2 4 8 16 { // Convenient for-loop implementation
    gen GDP_`hh'q = ((GDP/L`hh'.GDP)^(4/`hh')-1)*100
    gen GDP_dlog_`hh'q = (log(GDP)-log(L`hh'.GDP))*(4/`hh')*100
}

* These are equivalent
egen mean_GDP_4q = mean(GDP_4q)
egen sd_GDP_4q = sd(GDP_4q)
gen GDP_4q_std = ///
    (GDP_4q-mean_GDP_4q)/sd_GDP_4q

egen GDP_4q_std_alt = std(GDP_4q)

tw line GDP_4q date_q, yaxis(1) ///
	lcolor("`blue'") lwidth(medthick) ///
|| line GDP_4q_std date_q, yaxis(2) ///
	lcolor("`orange'") lwidth(medthick) ///
	yscale(range(-10,15) lstyle(none)) yscale(range(-5,5) lstyle(none) axis(2)) ///
	xscale(lcolor(`tick_color')) ///
	ylabel(-10(5)15, labsize(small) labcolor(`text_color') labgap(tiny) angle(0) noticks) ///
	ylabel(-6(3)9, labsize(small) labcolor(`text_color') labgap(tiny) angle(0) noticks axis(2)) ///
	xlabel(`=tq(1980q1)'(20)`=tq(2025q1)', format(%tqCCYY) labsize(small) ///
		labcolor(`text_color') labgap(tiny) angle(0) noticks) ///
	xtick(`=tq(1980q1)'(20)`=tq(2025q1)', tlcolor(`tick_color') tlength(2) tp(i) axis(1)) ///
	xmtick(`=tq(1980q1)'(4)`=tq(2025q1)', tlcolor(`tick_color') tlength(1) tp(i) axis(1)) ///
	legend(on order(1 "Four-quarter, actual [left]" 2 "Four-quarter, standardized [right]") rows(1) ///
		size(*1) symxsize(medium) color("`text_color'") region(lstyle(none)) bplace(left)) ///
	title("Real GDP Growth", size(medlarge) color("`text_color'") position(11)) ///
	xtitle("", size(*1) color("`text_color'")) ///
	ytitle("Percent", size(*1) color("`text_color'")) ///
	ytitle("Standard deviations", size(*1) color("`text_color'") orientation(rvertical) axis(2)) ///
	plotregion(`plot_region') graphregion(`graph_region') `graph_size' ///
	name("GDP_actual_vs_standard_4q", replace)
graph export "Figures/GDP_actual_vs_standard_4q.pdf", replace
