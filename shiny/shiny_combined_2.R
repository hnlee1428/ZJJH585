
library(shiny)
library(tidyr)
library(mapview)
library(leaflet)
library(plotly)
library(lubridate)
library(tidyverse)



## Extract dataset from the website 

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


## Create dataset for time series 
story_df_new <- story_df %>% 
  mutate(new_date = gsub("T.*","", date),
         year=year(new_date),
         month=month(new_date),
         day=day(new_date)) 



story_df_new1 <- story_df_new %>% 
  group_by(name, year, month) %>% 
  summarise(sale_sum = sum(as.numeric(sale_dollars)))

story_total2 <- story_df2 %>% group_by(name, city, lng, lat) %>% summarise(Total_Sales_Dollars = sum(as.numeric(sale_dollars))) 


##Remove NAs

story_df2<- story_df[!is.na(story_df$lng) & !is.na(story_df$lat),]


### Categorize sales


story_total2 <- story_total2 %>%
  mutate(Total_Sales = ifelse(Total_Sales_Dollars < 5000, "Less than 5000",
                                        ifelse(Total_Sales_Dollars >= 5000 & Total_Sales_Dollars <= 10000, "5000 ~ 10,000",
                                               ifelse(Total_Sales_Dollars > 10000 & Total_Sales_Dollars < 30000, "10,000 ~ 30,000",
                                                       ifelse(Total_Sales_Dollars >= 30000 & Total_Sales_Dollars <= 60000, "30,000 ~ 60,000", NA)))))

## Reorder the levels
story_total2$Total_Sales <- factor(story_total2$Total_Sales, levels = c("Less than 5000", "5000 ~ 10,000", "10,000 ~ 30,000","30,000 ~ 60,000"))


##### Shiny starts here!

ui <- fluidPage(
  titlePanel("Story County Liquor Sales"),
  mainPanel(
    tabsetPanel(
      tabPanel("Liquor Sales Map",  sidebarPanel(
        selectInput("city", label = "City", choices = levels(unique(story_df2$city)), selected = "AMES")
        , selectInput("Total_Sales", "Total Sales in Dollars(2012-2015)", choices = levels(as.factor(story_total2$Total_Sales)), selected = "Less than 30000")),
        
        mainPanel(
          fluidRow( 
            leafletOutput("map"))
        )), 
      tabPanel("Liquor Sales Trend Analysis ",
               # Sidebar layout with input and output
               sidebarLayout(
                 
                 # Sidebar Panel for inputs
                 sidebarPanel(
                   
                   helpText("Create Bar Plot for Time vs. Stores' Sale."),
                   
                   # Input: Select for choosing dataset
                   selectInput("Stores",
                               label = "Stores",
                               choices = levels(story_df_new1$name),
                               selected = "Cyclone Liquors"),
                   
                   selectInput("Year", 
                               label = "Year",
                               choices = levels(as.factor(story_df_new1$year)),
                               selected = NULL),
                   
                   selectInput("Month",
                               label = "Month",
                               choices = levels(as.factor(story_df_new1$month)),
                               selected = NULL)),
                 mainPanel(
                   fluidRow( 
                     plotlyOutput("storePlot"),
                     plotlyOutput("storePlot2")
                   )
                 )
               )
      )) 
  )
)
  
  
  
 
  
  
  
server <- function(input, output) {
  
  story_df2_subset <- reactive({
    story_df2 %>%
      filter(city == input$city)
  })

  story_total2_subset <- reactive({
    story_total2 %>%
      filter(Total_Sales == input$Total_Sales)
  })
  
  output$map <- renderLeaflet({
    
    validate(need(!is.na(input$city), "Zipcode must not be NA. Please enter a zip code"))
    validate(need(!is.na(input$Total_Sales), "Distance must not be NA. Please enter a valid distance"))
    
    data <- story_total2 %>% filter(city == input$city, Total_Sales == input$Total_Sales)
  
    leaflet(data = data) %>%
      addTiles() %>%
      addMarkers(~ lng,
                 ~ lat,
                 popup = ~ as.character(name))
  })
    
  
  

  output$storePlot <- renderPlotly({
      story_df_new1 %>% filter(name == input$Stores, year == input$Year) %>%
      mutate(month = factor(month)) %>%
      ggplot(aes(x = month, y = sale_sum))+geom_col(colour="black", fill="#DD8888")
    
  }
  ) 
  
  
  output$storePlot2 <- renderPlotly({
    
    story_df_new %>% filter(name == input$Stores, year == input$Year, month == input$Month) %>%
      mutate(day = as.factor(day), month = as.factor(month), year = as.factor(year), sale_dollars = as.numeric(sale_dollars)) %>%
      ggplot(aes(x = day, y = sale_dollars)) + geom_col(colour = "black", fill = "#7fcdbb")
    
    
  })
}
  
  
  

# Run the application 
shinyApp(ui = ui, server = server)



