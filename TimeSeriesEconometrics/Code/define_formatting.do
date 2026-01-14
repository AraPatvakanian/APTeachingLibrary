* Ara Patvakanian
* 2025.09.17
* APTeachingLibrary | TimeSeriesEconometrics | define_formatting.do

set scheme s1color
grstyle init
grstyle gsize axis_title_gap small
grstyle yesno draw_major_hgrid no
grstyle yesno draw_major_vgrid yes
graph set window fontface "Open Sans"

local tick_color 		`"199 200 202"'
local blue 				`"0 58 93"' 
local orange 			`"172 69 30"'
local teal 				`"47 158 135"'

local graph_size 		"xsize(1920pt) ysize(1080pt)"
local graph_region 		"margin(t+2 b+2 r+6)"
local plot_region 		"margin(zero) style(none)"
local text_color 		`"109 110 113"'
local legend_options 	`"size(*1.1) symxsize(medium) color("`text_color'") region(lstyle(none)) bplace(left)"'
local tick_options 		`"labgap(0.15cm) tlcolor("`tick_color'") tlength(1) tp(i)"'
