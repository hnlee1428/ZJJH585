
library(shiny)
library(tidyr)
library(leaflet)
library(tidyverse)

## Extract dataset
basic_url <- "https://data.iowa.gov/resource/m3tr-qhgy.json"
full_url = paste0(basic_url, "?County=Story")


story_info <- jsonlite::read_json(full_url)


new.distinct.names <- story_info %>% 
  purrr::map(.x, 
             .f=~names(rbind.data.frame(rlist::list.flatten(.x),0)))

unlisted <- story_info %>% 
  purrr::map(.f = ~rbind.data.frame(unlist(.x, recursive=T, use.names=T)))

unlisted.info <- purrr::map2(unlisted,
                             new.distinct.names,
                             .f= ~purrr::set_names(.x, .y))

story_df <- do.call(plyr::rbind.fill, unlisted.info)
as.numeric.factor <- function(x) {as.numeric(levels(x))[x]}

story_df$lng <- as.numeric.factor(story_df$store_location.coordinates1)
story_df$lat <- as.numeric.factor(story_df$store_location.coordinates2)
story_df2<- story_df[!is.na(story_df$lng) & !is.na(story_df$lat),]

#leaflet(data = story_new2) %>% addTiles() %>% addMarkers(~lng, ~lat, popup = ~as.character(category_name))


#story_new %>%
#  ungroup() %>%
#  filter(name == "Hy-vee  #2 / Ames") %>%
#  ggplot(aes(x = new_date, y = sale_dollars)) + geom_point()
 
#grp <- story_new %>%
#  filter(name == "Hy-vee  #2 / Ames") %>% nrow()  %>% 
#  group_by(new_date)  %>% summarise(sum = sum(as.numeric.factor(sale_dollars))) 


#grp %>% ggplot(aes(x = ymd(new_date), y = sum)) + geom_point() 




##Work with drink2

readr::parse_number(drink2$`Store Location`)

### Shiny Attempt 1
ui <- fluidPage(
  
  titlePanel("Iowa Liquor Sales"),
  
  sidebarPanel(
    selectInput("city", label = "city", choices = levels(unique(story_df2$city)), selected = "AMES"),
    selectInput("circlesizevar", "Circle Size Variable", choices = c("None"
                                                                     = "none","The total Sales 2012 - 2015" = "Total_Sales","The Total Volume of Alcohol Sold " = "Total_Liters"
    , selected = "None"))
  ),
  
  mainPanel(
    tabsetPanel(
      tabPanel("Cornfield", leafletOutput("map"))
    )
  )
)
##

server <- function(input, output) {
 
  #story_new_subset <- reactive({
   # story_new2 %>%
    #  filter(city == input$city)
  #})
  
  
  
  output$map <- renderLeaflet({
    leaflet(story_df2[story_df2$city == input$city, ]) %>%
      addTiles() %>%
      addMarkers(~lng, ~lat, popup = ~as.character(name))
  })
  
}


###
# Run the application 
shinyApp(ui = ui, server = server)
