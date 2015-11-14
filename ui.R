# ui.R

#load('temp2.Rdata')

shinyUI(fluidPage(
  titlePanel("Should I Stay or Should I Transfer?"),
  
  sidebarLayout(
    sidebarPanel(
      helpText("Select the trains and stops that you want to view below:"),
      
      selectInput("route_sel",
                   label = 'Train Line',
                   choices = c("1", "2", "3", 
                               "4", "5", "6",
                               "GS", "L", "SI"),
                  selected = "1",
                  multiple = T),
      selectInput("dir_sel", 
                  label = "Train Direction",
                  choices = list(North = "N", 
                                 South = "S"),
                  selected = "S"),
      selectInput("starting_stop",
                  label = "Starting Stop",
                  choices = list("Please wait..." = "")
                  ),
      selectInput("ending_stop",
                  label = "Ending Stop",
                  choices = list("Please wait..." = "")
      ),
      
      submitButton(text = "Apply Changes", icon = NULL, width = NULL),
      numericInput("outlier_level", label = "Adjust Outlier Cutoff", 
                  min = 0, max = 1, value = 0.2, step = 0.1),
      textOutput("last_update")
      #actionButton("update_fulltable", "Reload Data")
      
      ),
    
    mainPanel(
      plotOutput("time_to_stop", height = "600px")
      #dataTableOutput("travel_time")
      
      #textOutput("travel_diag")
    )
  )
))