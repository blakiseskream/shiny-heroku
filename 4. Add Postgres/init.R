my_packages = c("httr","RPostgreSQL","devtools")

install_if_missing = function(p) {
  if (p %in% rownames(installed.packages()) == FALSE) {
    install.packages(p)
  }
}

invisible(sapply(my_packages, install_if_missing))
# install pool from Github
invisible(devtools::install_github("rstudio/pool"))
