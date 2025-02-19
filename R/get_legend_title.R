#' Get legend title table
#'
#' Store legend titles for deployment visualizations: RAI, effort, number of
#' observations, etc.
#'
#' Returns a data.frame of all titles with the following columns: - `feature`:
#' deployment feature to visualize - `legend_title`: legend title
#'
#' @importFrom dplyr as_tibble
#'
#' @noRd
#'
#' @usage map_legend_title()
#'
#' @keywords internal
map_legend_title <- function() as_tibble(mapdep_legend_titles)

mapdep_legend_titles <- structure(list(
  feature = c(
    "n_species",
    "n_obs",
    "n_individuals",
    "rai",
    "rai_individuals",
    "effort"
  ),
  legend_title = c(
    "Number of detected species",
    "Number of observations",
    "Number of individuals",
    "RAI",
    "RAI (individuals)",
    "Effort"
  )
))

#' Retrieve legend title for deployment visualizations
#'
#' @param feature character, one of:
#'
#' - `n_species`
#' - `n_obs`
#' - `rai`
#' - `effort`
#'
#' @importFrom dplyr .data %>% filter
#'
#' @noRd
#'
#' @keywords internal
get_legend_title <- function(feat) {
  # get all legend titles
  titles <- map_legend_title()
  # return the legend title we need
  titles %>%
    filter(.data$feature == feat) %>%
    pull(.data$legend_title)
}


#' Add unit to legend title
#'
#' This function is useful when a unit (e.g. temporal unit) should be added to
#' legend title
#'
#' @param title a character with legend title
#' @param unit character with unit to add to `title`
#' @param use_brackets logical. If `TRUE` (default) `unit` is wrapped between
#'   brackets, e.g. `(days)`.
#'
#' @noRd
#'
#' @usage map_legend_title("My title", unit = "day", use_bracket = TRUE)
#'
#' @keywords internal
add_unit_to_legend_title <- function(title,
                                     unit = NULL,
                                     use_brackets = TRUE) {
  if (is.null(unit)) {
    title
  } else {
    if (use_brackets == TRUE) {
      unit <- paste0("(", unit, ")")
    }
    paste(title, unit)
  }
}
