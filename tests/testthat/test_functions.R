test_that("example_mean works correctly", {
  expect_equal(example_mean(c(1, 2, 3, 4, 5)), 3)
  expect_error(example_mean("not numeric"))
})
