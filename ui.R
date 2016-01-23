# ui.R

#load('temp2.Rdata')

shinyUI(fluidPage(
  tags$head(tags$link(rel="icon", href=
                        "data:image/png;base64,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"
)),
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
      plotOutput("time_to_stop", height = "600px"),
      
      dataTableOutput("tbl_time_to_stop")
      
      #textOutput("travel_diag")
    )
  )
))