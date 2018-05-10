# app.R
library(shiny)
library(RPostgreSQL)
library(pool)


# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("File upload"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      fileInput("file1", "Choose CSV File",
                multiple = FALSE,
                accept = c(
                  "text/csv",
                  "text/comma-separated-values,text/plain",
                  ".csv")
      ),
      actionButton("viewData", label = "View data")
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      tableOutput('postgresTable')
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  postgress.connect <- function() {
    #driver
    drv <- dbDriver("PostgreSQL")
    #attempt connection
    if (Sys.getenv("DATABASE_URL") != "") {
      url <- httr::parse_url(Sys.getenv("DATABASE_URL"))
      pool <- dbPool(drv
                     , host     = url$hostname
                     , port     = url$port
                     , user     = url$user
                     , password = url$password
                     , dbname   = url$path
      )
      print("Heroku application detected connecting to Postgres")
      
    } else {
      print("Setup local connection")
    }
    return(pool)
  }
  
  
  # File upload event listener
  observeEvent(input$file1,{
    # input$file1 will be NULL initially.
    req(input$file1)
    
    # check to make sure an error doesn't occur
    tryCatch({
      df <- read.csv(input$file1$datapath)
      # create connection
      pg <- postgress.connect()
      # remove table if exists
      try(dbRemoveTable(pg, "upload_table"))
      # write a new table
      dbWriteTable(pg, 'upload_table', df, temporary = FALSE)
      # close connection
      pool::poolClose(pg)
    }, error = function(e) {
      # return a safeError if a parsing error occurs
      stop(safeError(e))
    }
    )
  })
  
  # create a reactive object for the database
  pgData <- eventReactive(input$viewData, {
    # create connection
    pg <- postgress.connect()
    # read data
    data <- dbReadTable(pg, 'upload_table')
    # close connection
    pool::poolClose(pg)
    # return data
    return(data)
  })
  
  output$postgresTable <- renderTable({
    pgData()
  })
}

shinyApp(ui = ui, server = server)