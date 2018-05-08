#
# init.R
# shiny-heroku
#
# Created by blakiseskream on 5/7/2018
# MIT License and shit
#

my_packages = c("rmarkdown")

install_if_missing = function(p) {
  if (p %in% rownames(installed.packages()) == FALSE) {
    install.packages(p)
  }
}

invisible(sapply(my_packages, install_if_missing))