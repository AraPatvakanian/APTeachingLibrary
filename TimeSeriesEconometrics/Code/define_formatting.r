# Ara Patvakanian
# 2025.08.06
# APTeachingLibrary | TimeSeriesEconometrics | define_formatting.r

color_blue = rgb(0,58,93,maxColorValue=255)
color_orange = rgb(172,69,30,maxColorValue=255)
dark_gray = rgb(109,110,113,maxColorValue=255)
light_gray = rgb(207, 207, 207,maxColorValue=255,alpha=150)
line_scale = 2
text_scale = 2
nice = theme_minimal() + 
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 24*text_scale),
    plot.subtitle = element_text(hjust = 0.5, size = 22*text_scale),
    axis.title = element_text(size = 22*text_scale, color=dark_gray), # face = "bold",
    axis.title.x = element_text(margin=margin(t=12*text_scale)),
    axis.title.y = element_text(margin=margin(r=12*text_scale)),
    axis.text = element_text(size = 20*text_scale, color=dark_gray),
    axis.text.x = element_text(margin=margin(t=12*text_scale,unit="pt")),
    axis.line.x = element_line(color=light_gray,size = 1.1*line_scale),
    axis.ticks.x = element_line(color=light_gray,linewidth=1*((line_scale-1)/2+1),linetype="solid"),
    axis.ticks.length.x = unit(-1,"cm"),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(color=light_gray,linewidth = 1.1*line_scale),
    panel.grid.minor = element_blank(),
  )
