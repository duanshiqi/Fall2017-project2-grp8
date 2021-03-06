packages.used <- 
  c("ggplot2",
    "plyr",
    "reshape2",
    "reshape",
    "shiny",
    "dplyr",
    "lubridate",
    "zoo",
    "treemap",
    "plotly",
    "leaflet",
    "geosphere",
    "shinydashboard",
    "ROCR",
    "sparklyr",
    "DT"

  )

# check packages that need to be installed.
packages.needed=setdiff(packages.used, 
                        intersect(installed.packages()[,1], 
                                  packages.used))
# install additional packages
if(length(packages.needed)>0){
  install.packages(packages.needed, dependencies = TRUE)
}

#load the packages
library(ggplot2)
library(zoo)
library(lubridate)
library(dplyr)
library(shiny)
library(shinydashboard)
library(treemap)
library(plotly)
library(reshape2)
library(leaflet)
library(geosphere)
library(ROCR)
library(DT)
library(sparklyr)


source("../lib/plot_functions.R")
source("../lib/filter_data_functions.R")
source("../lib/flight_path_map.R")
source("../lib/delay_percent_barplot.R")

flightData <- read.table(file = "../output/1990.csv",
                         as.is = T, header = T,sep = ",")
flightData$FL_DATE <- parse_date_time(flightData$FL_DATE, "%Y-%m-%d")
flightData <- flightData[flightData$ORIGIN == c("JFK", "LAX", "SEA"),]

raw_data = read.csv("../output/flight_data.csv")
dest_airport=c('All',as.character(sort(unique(raw_data$dest))))
orig_airport=c('All',as.character(sort(unique(raw_data$orig))))

temp <-  read.csv("../output/temp.csv",header=T)
origins <- as.character(sort(unique(temp$orig)))
destinations <- as.character(sort(unique(temp$dest)))

#Define UI for application that draws a histogram
shinyUI(navbarPage(theme = "bootstrap.min-copy.css",'Flight Delay',
        tabPanel("Introduction",
                 tabName="Introduction",
                 icon=icon("book"),
                 #menuItem("Overview",tabName="Overview",icon=icon("book")),
                 
                 mainPanel(
                   img(src="world_flight.jpg",height='300',width='600'),
                   h2('Introduction'),
                   includeMarkdown('intro.md')
                   )
                 # titlePanel(h2("Introduction")),
                 # mainPanel(tabPanel("Introduction"))
        ),
        tabPanel("Dynamic Map of Flights 1990 VS 2010",
                 tabName="Dynamic Map",
                 icon=icon("map-o"),

                 sidebarLayout(
                   sidebarPanel(
                     sliderInput(inputId ="range",
                                 label = "Time of data collection:",
                                 min = min(flightData$FL_DATE),
                                 max = max(flightData$FL_DATE),
                                 value = min(flightData$FL_DATE),#The initial value
                                 step = days(),
                                 animate = animationOptions(interval = 200))
                   ),
                   # Show a tabset that includes a plot, model, and table view
                   mainPanel(
                     tabsetPanel(type = "tabs", 
                                 tabPanel("Map", leafletOutput("m_dynamic"))
                     )
                   )
                 )
        ),
        tabPanel('Search you flight',
                 tabName='Search your flight',
                 icon=icon('plane'),
                 sidebarLayout(
                   sidebarPanel(
                
                     selectInput(inputId = "origin",
                                 label  = "Select the origin",
                                 choices = origins,
                                             selected ='JFK (New York, NY)'),
                     selectInput(inputId = "destination",
                                 label  = "Select the destination",
                                 choices = c('all',destinations),
                                 selected ='all'),
                     selectInput(inputId = "month",
                                 label  = "Select the month",
                                 choices = c('Jan','Feb','Mar','Apr','May','Jun','Jul',
                                             'Aug','Sep','Oct','Nov','Dec'),
                                 selected ='Jul'),
                     radioButtons(inputId = "week", 
                                  label = "Select day of the week",
                                  choices = c('all','Monday','Tuesday','Wednesday','Thursday',
                                              'Friday','Saturday','Sunday'), 
                                  selected = 'all'),
                     
                     radioButtons(inputId = "type",
                                  label = 'Calculated by:',
                                  choices = c('Percent of delay flights',
                                              'Average delay time'),
                                  selected = 'Percent of delay flights'),
                     width = 3
                 ),
                   
                   mainPanel(
                     box(leafletOutput("map23"),
                         width=600),
                     box(plotlyOutput("delay_barplot",height='200px'),width=300)
                     )
                                   
                   )
                 ),
        
        tabPanel('Statistics',
                 tabName='App',
                 icon=icon('bar-chart'),
                 tabsetPanel(type="pill",
                             tabPanel('Delay Time Expectation',
                                      sidebarLayout(
                                        sidebarPanel(
                                          
                                          selectInput(inputId = "destination1",
                                                      label  = "Select the Destination",
                                                      choices = dest_airport,
                                                      selected ='All'),
                                          selectInput(inputId = "origin1",
                                                      label  = "Select the Origin",
                                                      choices = orig_airport,
                                                      selected ='All'),
                                          width = 3
                                        ),
                                        
                                        mainPanel(
                                          box(plotlyOutput("plt_delay_time"),width=300),
                                          box(plotlyOutput("plt_delay_flight_distr"),width=300),
                                          box(plotlyOutput("plt_delay_time_distr"),width=300)
                                        )
                                      )
                                      
                             ),
                             tabPanel('Delay Reason',
                                      sidebarLayout(
                                        sidebarPanel(
                                          
                                          selectInput(inputId = "destination2",
                                                      label  = "Select the Destination",
                                                      choices = dest_airport,
                                                      selected ='All'),
                                          selectInput(inputId = "origin2",
                                                      label  = "Select the Origin",
                                                      choices = orig_airport,
                                                      selected ='All'),
                                          selectInput(inputId = "month2",
                                                      label  = "Select the Month",
                                                      choices = c('Jan','Feb','Mar','Apr','May','Jun','Jul',
                                                                  'Aug','Sep','Oct','Nov','Dec'),
                                                      selected ='Jan'),
                                          width = 3
                                        ),
                                        
                                        mainPanel(
                                          box(plotlyOutput("plt_delay_reason_distr"),width=300)
                                        )
                                      )
                                      
                             ),
                             tabPanel('Satisfication Probability of Carriers',
                                      sidebarLayout(
                                        sidebarPanel(
                                          
                                          selectInput(inputId = "destination3",
                                                      label  = "Select the destination",
                                                      choices = dest_airport,
                                                      selected ='ATL (Atlanta, GA)'),
                                          selectInput(inputId = "origin3",
                                                      label  = "Select the origin",
                                                      choices = orig_airport,
                                                      selected ='AUS (Austin, TX)'),
                                          sliderInput(inputId = "mon3",
                                                      label = "Select the month",
                                                      value = 1, min =1, max =12),
                                          sliderInput(inputId = "satisfy_time3",
                                                      label = "Select the limit of delay time (hr)",
                                                      value = 1,min = 0,max = 5),
                                          width = 3
                                        ),
                                        
                                        mainPanel(
                                          box(plotOutput("treemap",width = "100%", height = 600))
                                        )
                                      )
                                      
                             ),
                             tabPanel('Cancellation Analysis',
                                      sidebarLayout(
                                        sidebarPanel(
                                          
                                          selectInput(inputId = "destination4",
                                                      label  = "Select the destination",
                                                      choices = dest_airport,
                                                      selected ='ATL (Atlanta, GA)'),
                                          selectInput(inputId = "origin4",
                                                      label  = "Select the origin",
                                                      choices = orig_airport,
                                                      selected ='AUS (Austin, TX)'),
                                          sliderInput(inputId = "mon4",
                                                      label = "Select the month",
                                                      value = 1, min =1, max =12),
                                          width = 3
                                        ),
                                        
                                        mainPanel(
                                          box(plotlyOutput("hcontainer"),width=600)
                                        )
                                      )
                                      
                             )
                             
                 )
                 ),
        
        tabPanel('About Us',
                 tabName='About Us',
                 icon=icon('address-card-o'),
                 
                 box(includeMarkdown('contact.md')),
                 box(img(src="thank_you.png",height='300',width='400')))
        )
        )




