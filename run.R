#
# run.R
# shiny-heroku
#
# Created by blakiseskream on 5/7/2018
# MIT License and shit
#

# simple run.R
library(shiny)

# Gets the port # from Heroku
port <- Sys.getenv('PORT')

# Runs the app in the working directory. By default this will search for an `app.R` file or 
# a ui.R + server.R file combination
# The host of 0.0.0.0 indicates the app runs at the web server's ip address

rmarkdown::run(
    'tutorial.Rmd'
  , shiny_args = list(
      host = '0.0.0.0',
      port = as.numeric(port)
  )
)

# shiny::runApp(
#   appDir = getwd(),
#   host = '0.0.0.0',
#   port = as.numeric(port)
# )