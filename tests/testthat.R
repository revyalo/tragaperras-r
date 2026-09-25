library(testthat)
library(tragaperras)

test_path <- if (dir.exists("testthat")) {
  "testthat"
} else {
  file.path("tests", "testthat")
}

test_dir(test_path, reporter = "summary")
