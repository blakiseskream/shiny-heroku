# TODO: To get this to work on Heroku you will need to fill out the info on lines
# 35, set APP_URL to your heroku apps url 
# 40, set key = to the Github application's Client ID
# 41, set secret = to the Github application's Client Secret
# Create a Github OAuth app here https://github.com/settings/applications/new


library(shiny)
library(httr)

RunHerokuApp <- function() {
  # OAuth setup --------------------------------------------------------
  # (1) Most OAuth applications require that you redirect to a fixed and known
  # set of URLs. Many only allow you to redirect to a single URL: if this
  # is the case for, you'll need to create an app for testing with a localhost
  # url, and an app for your deployed app.
  
  if (interactive()) {
    # testing url and token
    options(shiny.port = 8100)
    APP_URL <- "http://localhost:8100/"
    
    # (2) Note that secret is not really secret, and it's fine to include inline
    app <- oauth_app("shiny-local-app",
                     key = "51d46f96810d1fd182a2",
                     secret = "66eec8782825eeb61007dbef32f91afc9c3587aa",
                     redirect_uri = APP_URL
    )
    
  } else {
    
    setwd('/app')
    
    # deployed URL and token
    APP_URL <- "https://my-app-name.herokuapp.com/" # NOTE: SET THIS TO YOUR APP'S URL
    
    # (2) Note that secret is not really secret, and it's fine to include inline
    # NOTE: SET THIS BASED ON YOUR GITHUB APP.
    app <- oauth_app("my-heroku-app", 
                     key = "MY_APP_ID",
                     secret = "MY_SECRET_KEY",
                     redirect_uri = APP_URL
    )
  }
  
  # (3) Here I'm using a canned endpoint, but you can create with oauth_endpoint()
  api <- oauth_endpoints("github")
  
  # (4) Always request the minimal scope needed. For github, an empty scope
  # gives read-only access to public info
  scope <- ""
  
  # Shiny -------------------------------------------------------------------
  
  # Bring in the server.R and ui.R objects
  source('app.R')
  
  has_auth_code <- function(params) {
    # params is a list object containing the parsed URL parameters. Return TRUE if
    # based on these parameters, it looks like auth codes are present that we can
    # use to get an access token. If not, it means we need to go through the OAuth
    # flow.
    return(!is.null(params$code))
  }
  
  # (5) A little-known feature of Shiny is that the UI can be a function, not just
  # objects. You can use this to dynamically render the UI based on the request.
  # We're going to pass this uiFunc, not ui, to shinyApp(). If you're using
  # ui.R/server.R style files, that's fine too--just make this function the last
  # expression in your ui.R file.
  uiFunc <- function(req) {
    
    # (6) Check if HTTPs
    if (!interactive()) {
      if (req$HTTP_X_FORWARDED_PROTO != "https") {
        return("ERROR: Not HTTPS")
      }
    } else {
      print("localhost app, not verifying https")
    }
    
    # (7) Check if token in URL, else redirect
    if (!has_auth_code(parseQueryString(req$QUERY_STRING))) {
      url <- oauth2.0_authorize_url(api, app, scope = scope)
      redirect <- sprintf("location.replace(\"%s\");", url)
      tags$script(HTML(redirect))
    } else {
      
      # (8) Manually create a token (saved to local environment)
      token <<- oauth2.0_token(
        app = app,
        endpoint = api,
        credentials = oauth2.0_access_token(
          api, 
          app, 
          parseQueryString(req$QUERY_STRING)$code
        ),
        cache = FALSE
      )
      
      # (9) Perform a GET request to confirm access
      resp <- GET("https://api.github.com/user", config(token = token))
      stop_for_status(resp) # CRASH APP IF ERROR RETURNED
      
      return(ui) # otherwise return UI
    }
  }
  
  # (10) Note that we're using uiFunc, not ui!
  if (interactive()) {
    
    # run locally
    shinyApp(uiFunc, server)
    
  } else {
    
    # Create a file at the path /tmp/app-initalized
    # This tells nginx that the app is running, and it can now forward traffic to the custom 'port' below
    # If this file is created, nginx will simply wait forever until the app says its running
    file.create("/tmp/app-initialized")
    port <- '/tmp/nginx.socket'
    attr(port, 'mask') <- strtoi("117", 8)
    
    
    # Runs the app in the working directory. By default this will search for an `app.R` file or 
    # a ui.R + server.R file combination
    # In this case the port is now the address to the nginx proxy
    shiny::runApp(
      appDir = shinyApp(uiFunc, server),
      port = port
    )
  }
}

RunHerokuApp()