* Ara Patvakanian
* 2025.09.15
* APTeachingLibrary | TimeSeriesEconometrics | retrieve_time_series.do

* Retrieves Time Series for LPs
* Pulls the following series for use in local projections training.
* FRED refers to Federal Reserve Economic Data hosted by the St. Louis Fed.
*	— SP500: S&P500 Composite Stock Market Index
*		Source: Standard & Poor's
*		Retrieved from: FRED — SP500 (from 2016 onwards)
*       Retrieved from: Robert Shiller's website (prior to 2016): https://shillerdata.com/
* 	— employment: Total Nonfarm Payrolls
*		Source: U.S. Bureau of Labor Statistics
* 		Retrieved from: FRED — PAYEMS
* 	— PCEPIX: Core PCE Price Index
* 		Source: U.S. Bureau of Economic Analysis
*		Retrieved from: FRED — PCEPILFE
* 	— GZCS: Gilchrist & Zakrajšek Credit Spread
*		Source: Federal Reserve Board of Governors
*		Retrieved from: Federal Reserve Board of Governors Website
*	— corporate_bonds: Nonfinancial Corporate Bonds
*		Source: Federal Reserve Board of Governors
*		Retrieved from: FRED — CBLBSNNCB
*	— house_prices: U.S. House Price Index
*		Source: U.S. Federal Housing Finance Agency
*		Retrieved from: FRED — USSTHPI

*** Settings ***
include "Code/configure_settings.do"
set graphics on

* S&P500
* FRED only has the S&P500 data starting in 2016:01; I supplement it with open-source
* data (original name: ie_data.xls) taken from Robert Shiller's website for prior to 2016.
* For consistency with Shiller's data, I first take the monthly average of the SP500 series,
* and then the quarterly average of the monthly series. This should be fine enough for our purposes.
import fred SP500, clear
drop if SP500 == .
gen date_m = mofd(daten)
format date_m %tm
collapse (mean) SP500, by(date_m)
gen date = qofd(dofm(date_m))
format date %tq
collapse (mean) SP500, by(date)
tempfile temp
save `temp', replace

* Robert Shiller's Website: https://shillerdata.com/
import excel "${data}/Shiller_ie_data.xls", clear sheet("Data") firstrow cellrange(A8) allstring(%4.2f)
keep A B
rename (A B) (date_m SP500)
gen date = qofd(dofm(monthly(date_m,"YM")))
format date %tq
drop if date == .
destring SP500, replace
collapse (mean) SP500, by(date)

// rename SP500 SP500_Shiller // High Correlation
keep if inrange(date,tq(1960q1),tq(2016q1))
merge 1:1 date using `temp', nogen
save `temp', replace

* Employment & Core PCE Price Index
import fred PAYEMS PCEPILFE, clear 
rename (PAYEMS PCEPILFE) (employment PCEPIX)
gen date = qofd(daten)
format date %tq
keep date employment PCEPIX
order date employment PCEPIX
collapse (mean) employment PCEPIX, by(date)
merge 1:1 date using `temp', nogen
save `temp', replace

* Gilchrist & Zakrajšek Credit Spread
import delimited "https://www.federalreserve.gov/econres/notes/feds-notes/ebp_csv.csv", ///
	clear case(preserve)
rename (date gz_spread ebp est_prob) (date_str GZCS EBP est_prob_recession)
gen date = qofd(daily(date_str,"YMD"))
format date %tq
order date GZCS EBP est_prob_recession
keep date GZCS
collapse (mean) GZCS, by(date)
merge 1:1 date using `temp', nogen
save `temp', replace

* Corporate Bonds & House Prices 
import fred CBLBSNNCB USSTHPI, clear
rename (CBLBSNNCB USSTHPI) (corporate_bonds house_prices)
gen date = qofd(daten)
format date %tq
keep date corporate_bonds house_prices
merge 1:1 date using `temp', nogen
keep if inrange(date,tq(1960q1),tq(2025q4))

order date employment PCEPIX corporate_bonds SP500 house_prices GZCS
label var employment "Total Nonfarm Payrolls"
label var PCEPIX "Core PCE Price Index"
label var corporate_bonds "Outstanding Corporate Bonds"
label var SP500 "S&P500 Index (Quarterly Average)"
label var house_prices "House Price Index"
label var GZCS "Gilchrist & Zakrajšek Credit Spread"

tsset date
compress
save "${data}/macro_financial_Q.dta", replace
