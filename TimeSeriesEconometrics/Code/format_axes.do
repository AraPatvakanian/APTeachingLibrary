* Ara Patvakanian
* 2025.04.02
* APTeachingLibrary | TimeSeriesEconometrics | format_axes.do

* Format Figure Axes
* Use `include` to use this script within do-files that plot figures.

*** Y-Axis Bounds ***
* Need the following locals: series_max, series_min, bound
if abs(`bound') >= 1 {
	local bound = `bound'
	
	local U = ceil(`series_max')
	local L = floor(`series_min')
	if abs(`U'-`series_max')>`bound' & abs(`U')>abs(`series_max') local U = `U'-`bound'
	else if abs(`U'-`series_max')>`bound' & abs(`U')<abs(`series_max') local U = `U'+`bound'
	if abs(`L'-`series_min')>`bound' & abs(`L')>abs(`series_min') local L = `L'+`bound'
	else if abs(`L'-`series_min')>`bound' & abs(`L')<abs(`series_min') local L = `L'-`bound'
}
else {
	local U = round(`series_max',`bound')
	local L = round(`series_min',`bound')
	
	if abs(`U'-`series_max')>`bound' & abs(`U')>abs(`series_max') local U = `U'-`bound'
	else if abs(`U'-`series_max')>`bound' & abs(`U')<abs(`series_max') local U = `U'+`bound'
	else if abs(`U'-`series_max')<`bound' & `U'<`series_max' local U = `U'+`bound'
	if abs(`L'-`series_min')>`bound' & abs(`L')>abs(`series_min') local L = `L'+`bound'
	else if abs(`L'-`series_min')>`bound' & abs(`L')<abs(`series_min') local L = `L'-`bound'
	else if abs(`L'-`series_min')<`bound' & `L'>`series_min' local L = `L'-`bound'
}

*** Y-Axis Tick Spacing ***
foreach div in 0.05 0.1 0.25 0.5 1 2 4 8 10 20 40 50 100 500 { // Make Divisible by `div'
	if `div' == 0.05 {
        local lim1 = 0
        local lim2 = 0.3
    }
    else if `div' == 0.1 {
        local lim1 = 0.3
        local lim2 = 0.5
    }
    else if `div' == 0.25 {
        local lim1 = 0.5
        local lim2 = 1.5
    }
    else if `div' == 0.5 {
        local lim1 = 1.5
        local lim2 = 3
    }
    else if `div' == 1 {
        local lim1 = 3
        local lim2 = 8
    }
	else if `div' == 2 {
        local lim1 = 8
        local lim2 = 16
    }
	else if `div' == 4 {
        local lim1 = 16
        local lim2 = 32
    }
	else if `div' == 8 {
        local lim1 = 32
        local lim2 = 80
    }
	else if `div' == 10 {
        local lim1 = 80
        local lim2 = 100
    }
	else if `div' == 20 {
        local lim1 = 100
        local lim2 = 160
    }
	else if `div' == 40 {
        local lim1 = 160
        local lim2 = 400
    }
    else if `div' == 50 {
        local lim1 = 400
        local lim2 = 500
    }
    else if `div' == 100 {
        local lim1 = 500
        local lim2 = 1000
    }
    else if `div' == 500 {
        local lim1 = 1000
        local lim2 = 10000
    }

	if abs(`U'-`L')>=`lim1' & abs(`U'-`L') < `lim2' {
		if mod(`series_min', `div') != 0 local L = `series_min' - mod(`series_min',`div') 
		if mod(`series_max', `div') != 0 local U = `series_max' + (`div'-mod(`series_max',`div'))
        local S = `div'
	}
}

if abs(`U'-`L')>= 0.2 & abs(`U'-`L') < 1 local fmt "format(%9.2g)"
else if abs(`U'-`L')>= 1 & abs(`U'-`L') < 2 local fmt "format(%9.1g)"
else local fmt "format(%9.2g)"

*** X-Axis Formatting ***
summ date, meanonly
local series_start = `r(min)'
local series_end = `r(max)'
local xt_shift = 0
local xl_shift = 0
local fix_start = 0
local fix_end = 0

if "`figure_horizon'" == "" local figure_horizon 0
if `figure_horizon' == 0 { 					// Full-Sample
	local xl_space = 60
	local xt_space = 12
	local fix_start = `xl_space'
	local fix_end = `xl_space'
	
	local xtmaj_start = `series_start' - mod(`series_start', `xl_space') + `fix_start'
	local xtmaj_end = `series_end' - mod(`series_end', `xl_space')
	local xtmin_start = `series_start' - mod(`series_start', `xt_space')
	local xtmin_end = `series_end' + (`xt_space'-mod(`series_end', `xt_space'))
	local xl_start = `xtmaj_start' + `xl_shift'
	local xl_end = `xtmaj_end'
}
else if `figure_horizon' == 1 { 			// Pre-Pandemic
	local xl_space = 60
	local xt_space = 12
	local fix_start = `xl_space'
	local fix_end = `xl_space'
	
	local xtmaj_start = `series_start' - mod(`series_start', `xl_space') + `fix_start'
	local xtmaj_end = `series_end' - mod(`series_end', `xl_space') + `fix_end'
	local xtmin_start = `series_start' - mod(`series_start', `xt_space')
	local xtmin_end = `series_end' + (`xt_space'-mod(`series_end', `xt_space'))
	local xl_start = `xtmaj_start' + `xl_shift'
	local xl_end = `xtmaj_end'
}
else if `figure_horizon' == 2 { 			// Post-Pandemic
	local xl_space = 12
	local xt_space = 1
	local xl_shift = 6
	local xt_shift = 12
	
	local xtmaj_start = `series_start' + (`xl_space' - mod(`series_start', `xl_space')) - 1 // December
	local xtmaj_end = `series_end' - mod(`series_end', `xl_space') - 1 // December
	local xtmin_start = `series_start' + mod(`series_start', `xt_space') 
	local xtmin_end = `series_end' -mod(`series_end', `xt_space')
	local xl_start = `xtmaj_start' - `xl_shift'
	local xl_end = `xtmaj_end' - `xl_shift'
}

di as result "`L'(`S')`U'"
di as result %tm `series_start'
di as result %tm `series_end'
di as result %tm `xtmaj_start'
di as result %tm `xtmaj_end'
di as result %tm `xtmin_start'
di as result %tm `xtmin_end'
di as result %tm `xl_start'
di as result %tm `xl_end'
