source('server_functions.R', local = TRUE)
work_local = TRUE
#options(error = NULL)

if(!work_local){
  full_table <- createFullMergedTable()
  save(full_table, file = 'data/full_table.Rdata')
}else{
  load('data/full_table.Rdata')
  message("Completed Loading Data")
}


stop_subset <- full_table %>% 
  filter(route_id != "") %>% 
  group_by(stop_id, route_id, stop_name) %>% 
  summarise(ct = n()) %>% 
  group_by(route_id) %>% 
  filter(ct >.2*max(ct)) %>% 
  group_by(stop_id, stop_name) %>% 
  arrange(route_id) %>% 
  summarise(avail_routes = paste(route_id, collapse = ",")) %>% 
  mutate(full_label = paste0(stop_name," (",avail_routes,")"))

stop_selection <- as.character(stop_subset$stop_id)
names(stop_selection) <- stop_subset$full_label





# rows <- data$sched_stops %>% nrow()



shinyServer(function(input, output, session) {
  ids_selected <- NULL
  
  
  output$time_to_stop <- renderPlot({
    ## How can we make a placeholder plot that can be used while the data gets loaded.
    
    if( input$ending_stop != ""){
    getTimeBetweenStations(full_df = full_table,
                           route = input$route_sel,
                           dir = input$dir_sel,
                           start_station = input$starting_stop,
                           end_station = input$ending_stop) %>%
      filter(stop_id ==input$ending_stop,
             time_in_transit >0 ) %>%
      mutate(dayT = dayType(station_leave_time)) %>%
      ggplot(data =., aes(x = hour(station_leave_time),
                          y = time_in_transit/60,
                          color = route_id)) +
      geom_point(alpha = 0.15)+ 
      stat_summary(fun.y = "median", geom = "line") + 
      facet_grid(dayT~.) + 
      labs(x = "Depart Time (Hour of Day)",
           y = "Time in Transit (min)")
    }
      

  })
  
  output$tbl_time_to_stop <- renderDataTable({
    getTimeBetweenStations(full_df = full_table,
                          route = input$route_sel,
                          dir = input$dir_sel,
                          start_station = input$starting_stop,
                          end_station = input$ending_stop) %>%
    filter(stop_id ==input$ending_stop,
           time_in_transit >0 ) %>%
    mutate(dayT = dayType(station_leave_time))  %>% 
    group_by(route_id, dayT,`hour` = hour(station_leave_time)) %>% 
    summarise(`med` = median(time_in_transit/60)) %>%
      cast(dayT+hour~route_id, mean)
  })
  
  
  
  output$travel_time <- renderDataTable({
    getTrainTravelTime(full_df = full_table,
                       route = input$route_sel,
                       dir = input$dir_sel,
                       start_station = input$starting_stop
                        ) %>% 
      filter(time_in_transit >0) %>% 
      group_by(route_id,stop_id) %>% 
      summarise(avg = mean(time_in_transit/60,na.rm = T), 
                stand_dev = sd(time_in_transit/60,na.rm = T),
                ct = n()) %>%
      filter(ct > input$outlier_level*max(ct)) %>% 
      left_join(stop_subset, by = 'stop_id') %>% 
      select(stop_name, route_id,avg, stand_dev, ct)
      
  })
  
  output$travel_diag <- renderPrint({
    #str(sched_stops)
    #str(trainids)
    str(input$route_sel)
    str(input$dir_sel)
    str(input$starting_stop)
  })
  
#   observe({
#     ids_selected <<- filterTrainIds(clean_trainid = trainids, 
#                    route = input$route_sel, 
#                    dir_interest = input$dir_sel )
#   })
#   
  output$last_update <- renderText({
    paste("Last Updated:",format(max(full_table$timeFeed)))
    
  })
  ## Add stop selections to UI
#   observeEvent(input$update_fulltable,
#                {
#                  message("began reload")
#                  full_table <<- createFullMergedTable()
#                  message("end reload")
#                })
  
  observe({
    updateSelectInput(session, "starting_stop", 
                      choices = as.list(stop_selection),
                      selected = "120")
    updateSelectInput(session, "ending_stop", 
                      choices = as.list(stop_selection),
                      selected = "137")
  })
  
})
