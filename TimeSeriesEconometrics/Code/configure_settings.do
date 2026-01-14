* Ara Patvakanian
* 2025.11.13
* APTeachingLibrary | TimeSeriesEconometrics | configure_settings.do

*** Paths ***
if "`c(os)'" == "Unix" {
	
}
else if "`c(os)'" == "Windows" {
	
}

global code									    "Code"
global data										"Data"
global figures 									"Figures"
global results 									""

*** Settings ***
clear all
graph close
set linesize 250
set maxvar 10000
set more off
set varabbrev off, permanently

*** Formatting ***
include "${code}/define_formatting.do"

*** Programs ***
// do "${code}/define_programs.do"

*** Miscellaneous ***
* FRED Key
// file open FRED_API using "${data}/.FRED_API_key", read text
// file read FRED_API FRED_API_key
// file close FRED_API
// set fredkey "`FRED_API_key'"
