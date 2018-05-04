#
# run.R
# shiny-heroku
#
# Created by blakiseskream on 5/5/2018
# MIT License and shit
#

library(shiny)
library(httr)

RunDawnstar <- function() {
  # OAuth setup --------------------------------------------------------
  
  # Most OAuth applications require that you redirect to a fixed and known
  # set of URLs. Many only allow you to redirect to a single URL: if this
  # is the case for, you'll need to create an app for testing with a localhost
  # url, and an app for your deployed app.
  
  if (interactive()) {
    # testing url
    source("environment.R", local = TRUE)
    source("server.R", local = TRUE)
    source("ui.r", local = TRUE)
    APP_URL <- "http://localhost:8100/"
    
  } else {
    
    # deployed URL
    setwd("/app")
    source("server.R", local = TRUE)
    source("ui.r", local = TRUE)
    APP_URL <- Sys.getenv("APP_URL")
  }
  
  # Note that secret is not really secret, and it's fine to include inline
  
  # SALESFORCE
  # TODO: MOVE TO ENIVORNMENT VARIABLES
  sfdcId <- Sys.getenv("APP_ID")
  sfdcSecret <- Sys.getenv("CLIENT_SECRET")
  
  app <- oauth_app("sfdc-dawnstar",
                   key = sfdcId,
                   secret = sfdcSecret,
                   redirect_uri = APP_URL
  )
  
  # Here I'm using a canned endpoint, but you can create with oauth_endpoint()
  sfdcAPI <- oauth_endpoint(
      authorize = "https://login.salesforce.com/services/oauth2/authorize"
    , access    = "https://login.salesforce.com/services/oauth2/token"
  )
  
  # Always request the minimal scope needed. For github, an empty scope
  # gives read-only access to public info
  #scope <- "https://www.googleapis.com/auth/userinfo.profile"
  scope <- "id"
  
  # Shiny -------------------------------------------------------------------
  
  has_auth_code <- function(params) {
    # params is a list object containing the parsed URL parameters. Return TRUE if
    # based on these parameters, it looks like auth codes are present that we can
    # use to get an access token. If not, it means we need to go through the OAuth
    # flow.
    return(!is.null(params$code))
  }
  
  # A little-known feature of Shiny is that the UI can be a function, not just
  # objects. You can use this to dynamically render the UI based on the request.
  # We're going to pass this uiFunc, not ui, to shinyApp(). If you're using
  # ui.R/server.R style files, that's fine too--just make this function the last
  # expression in your ui.R file.
  uiFunc <- function(req) {
    
    # Check if HTTPs
    if (!interactive()) {
      if (req$HTTP_X_FORWARDED_PROTO != "https") {
        redirect <- sprintf("location.replace(\"%s\");", APP_URL)
        tags$script(HTML(redirect)) # redirect if it isn't
      }
    } else {
      print("localhost app, not verifying https")
    }
    
    # Check if token in URL, else redirect
    if (!has_auth_code(parseQueryString(req$QUERY_STRING))) {
      url <- oauth2.0_authorize_url(sfdcAPI, app, scope = scope)
      redirect <- sprintf("location.replace(\"%s\");", url)
      tags$script(HTML(redirect))
    } else {
      
      # Manually create a token (saved to local environment)
      token <<- oauth2.0_token(
        app = app,
        endpoint = sfdcAPI,
        credentials = oauth2.0_access_token(
          sfdcAPI, 
          app, 
          parseQueryString(req$QUERY_STRING)$code
        ),
        cache = FALSE
      )
      
      # Perform a GET request to confirm access
      sfdUserInfo <- "https://login.salesforce.com/services/oauth2/userinfo"
      resp <- GET(sfdUserInfo, config(token = token))
      stop_for_status(resp) # CRASH APP IF ERROR RETURNED
      json <- jsonlite::fromJSON(content(resp, "text") ,simplifyDataFrame = FALSE)
      if(json$organization_id %in% jsonlite::fromJSON(Sys.getenv("ORG_ID"))) {
        return(ui)
      } else {
        span(paste("Unauthorized", json$organization_id))
      }
    }
  }
  
  
  # Note that we're using uiFunc, not ui!
  if (interactive()) {
    
    # run locally
    options(shiny.port = 8100)
    shinyApp(uiFunc, server)
    
  } else {
    print("run.R runApp about to start")
    
    # run on heroku w/ nginx
    file.create("/tmp/app-initialized")
    port <- '/tmp/nginx.socket'
    attr(port, 'mask') <- strtoi("117", 8)
    
    shiny::runApp(
      appDir = shinyApp(uiFunc, server),
      port = port
    )
  }
}

# Run it
RunDawnstar()
