.PHONY: install-deps test report run check

install-deps:
	Rscript -e 'install.packages(c("shiny", "ggplot2", "testthat", "knitr", "rmarkdown"), repos = "https://cloud.r-project.org")'

test:
	R CMD INSTALL .
	Rscript tests/testthat.R

report:
	Rscript -e 'dir.create("analysis/figures", recursive = TRUE, showWarnings = FALSE); knitr::knit("analysis/report.Rmd", "analysis/report.md")'

run:
	Rscript -e 'shiny::runApp(".", launch.browser = TRUE)'

check:
	R CMD build .
	R CMD check --no-manual tragaperras_2.0.0.tar.gz
