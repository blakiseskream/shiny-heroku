# Add a list of packages you want to install here
# The list, like every list in R, should be comma seperated
# Package names in quotes, e.g. c("lubridate","httr","dplyr")
my_packages = c("httr")


# This is a simple function that will install the packages in the list
install_if_missing = function(p) {
  if (p %in% rownames(installed.packages()) == FALSE) {
    install.packages(p)
  }
}

# run the function
invisible(sapply(my_packages, install_if_missing))