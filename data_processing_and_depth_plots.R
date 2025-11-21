############################################################
## Combined script: data_processing_plotting + ggplot_trans
## 
## This script reproduces:
## 1) pp_shelters.png   (time series with inundation shading)
## 2) posSD_temp_ggplot.png (depth–temperature / position SD plots)
##
## Requirements (in root folder):
## - PPCa0.csv, PPCb0.csv, PPCa3.csv, PPCb3.csv
## - tern_rect.csv
## - cc_depth_temp.csv
############################################################

## ---- 0. Packages --------------------------------------------------------

library(plyr)
library(ggplot2)
library(gganimate)
library(gifski)
library(anytime)
library(scales)
library(png)

library(ggpubr)
library(plotrix)
library(car)

## ---- 1. Shelter temperature time series (from data_processing_plotting.Rmd) ----

## 1. loading data
a0.a <- read.csv("PPCa0.csv", header = TRUE)
a0.b <- read.csv("PPCb0.csv", header = TRUE)
a0   <- data.frame(
  DateTime = a0.a$DateTime,
  Temp     = (a0.a$Temp + a0.b$Temp) / 2,
  group    = rep("air", nrow(a0.a))
)

s3.a <- read.csv("PPCa3.csv", header = TRUE)
s3.b <- read.csv("PPCb3.csv", header = TRUE)
s3   <- data.frame(
  DateTime = s3.a$DateTime,
  Temp     = (s3.a$Temp + s3.b$Temp) / 2,
  group    = rep("sediment_3cm", nrow(s3.a))
)

shelters.t <- rbind.fill(a0, s3)

## 2. define time
# define time range for the experiment
datetime <- seq.POSIXt(
  from = as.POSIXct("2020-8-7 17:0:0", tz = "Europe/Berlin"),
  to   = as.POSIXct("2020-8-13 17:0:0", tz = "Europe/Berlin"),
  by   = "15 min"
)
datetime_posix       <- data.frame(rep(datetime, 2))
shelters.t$DateTime  <- datetime_posix[, 1]

## 3. loading inundation time
rect_range <- read.csv("tern_rect.csv", header = TRUE)
rect_range$start <- as.POSIXct(
  rect_range$start,
  tz     = "Europe/Berlin",
  format = "%m/%d/%Y %H:%M"
)
rect_range$end <- as.POSIXct(
  rect_range$end,
  tz     = "Europe/Berlin",
  format = "%m/%d/%Y %H:%M"
)

## 4. making shelter temperature plot

# trim to experiment end
filter1      <- shelters.t$DateTime <= as.POSIXct("2020-08-13 17:00:00", tz = "Europe/Berlin")
shelters.t   <- shelters.t[filter1, ]

filter2      <- rect_range$start <= as.POSIXct("2020-08-13 17:00:00", tz = "Europe/Berlin")
rect_range   <- rect_range[filter2, ]

p.shelters <- ggplot(shelters.t, aes(DateTime, Temp, group = group)) + 
  geom_rect(
    data   = rect_range,
    mapping = aes(xmin = start, xmax = end, ymin = -Inf, ymax = Inf),
    fill   = "#3399FF",
    color  = NA,
    alpha  = 0.2,
    inherit.aes = FALSE
  ) +
  geom_line(aes(color = group), size = 1.2) + 
  labs(
    x = "Date and time",
    y = expression(bold("Temperature" * ~degree * C))
  ) +
  theme(plot.margin = margin(1, 30, 1, 0.5)) +
  theme(legend.position = "bottom") +
  scale_y_continuous(limits = c(15, 40)) +
  scale_color_manual(
    name   = "Sensor position",
    values = c("air" = "black", "sediment_3cm" = "red"),
    labels = c("air", "3 cm below sediment")
  ) +
  theme_bw() +
  theme(
    panel.border = element_rect(color = "black", fill = NA, size = 2),
    legend.position = "bottom",
    legend.title    = element_text(size = 11, face = "bold", color = "black"), 
    legend.text     = element_text(size = 10, face = "bold"),
    axis.title.x    = element_text(size = 12, face = "bold"),
    axis.title.y    = element_text(size = 12, face = "bold"),
    axis.text.x     = element_text(size = 10, face = "bold"),
    axis.text.y     = element_text(size = 10, face = "bold")
  ) +
  guides(color = guide_legend(override.aes = list(size = 1.5)))

print(p.shelters)

ggsave(
  "pp_shelters.png",
  p.shelters,
  units = "in",
  width = 10,
  height = 4,
  dpi = 300
)

## ---- 2. Depth × temperature variability plots (from ggplot_trans.R) ----

## 1. loading data
dp = read.csv('cc_depth_temp.csv', header = T)
dp$day_count = dp$date

dates = unique(dp$date)
days = as.vector(paste0('D', 1:25))

for (i in 1:25) {
  dp$day_count[dp$day_count == dates[i]] = days[i]
}

dp$ccLabel_daily = paste0(dp$ccLabel, '_', dp$date)

## 2. individual based analysis
n_cockles = length(unique(dp$ccLabel_daily))
date = week = ccLabel = day_count = lTemp = sdPos = rep(NA, times = n_cockles)

for (i in 1:800) {
  ind_daily = dp[dp$ccLabel_daily == unique(dp$ccLabel_daily)[i], ]
  
  date[i] = ind_daily$date[1]
  week[i] = ind_daily$week[1]
  ccLabel[i] = ind_daily$ccLabel[1]
  day_count[i] = ind_daily$day_count[1]
  ccLabel[i] = ind_daily$ccLabel
  lTemp[i] = mean(ind_daily$Temperature[2:4])
  sdPos[i] = sd(ind_daily$deltaL, na.rm = T)
}

cc.ind = data.frame(date, week, ccLabel, day_count, lTemp, sdPos)

df.label = as.data.frame(do.call(rbind, strsplit(cc.ind$ccLabel, split = "_")))
colnames(df.label) = c('tank', 'trt', 'water', 'ind')
cc.ind = cbind(cc.ind, df.label)

cc.ind = cc.ind[is.na(cc.ind$sdPos) == F, ]

## 3. log data
cc.ind$log.sdPos = log(cc.ind$sdPos)
cc.ind$log.lTemp = log(cc.ind$lTemp)

cc.ind$day_number = gsub("[^0-9.-]", "", cc.ind$day_count)
cc.ind$day_number = as.numeric(cc.ind$day_number)
cc.ind$log.day_number = log(cc.ind$day_number)

filter1 = cc.ind$log.sdPos > 0
cc.ind.log = cc.ind[filter1,]

## 4. moving window analysis
dt = cc.ind.log[order(cc.ind.log$lTemp),c(5, 11)]

step.temp = 0.1
window.temp = 3

min.temp = min(dt$lTemp)
max.temp = max(dt$lTemp)

wm.df =  data.frame(wm.temp = numeric(0), wm.logsd = numeric(0))

i = 0
n_step = (max.temp - min.temp - window.temp)/step.temp

for (i in 0:n_step)  {
  filter.temp = dt$lTemp >= (min.temp + i*step.temp) & 
    dt$lTemp <= (min.temp + i*step.temp + window.temp)
  sub.dt = dt[filter.temp, ]
  wm.temp = mean(sub.dt$lTemp)
  wm.logsd = mean(sub.dt$log.sdPos)
  wm.dt = list(wm.temp, wm.logsd)
  wm.df = rbind(wm.df, wm.dt)
  i + 1}

colnames(wm.df) = c('m.temp', 'm.logSD')

## 5. linear regression
mod1 = lm(m.logSD~m.temp, data = wm.df)
modsum1 = summary(mod1)

r2.1 = modsum1$adj.r.squared
my.p.1 = modsum1$coefficients[2,4]
f.value.1 = modsum1$fstatistic[1]

labels_annots1 = data.frame(xpos = c(15,15,15), 
                            ypos = c(2.35,2.20,2.05), 
                            labels = c(paste0("italic(R^{2}) == ", format(r2.1, digits = 2)), 
                                       paste0("italic(p) == ", format(my.p.1, digits = 2)),
                                       paste0("F ==", format(f.value.1, digits = 2))))
labels_annots2 = data.frame(xpos = c(18,18), 
                            ypos = c(2.35,2.20), 
                            labels = c(paste0("Step = ", step.temp, '°C'),
                                       paste0("Window = ", window.temp, '°C')))

## 6. plotting 
write.csv(cc.ind.log, 'cc_ind_log.csv', row.names = F)

p.all = ggplot() +
  geom_point(data = cc.ind.log, size = 3, aes(x = lTemp, y = log.sdPos, fill = water), shape = 21, alpha = 0.5) +
  geom_point(data = wm.df, size = 5, aes(x = m.temp, y = m.logSD, fill = 'summarized data'), shape = 21)+
  geom_smooth(data = wm.df,aes(x = m.temp, y = m.logSD), 
              method = 'lm', level=0.95, alpha = 0.25, 
              color = 'black', show.legend = FALSE)+
  scale_fill_manual(name = 'Micro-topography settings',
                    values = c('white', '#3399FF', '#FF0033'),
                    breaks = c('no', 'yes', 'summarized data'),
                    labels = c("No water pool", 'With water pool', "Summarized data")) +
  stat_regline_equation(data = wm.df, aes(x = m.temp, y = m.logSD), 
                        label.x = 15, label.y = 2.5, size = 6, show.legend = FALSE)+
  geom_text(data = labels_annots1, aes(x=xpos, y=ypos, label=labels, hjust = 0), 
            size = 4.5, show.legend = FALSE, parse = TRUE)+
  geom_text(data = labels_annots2, aes(x=xpos, y=ypos, label=labels, hjust = 0), 
            size = 4.5, show.legend = FALSE)+
  xlab(expression(bold(paste('Temperature (',~degree,'C)', sep=''))))+
  ylab('Position change SD') +
  scale_y_continuous(breaks=c(log(1), log(2), log(5), log(10), log(15)),
                     labels = c(1,2,5,10,15)) +
  theme_bw()+
  theme(legend.position='bottom',
        legend.title = element_text(size=14, face="bold", color = "blue"), 
        legend.text = element_text(size=12, face="bold"),
        plot.margin = unit(c(10,10,10,10), "pt"),
        strip.text.x = element_text(size = 17, face = "bold"),
        axis.title.x = element_text(size = 17, face="bold"),
        axis.title.y = element_text(size = 17, face="bold"),
        axis.text.x = element_text(size = 15, face="bold"),
        axis.text.y = element_text(size = 15, face="bold"),
        panel.border = element_rect(colour = "black", fill=NA, size=2))
p.all

ggsave('posSD_temp_ggplot.png', p.all, units = 'in', width = 10.0, height = 6.5, dpi=300)
