#' Visualize deployments features
#'
#' This function visualizes deployments features such as number of detected
#' species, number of observations and RAI on a dynamic map. The circle size and
#' color are proportional to the mapped feature. Deployments without
#' observations are shown as gray circles and a message is returned.
#'
#' @param datapkg a camera trap data package object, as returned by
#'   `read_camtrap_dp()`.
#' @param feature character, deployment feature to visualize. One of:
#'
#' - `n_species`: number of identified species
#' - `n_obs`: number of observations
#' -  `n_individuals`: number of individuals
#' - `rai`: Relative Abundance Index
#' - `effort`: effort (duration) of the deployment
#'
#' @param species a character with a scientific name. Required for  `rai`,
#'   optional for `n_obs`. Default: `NULL`
#' @param effort_unit time unit to use while visualizing deployment effort
#'   (duration). One of:
#'
#' - `second`
#' - `minute`
#' - `hour`
#' - `day`
#' - `month`
#' - `year`
#' - `NULL` (default) duration objects (e.g. 2594308s (~4.29 weeks)) are shown
#' while hovering and seconds shown in legend
#' @param sex a character defining the sex class to filter on, e.g. `"female"`.
#'   If `NULL`, default, all observations of all sex classes are taken into
#'   account. Optional argument for `n_obs` and `n_individuals`
#' @param life_stage a character vector defining the life stage class to filter on, e.g.
#'   `"adult"` or `c("subadult", "adult")`. If `NULL`, default, all observations
#'   of all life stage classes are taken into account. Optional argument for `n_obs`
#'   and `n_individuals`
#' @param cluster a logical value
#'   indicating whether using the cluster option while visualizing maps.
#'   Default: TRUE
#' @param hover_columns character with the name of the columns to use for
#'   showing location deployment information while hovering the mouse over. One
#'   or more from deployment columns. Use `NULL` to disable hovering. Default
#'   information:
#'
#'   - `n`: number of species, number of observations, RAI or effort (column
#'   created internally by a `get_*()` function)
#'   - `species`: species name(s)
#'   - `start`: start deployment
#'   - `end`: end deployment -
#'   - `deploymentID` deployment unique identifier
#'   - `locationID` location unique identifier
#'   - `locationName` location name
#'   - `latitude`
#'   - `longitude`
#'
#'   See [section Deployment of Camtrap DP
#'   standard](https://tdwg.github.io/camtrap-dp/data/#deployments) for the full
#'   list of columns you can use
#' @param relative_scale a logical indicating whether to use a relative color
#'   and radius scale (`TRUE`) or an absolute scale (`FALSE`). If absolute scale
#'   is used, specify a valid `max_scale`
#' @param max_scale a number indicating the max value used to map color
#'   and radius
#' @param radius_range a vector of length 2 containing the lower and upper limit
#'   of the circle radius. The lower value is used for deployments with zero
#'   feature value, i.e. no observations, no identified species, zero RAI or
#'   zero effort. The upper value is used for the deployment(s) with the highest
#'   feature value (`relative_scale` = `TRUE`) or `max_scale` (`relative_scale`
#'   = `FALSE`). Default: `c(10, 50)`
#' @param ... filter predicates for subsetting deployments
#'
#' @seealso Check documentation about filter predicates: [pred()], [pred_in()], [pred_and()], ...
#' @importFrom assertthat assert_that
#' @importFrom dplyr .data %>% as_tibble bind_rows bind_cols left_join mutate
#'   one_of rename select
#' @importFrom leaflet addControl addLegend addTiles addCircleMarkers
#'   colorNumeric leaflet markerClusterOptions setView
#' @importFrom glue glue
#' @importFrom grDevices rgb
#' @importFrom htmltools HTML tags
#' @importFrom lubridate is.POSIXt
#' @importFrom purrr map2 map
#' @importFrom tidyr unite
#'
#' @export
#'
#' @return a leaflet map
#'
#' @examples
#' \dontrun{
#' # show number of species
#' map_dep(
#'   mica,
#'   "n_species"
#' )
#'
#' # show number of observations  (observations of unidentified species included
#' if any)
#' map_dep(
#'   mica,
#'   "n_obs"
#' )
#'
#' # show number of observations of Anas platyrhynchos
#' map_dep(
#'   mica,
#'   "n_obs",
#'   species = "Anas platyrhynchos"
#' )
#'
#' # show number of observations of subadult individuals of AnasAnas strepera
#' map_dep(
#'   mica,
#'   "n_obs",
#'   species = "Anas strepera",
#'   life_stage = "subadult"
#' )
#'
#' # show number of observations of female or unknown individuals of gadwall
#' map_dep(
#'   mica,
#'   "n_obs",
#'   species = "gadwall",
#'   sex = c("female", "unknown")
#' )
#'
#' # show number of individuals (individuals of unidentified species included if
#' any)
#' map_dep(
#'   mica,
#'   "n_individuals"
#' )
#'
#' # same filters by life stage and sex as for number of observations apply
#' map_dep(
#'   mica,
#'   "n_individuals",
#'   species = "Anas strepera",
#'   sex = "female",
#'   life_stage = "adult"
#' )
#'
#' # show RAI
#' map_dep(
#'   mica,
#'   "rai",
#'   species = "Anas strepera"
#' )
#'
#' # same filters by life_stage and sex as for number of observations apply
#' map_dep(
#'   mica,
#'   "rai",
#'   species = "Anas strepera",
#'   sex = "female",
#'   life_stage = "adult"
#' )
#'
#' # show RAI calculated by using number of detected individuals
#' map_dep(
#'   mica,
#'   "rai_individuals",
#'   species = "Anas strepera"
#' )
#'
#' # same filters by life stage and sex as for basic RAI apply
#' map_dep(
#'   mica,
#'   "rai_individuals",
#'   species = "Anas strepera",
#'   sex = "female",
#'   life_stage = "adult"
#' )
#'
#' # show effort (basic duration in seconds)
#' map_dep(
#'   mica,
#'   "effort"
#' )
#'
#' # show effort (days)
#' map_dep(
#'   mica,
#'   "effort",
#'   effort_unit = "day"
#' )
#'
#' # show effort (months)
#' map_dep(
#'   mica,
#'   "effort",
#'   effort_unit = "month"
#' )
#'
#' # cluster disabled
#' map_dep(mica,
#'   "n_species",
#'   cluster = FALSE
#' )
#'
#' # show only number of observations and location name while hovering
#' map_dep(mica,
#'   "n_obs",
#'   hover_columns = c("locationName", "n")
#' )
#'
#' # use absolute scale for colors and radius
#' map_dep(mica,
#'   "n_species",
#'   relative_scale = FALSE,
#'   max_scale = 4
#' )
#'
#' # change max and min size circles
#' map_dep(
#'   mica,
#'   "n_obs",
#'   radius_range = c(40, 150)
#' )
#' }
map_dep <- function(datapkg,
                    feature,
                    ...,
                    species = NULL,
                    sex = NULL,
                    life_stage = NULL,
                    effort_unit = NULL,
                    cluster = TRUE,
                    hover_columns = c("n", "species", "deploymentID",
                                      "locationID", "locationName",
                                      "latitude", "longitude",
                                      "start", "end"),
                    relative_scale = TRUE,
                    max_scale = NULL,
                    radius_range = c(10, 50)
) {

  # check input data package
  check_datapkg(datapkg)

  # define possible feature values
  features <- c("n_species",
                "n_obs",
                "n_individuals",
                "rai",
                "rai_individuals",
                "effort")

  # check feature
  check_value(feature, features, "feature", null_allowed = FALSE)
  assert_that(length(feature) == 1,
              msg = "feature must have length 1")

  # check effort_unit in combination with feature
  if (!is.null(effort_unit) & feature != "effort") {
    warning(glue("effort_unit argument ignored for feature = {feature}"))
    effort_unit <- NULL
  }

  # check sex and life stage in combination with feature
  if (!is.null(sex) & !feature %in% c("n_obs",
                                      "n_individuals",
                                      "rai",
                                      "rai_individuals")) {
    warning(glue("sex argument ignored for feature = {feature}"))
    sex <- NULL
  }
  if (!is.null(life_stage) & !feature %in% c("n_obs",
                                      "n_individuals",
                                      "rai",
                                      "rai_individuals")) {
    warning(glue("life_stage argument ignored for feature = {feature}"))
    life_stage <- NULL
  }

  # extract observations and deployments
  observations <- datapkg$observations
  deployments <- datapkg$deployments

  # get average lat lon for empyt map without deployments (after filtering)
  avg_lat <- mean(deployments$latitude, na.rm = TRUE)
  avg_lon <- mean(deployments$longitude, na.rm = TRUE)

  # check species in combination with feature and remove from hover in case
  if (is.null(species) | (!is.null(species) & feature %in% c("n_species",
                                                             "effort"))) {
    if (!is.null(species) & feature %in% c("n_species", "effort")) {
      warning(glue("species argument ignored for feature = {feature}"))
      species <- NULL
    }
    hover_columns <- hover_columns[hover_columns != "species"]
  } else {
    # convert species to scientificName in hover_columns
    hover_columns <- replace(hover_columns,
                             hover_columns == "species",
                             "scientificName")
  }

  # check cluster
  assert_that(cluster %in% c(TRUE, FALSE),
              msg = "cluster must be TRUE or FALSE"
  )

  # check hover_columns
  if (!is.null(hover_columns)) {
    # check all hover_columns values are allowed
    possible_hover_columns <- map_dep_prefixes()$info
    possible_hover_columns <-
      possible_hover_columns[!possible_hover_columns %in% features]
    hover_columns <- match.arg(arg = hover_columns,
                               choices = c(possible_hover_columns, "n"),
                               several.ok = TRUE)
    # check all hover_columns are in deployments except scientificName
    not_found_cols <- hover_columns[!hover_columns %in% names(deployments) &
                                      hover_columns != "n" &
                                      hover_columns != "scientificName"]
    n_not_found_cols <- length(not_found_cols)
    if (n_not_found_cols > 0) {
      warning(glue("There are {n_not_found_cols} columns defined in",
                   " hover_columns not found in deployments: {not_found_cols*}",
                   .transformer = collapse_transformer(
                     sep = ", ",
                     last = " and "
                   )
      ))
    }
  }

  # check combination relative_scale and max_scale
  if (relative_scale == FALSE) {
    assert_that(!is.null(max_scale),
                msg = paste("If you use an absolute scale,",
                            "max_scale must be a number, not NULL")
    )
    assert_that(is.numeric(max_scale),
                msg = paste("If you use an absolute scale,",
                            "max_scale must be a number")
    )
  }

  if (relative_scale == TRUE & !is.null(max_scale)) {
    warning("Relative scale used: max_scale value ignored.")
    max_scale <- NULL
  }

  # calculate and get feature values
  if (feature == "n_species") {
    feat_df <- get_n_species(datapkg, ...)
  } else if (feature == "n_obs") {
    feat_df <- get_n_obs(datapkg, species = species, sex = sex, life_stage = life_stage, ...)
  } else if (feature == "n_individuals") {
    feat_df <- get_n_individuals(datapkg,
                                 species = species,
                                 sex = sex,
                                 life_stage = life_stage,
                                 ...)
  } else if (feature == "rai") {
    feat_df <- get_rai(datapkg, species = species, sex = sex, life_stage = life_stage, ...)
    feat_df <- feat_df %>% rename(n = .data$rai)
  } else if (feature == "rai_individuals") {
    feat_df <- get_rai_individuals(datapkg,
                                   species = species,
                                   sex = sex,
                                   life_stage = life_stage, ...)
    feat_df <- feat_df %>% rename(n = .data$rai)
  } else if (feature == "effort") {
    feat_df <- get_effort(datapkg, unit = effort_unit, ...)
    feat_df <- feat_df %>% rename(n = .data$effort)
  }

  # define title legend
  title <- get_legend_title(feature)
  # add unit to legend title (for effort)
  title <- add_unit_to_legend_title(title,
                                    unit = effort_unit,
                                    use_brackets = TRUE)

  # add informative message if no deployments left after applying filters and
  # return empty map
  if (nrow(feat_df) == 0) {
    message("No deployments left.")
    leaflet_map <-
      leaflet(feat_df) %>%
      setView(lng = avg_lon, lat = avg_lat, zoom = 10) %>%
      addTiles() %>%
      addControl(tags$b(title), position = "bottomright")
    return(leaflet_map)
  }

  # add deployment information for maps
  # first, mandatory fields to make maps and join
  deploy_columns_to_add <- c("deploymentID", "latitude", "longitude")
  # second, columns for hovering text
  deploy_columns_to_add <- unique(c(deploy_columns_to_add,
                                    hover_columns[hover_columns != "n" &
                                                    hover_columns != "scientificName"]))
  feat_df <-
    feat_df %>%
    left_join(deployments %>%
                select(one_of(deploy_columns_to_add)),
              by = "deploymentID"
    )

  # add info while hovering
  if (!is.null(hover_columns)) {
    hover_info_df <- get_prefixes(feature, hover_columns)
    ## set n_species or n_obs or rai or rai_individuals or effort to n in hover_info_df
    hover_info_df$info[hover_info_df$info %in% features] <- "n"
    hover_infos <- as_tibble(map2(hover_info_df$prefix,
                                  hover_info_df$info,
                                  function(x,y) {
                                    info <- feat_df[[y]]
                                    if (is.POSIXt(info)) {
                                      info <- format(info)
                                    }
                                    paste0(x, as.character(feat_df[[y]]))
                                  }), .name_repair = "minimal") %>%
      unite(col = "hover_info", sep = "</p><p>")
    hover_infos <-
      hover_infos %>%
      mutate(hover_info = paste0("<p>", .data$hover_info, "</p>"))
    hover_infos$hover_info <- map(hover_infos$hover_info, ~HTML(.))
    feat_df <-
      feat_df %>%
      bind_cols(hover_infos)
  } else {
    feat_df$hover_info <- NA
  }

  # Set upper limit if absolute value is used and it is lower than some values
  if (relative_scale == FALSE) {
    # set all n > max_scale to max_scale
    feat_df <-
      feat_df %>%
      mutate(n = ifelse(.data$n > max_scale,
                        max_scale,
                        .data$n
      ))
  }

  # max number of species/obs (with possible upper limit  `max_absolute_scale`
  # in case absolute scale is used) to set number of ticks in legend
  max_n <- ifelse(is.null(max_scale),
                  ifelse(!all(is.na(feat_df$n)),
                         max(feat_df$n, na.rm = TRUE),
                         0),
                  max_scale
  )

  # define color palette
  palette_colors <- c("white", "blue")
  pal <- colorNumeric(
    palette = palette_colors,
    domain = c(0, max_n)
  )
  # remove NA color to legend until this issue is solved:
  # https://github.com/rstudio/leaflet/issues/615
  pal_without_na <- colorNumeric(
    palette = palette_colors,
    domain = c(0, max_n),
    na.color = rgb(0, 0, 0, 0)
  )

  # define bins for ticks of legend
  # bins <- ifelse(max_n < 6, as.integer(max_n) + 1, 6)
  bins <- 6

  # define size scale for avoiding too small or too big circles
  radius_max <- radius_range[2]
  radius_min <- radius_range[1]
  if (max_n != 0) {
    conv_factor <- (radius_max - radius_min)/max_n
  } else {
    conv_factor <- 0
  }

  # define legend values
  legend_values <- seq(from = 0, to = max_n, length.out = bins)

  # make basic start map
  leaflet_map <-
    leaflet(feat_df) %>%
    addTiles()

  leaflet_map %>%
    addCircleMarkers(
      lng = ~longitude,
      lat = ~latitude,
      radius = ~ ifelse(is.na(n), radius_min, n * conv_factor + radius_min),
      color = ~ pal(n),
      stroke = FALSE,
      fillOpacity = 0.5,
      label = ~hover_info,
      clusterOptions = if (cluster == TRUE) markerClusterOptions() else NULL
    ) %>%
    addLegend("bottomright",
              pal = pal_without_na,
              values = legend_values,
              title = title,
              opacity = 1,
              bins = bins,
              na.label = "",
              labFormat = labelFormat_scale(
                max_scale = max_scale
              )
    )
}
