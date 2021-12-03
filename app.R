#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(RSQLite)
library( leaflet )    
library( shinydashboard )
library(sp)       # for spatial objects
library(dplyr)    # for working with data frames
library(ggplot2)
library(tidyr)
library(stringr)
library("maps")
library('sf')
setwd('C:/Users/Wei Jia/Documents/BE8093/project/covid_19/')
db <- dbConnect(RSQLite::SQLite(), dbname = "covid_19.db")


# Define UI for application that draws a histogram
vac_lab = c("Total Cases" = "tot_cases",
  "Total Death" = "tot_death",
  "Total Fully Vaccinated" = "total_vac",
  "New Cases by Month" = "new_case",
  "New Death by Month" = "new_death"
)
ui <- fluidPage(
  titlePanel("Covid-19 App"),
  
tabsetPanel(
  tabPanel('Cases and Death',
  sidebarLayout(
    sidebarPanel(
      helpText("Observe Covid-19 Cases and Death by States."),

      selectInput("var", 
                  label = "Choose a variable to display",
                  choices = c('Cases' ,'Death'),
                  selected = 'Cases'),

      
      sliderInput("range", 
                  label = "Time Range of interest:",
                  min = as.Date(toString(dbGetQuery(conn=db, statement = 'select min(submission_date) from Cases'))), 
                  max = as.Date(toString(dbGetQuery(conn=db, statement = 'select max(submission_date) from Cases'))),
                  value = c(as.Date(toString(dbGetQuery(conn=db, statement = 'select min(submission_date) from Cases'))),
                            as.Date(toString(dbGetQuery(conn=db, statement = 'select max(submission_date) from Cases')))))

          ),

    

    mainPanel(leaflet::leafletOutput( outputId = "myMap"
                                      , height = 500)
    )
    )
  ),
  tabPanel('Vaccination',
           sidebarLayout(
             sidebarPanel(
               helpText("Vaccinations informations by states."),
               

               sliderInput("range2", 
                           label = "Range of interest:",
                           min = as.Date(toString(dbGetQuery(conn=db, statement = 'select min(date) from Vaccination'))), 
                           max = as.Date(toString(dbGetQuery(conn=db, statement = 'select max(date) from Vaccination'))),
                           value = c(
                                     as.Date(toString(dbGetQuery(conn=db, statement = 'select max(date) from Vaccination')))))
               
             ),
             
             
             
             mainPanel(leaflet::leafletOutput( outputId = "myMap_vac"
                                               , height = 500),
             helpText("Note: Lack Data for Texas.")
             )
           )
           ),
  tabPanel('Plot',
           sidebarLayout(
             sidebarPanel(
               selectInput('select', 'Select State:', 
                           as.list(dbGetQuery(conn=db, statement = 'select distinct state from Cases order by state'))
                 
               ),
               checkboxGroupInput('opt', 'Select plot options:',
                                  vac_lab)
             )
           ,
           mainPanel(plotOutput('myplot')
                     )
           )
  )
)
)

# Define server logic required to draw a histogram
server <- function(input, output) {



  # create foundational map
  foundational.map <- reactive({
    cases_data = dbGetQuery(conn=db, statement = paste("select a.state, a.tot_cases-b.tot_cases as cases,
    lower(c.name) as ID, 
    c.population, (a.tot_cases-b.tot_cases)/c.population as pop from (
      select state, tot_cases from Cases
      where submission_date =",input$range[2],
      ") a
      join (
      select state, tot_cases from Cases
      where submission_date = ",input$range[1],
      ") b on a.state=b.state
      join geo_states c on a.state = c.abv
      order by c.name ", sep="'"))
    death_data = dbGetQuery(conn=db, statement = paste("select a.state, a.tot_death-b.tot_death as cases,
    lower(c.name) as ID,
    c.population, (a.tot_death-b.tot_death)/c.population as pop from (
      select state, tot_death from Cases
      where submission_date =",input$range[2],
                                                       ") a
      join (
      select state, tot_death from Cases
      where submission_date = ",input$range[1],
                                                       ") b on a.state=b.state
      join geo_states c on a.state = c.abv
      order by c.name ", sep="'"))
    vac_data = dbGetQuery(conn=db, statement = paste("select lower(b.name) as ID, sum(a.Series_Complete_Yes) as vac, b.population, round(100*cast(sum(a.Series_Complete_Yes) as float)/cast(b.population as float), 4) as cases from Vaccination a
join geo_states b on a.Recip_State = b.abv
where date = ", input$range[2], 
"group by Recip_State", sep="'")
      
    )
    data_ = switch(input$var,
                   'Cases'=cases_data,
                   'Death'=death_data,
                   'Vaccinations'=vac_data)
    
    states <- st_as_sf(map("state", plot = FALSE, fill = TRUE))
    
    states <- inner_join(states, data_, by = c('ID'))
    
    popup <- paste0(str_to_title(states$ID), ":<br>", "Confirmed cases: ", cases_data$cases, "<br>", "Confirmed death: ", 
                    death_data$cases, "<br>", "Fully vaccinated:", vac_data$vac)
    pal <- switch(input$var,
                'Cases' = colorNumeric(
      palette = "YlOrRd",
      domain = states$cases
    ),
    'Death'=colorNumeric(
      palette = "Blues",
      domain = states$cases
      ),
    'Vaccinations'=colorNumeric(
      palette = "Greens",
      domain = states$cases
    )
    )
    leaflet() %>%
      addTiles( urlTemplate = "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png") %>%
      setView( lng = -95.7129
               , lat = 37.0902
               , zoom = 4 ) %>%
      addPolygons( data = states,
                   fillColor = ~pal(cases), 
                   color = "#b2aeae", # you need to use hex colors
                   fillOpacity = 0.7, 
                   weight = 0.8, 
                   smoothFactor = 0.2,
                   popup = popup
      )

})
  
  output$myMap <- renderLeaflet({
    
    foundational.map()
    
  }) # end of leaflet::renderLeaflet({})
  # create foundational map
  foundational_map_vac <- reactive({

    vac_data = dbGetQuery(conn=db, statement = paste("select lower(b.name) as ID, cast(sum(a.Series_Complete_Yes) as float) as vac, b.population, round(100*cast(sum(a.Series_Complete_Yes) as float)/cast(b.population as float), 4) as cases from Vaccination a
join geo_states b on a.Recip_State = b.abv
where date = ", input$range2, 
                                                     "group by Recip_State", sep="'")
                          
    )
    data_ = vac_data
    
    states <- st_as_sf(map("state", plot = FALSE, fill = TRUE))
    
    states <- inner_join(states, data_, by = c('ID'))
    
    popup <- paste0(states$ID, "fully vaccinated:", states$vac)
    pal =colorBin(
                    palette = "Greens",
                    domain = states$cases,
#                    reverse = TRUE,
                    pretty = TRUE
                  )

    leaflet() %>%
      addTiles( urlTemplate = "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png") %>%
      setView( lng = -95.7129
               , lat = 37.0902
               , zoom = 4 ) %>%
      addPolygons( data = states,
                   fillColor = ~pal(cases), 
                   color = "#b2aeae", # you need to use hex colors
                   fillOpacity = 0.7, 
                   weight = 0.8, 
                   smoothFactor = 0.5,
                   popup = popup
      )
    
  })
  
  output$myMap_vac <- renderLeaflet({
    
    foundational_map_vac()
    
  }) # en
  data_plot = dbGetQuery(conn=db, statement = "select a.state, strftime('%Y-%m', a.submission_date) as Month, sum(a.new_case) as new_case, sum(a.new_death) as new_death, b.total_vac, f.tot_cases, f.tot_death, b.population from Cases a
left join(
select a.state, a.Month, sum(b.Series_Complete_Yes) as total_vac, c.population from(
SELECT recip_state as state, max(date) as max_date, strftime('%Y-%m', Date) as Month from Vaccination a 
where Month is NOT NULL
group by recip_state, Month
) a
join vaccination b on a.state=b.recip_state and a.max_date = b.date
left join geo_states c on a.state = c.abv
group by a.state,a.Month
) b on a.state = b.state and strftime('%Y-%m', a.submission_date) = b.month
join (
select b.state, b.month, c.tot_cases, c.tot_death from cases c
join (
select a.state, strftime('%Y-%m', a.submission_date) as Month, max(a.submission_date) as max_date from Cases a
where strftime('%Y-%m', a.submission_date) is not null
group by a.state, strftime('%Y-%m', a.submission_date)
) b on c.submission_date = b.max_date and c.state = b.state
order by b.state, b.month
) f on a.state = f.state and strftime('%Y-%m', a.submission_date) = f.month
where strftime('%Y-%m', submission_date) is not null
group by a.state, strftime('%Y-%m', submission_date)")

  data_st = reactive({data_plot[which(data_plot$state==input$select), c('state', 'Month',input$opt)]})
  data_st_long = reactive({gather_(data_st(), 'option', 'value', input$opt)})

  output$myplot = renderPlot({
    if(is.null(data_st_long()$Month)){
      ggplot()
    }else{
    ggplot(data = data_st_long(), aes(x=Month,y=value, colour=option, group=option)) + geom_point() + geom_line() + scale_color_hue(label=names(vac_lab[which(vac_lab %in% input$opt)]))
    }
  })

}
# Run the application 
shinyApp(ui = ui, server = server)
