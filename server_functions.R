
require(shiny)
require(RMySQL)
require(dplyr)
require(lubridate)
require(ggplot2)

getLineNumFromID <- function(line_full_id){
  out <-str_match(line_full_id,"[_]([0-9A-Za-z]+)[.]{2}")
  
  out[,2]
}

dayType <- function(x){
  temp = wday(x)
  ifelse(temp==1 | temp ==7, "Weekend", "Weekday")
  
}

updateTables <- function(tablesToUpdate = c("vw_thin_sched_stops", 
                                            "trainID", "enroute_trains",
                                            "stops")){
  
  load("data/dbConstants.RData")
  drv<-dbDriver("MySQL")
  
  names(tablesToUpdate)<-tablesToUpdate 
  
  con<-dbConnect(drv,
                 username = USERNAME,
                 password = PASSWORD,
                 host= HOST,
                 port = PORT,
                 dbname = DBNAME)
  
  
  output <- lapply(as.list(tablesToUpdate), FUN = function(x){
    tbl_df(dbReadTable(con, x))
  })
  
  dbDisconnect(con)
  
  output
  
}

cleanSchedStops <-function(sched_stops){
  sched_stops_clean <- sched_stops %>% 
    mutate(arrival = ymd_hms(arrival), departure = ymd_hms(departure),
           timeFeed = ymd_hms(timeFeed), stop_id = substr(stop_id,1,3))
  
  sched_stops_clean$departure[sched_stops_clean$departure<0] <-NA
  sched_stops_clean$arrival[sched_stops_clean$arrival<0] <-NA
  
  sched_stops_clean
  
}

cleanTrainId <-function(trainID){
  trainID %>% 
    mutate(start_date  = ymd(start_date),
           direction = as.factor(direction),
           route_id  = as.factor(route_id))
}

cleanStops <-function(df){
  df %>% filter(nchar(stop_id)==3) %>% 
    mutate(stop_name = as.factor(stop_name) )
}

mergeTables <-function(clean_sched, clean_id, clean_stops){
  clean_sched %>% 
    left_join(clean_id, by = 'full_id') %>% 
    left_join(clean_stops, by = 'stop_id') %>% 
    select(-stop_lat, -stop_lon) %>% 
    mutate(stop_id = as.factor(stop_id), 
           route_plan = as.factor(route_plan))
  
  
}

createFullMergedTable <- function(){
  data <- updateTables()
  #load('temp.Rdata')
  #message("Completed Loading Data")
  
  sched_stops <- cleanSchedStops(data$vw_thin_sched_stops)
  trainids <- cleanTrainId(data$trainID)
  stops <- cleanStops(data$stops)
  
  
  mergeTables(sched_stops,trainids,stops)
  
}

filterTrainIds <-function(clean_trainid, route, dir_interest){
  matched_train_ids <- clean_trainid %>% 
    filter(route_id %in% route, direction == dir_interest) %>% 
    select(full_id)
  
  matched_train_ids$full_id
}

removeOutlierTrainIds <- function(full_table, cutoff){
  ## OUtlier Trains
  outlier_train_ids <- full_table %>% 
    filter(route_id != "") %>% 
    group_by(stop_id, route_id, stop_name)  %>% 
    mutate(ct = n()) %>% 
    group_by(route_id) %>% 
    filter(ct < cutoff*max(ct)) %>% 
    ungroup() %>% select(full_id) %>% distinct()
  
  bad_ids <- outlier_train_ids$full_id
  
  full_table %>% 
    filter(!(full_id %in% bad_ids))
}

getTrainTravelTime <-function(full_df, route, 
                              dir, start_station){
  # Outputs data frame where start_station is the beginning of a trip
  # Negative Travel time indicates previous stops
  # Output includes unconfirmed routes (enroute_conf == 0, filter these out
  # for correct historical data)
  
  trains_interest <- full_df %>% 
    filter(route_id %in% route, direction == dir)

  trip_begin <- trains_interest %>% 
    filter(stop_id == start_station) %>% 
    select(full_id, station_leave_time = departure) 
  
  
  trains_interest %>% 
    inner_join(trip_begin, by='full_id') %>% 
    mutate(time_in_transit = as.numeric(arrival - station_leave_time)) %>% 
    group_by(full_id) %>% 
    arrange(timeFeed, enroute_conf)
  
}



getNextTrainsatStop <-function(enroute_df, sched_stop, clean_trainid, stop_interest, 
                               route, dir_interest, num_trains, 
                               time_start = force_tz(now(),tzone = "UTC")){
  
  
  
  matched_train_ids <-  filterTrainIds(clean_trainid, route, dir_interest)
  
  
  train_ids<- matched_train_ids[matched_train_ids %in% enroute_df$full_id]
  
  sched_stop %>% 
    filter(stop_id == stop_interest,
           full_id %in% train_ids,
           departure > time_start) %>%
    top_n(num_trains,departure)
}
# getNextTrainsatStop(output$enroute_trains, 
#                     clean_sched_stop, clean_trainid, 
#                     "120S", c("1","2"), "S", 5, time_of_interest)

# TODO route ids are not available to the output.
# should there be a merge or should they be calculated from the id?
getTimeBetweenTrains <-function(sched_stop, clean_trainid, stop_interest, 
                                route, dir_interest){
  
  matched_train_ids <- filterTrainIds(clean_trainid, route, dir_interest)
  
  sched_stop %>% 
    filter(enroute_conf != 0,
           stop_id == stop_interest,
           full_id %in% matched_train_ids) %>%
    arrange(departure) %>% 
    mutate(time_between = lead(departure)-departure)
}

getTimeBetweenStations <- function(full_df, route, dir, start_station, end_station){
  trains_interest <- full_df %>% 
    filter(route_id %in% route, direction == dir)
  
  trip_begin <- trains_interest %>% 
    filter(stop_id == start_station) %>% 
    select(full_id, station_leave_time = departure) 
  
  
  trains_interest %>% 
    filter(stop_id %in% c(start_station, end_station)) %>% 
    inner_join(trip_begin, by='full_id') %>% 
    mutate(time_in_transit = as.numeric(arrival - station_leave_time)) %>% 
    group_by(full_id) %>% 
    arrange(timeFeed, enroute_conf)
  
  
  
  
  
}



