#' Get Relative Abundance Index (RAI)
#'
#' @name get_rai
#'
#' @description Function to get the RAI (Relative Abundance Index) per
#'   deployment. The RAI is normalized using 100 days deployment activity.
#'
#' @param datapkg a camera trap data package object, as returned by
#'   `read_camtrap_dp()`.
#' @param species a character with scientific names or common names (case
#'   insensitive). If "all" (default), all scientific names are automatically
#'   selected
#' @param sex a character defining the sex class to filter on, e.g. `"female"`
#'   or `c("male", "unknown")`.  If `NULL`, default, all observations of all
#'   sex classes are taken into account.
#' @param life_stage a character vector defining the life stage class to filter on, e.g.
#'   `"adult"` or `c("subadult", "adult")`. If `NULL`, default, all observations
#'   of all life stage classes are taken into account.
#' @param ... filter predicates for filtering on deployments
#'
#' @export

#' @return a tibble (data.frame) with the following columns:
#' - `deploymentID` deployment unique identifier
#' - `scientificName` scientific name
#' - `rai`: relative abundance index
#'
#' @family RAI functions
#'
#' @examples
#' # calculate RAI for all species
#' get_rai(mica) # species = "all" by default, so equivalent of
#' get_rai(mica, species = "all")
#'
#' # selected species
#' get_rai(mica, species = c("Anas platyrhynchos", "Martes foina"))
#'
#' # with vernacular names, even mixing languages
#' get_rai(mica, species = c("mallard", "steenmarter"))
#'
#' # mixed scientific and vernacular names
#' get_rai(mica, species = c("Anas platyrhynchos", "steenmarter"))
#'
#' # species argument is case insensitive
#' get_rai(mica, species = c("ANAS plAtyRhynChOS"))
#'
#' # specify sex
#' get_rai(mica, sex = "female")
#' get_rai(mica, sex = c("female", "unknown"))
#'
#' # specify life stage
#' get_rai(mica, life_stage = "adult")
#' get_rai(mica, life_stage = c("adult", "subadult"))
#'
#' # apply filter(s): deployments with latitude >= 51.18
#' get_rai(mica, pred_gte("latitude", 51.18))
#'
get_rai <- function(datapkg, ...,
                    species = "all",
                    sex = NULL,
                    life_stage = NULL
                    ) {
  get_rai_primitive(datapkg, ...,
                    use = "n_obs",
                    species = species,
                    sex = sex, life_stage = life_stage)
}

#' Get Relative Abundance Index (RAI) based on number of individuals
#'
#' @name get_rai_individuals
#'
#' @description Function to get the RAI (Relative Abundance Index) per
#'   deployment based on number of detected individuals instead of the number of
#'   observations.
#'
#' @param datapkg a camera trap data package object, as returned by
#'   `read_camtrap_dp()`.
#' @param species a character with scientific names or common names (case
#'   insensitive). If "all" (default), all scientific names are automatically
#'   selected
#' @param sex a character defining the sex class to filter on, e.g. `"female"`
#'   or `c("male", "unknown")`.  If `NULL`, default, all observations of all
#'   sex classes are taken into account.
#' @param life_stage a character vector defining the life stage class to filter on, e.g.
#'   `"adult"` or `c("subadult", "adult")`. If `NULL`, default, all observations
#'   of all life stage classes are taken into account.
#' @param ... filter predicates for filtering on deployments
#'
#' @export

#' @return a tibble (data.frame) with the following columns:
#' - `deploymentID` deployment unique identifier
#' - `scientificName` scientific name
#' - `rai`: relative abundance index
#'
#' @family RAI functions
#'
#' @examples
#' # calculate RAI based on number of individuals
#' get_rai_individuals(mica) # species = "all" by default, so equivalent of
#' get_rai_individuals(mica, species = "all")
#'
#' # selected species
#' get_rai_individuals(mica,
#'   species = c("Anas platyrhynchos", "Martes foina")
#' )
#'
#' # with common names, also mixing up languages
#' get_rai_individuals(mica, species = c("mallard", "steenmarter"))
#'
#' # mixed scientific and vernacular names
#' get_rai_individuals(mica, species = c("Anas platyrhynchos", "beech marten"))
#'
#' # species argument is case insensitive
#' get_rai_individuals(mica, species = c("ANAS plAtyRhynChOS"))
#'
#' # specify sex
#' get_rai_individuals(mica, sex = "female")
#' get_rai_individuals(mica, sex = c("female", "unknown"))
#'
#' # specify life stage
#' get_rai_individuals(mica, life_stage = "adult")
#' get_rai_individuals(mica, life_stage = c("adult", "subadult"))
#'
#' # apply filter(s): deployments with latitude >= 51.18
#' get_rai_individuals(mica, pred_gte("latitude", 51.18))
#'
get_rai_individuals <- function(datapkg, ...,
                    species = "all",
                    sex = NULL,
                    life_stage = NULL
) {
  get_rai_primitive(datapkg, ...,
                    use = "n_individuals",
                    species = species,
                    sex = sex, life_stage = life_stage)
}


#' Primitive function for RAI calculation
#'
#' This function is the primitive function behind `get_rai()` and
#' `get_rai_individuals()` to calculate RAI based on number of observations or
#' number of individuals respectivel
#'
#' @param use character, one of:
#' - `"n_obs"`: calculate RAI based on number of observation (standard)
#' - `"n_individuals"`: calculate RAI based on number of individuals
#'
#' @importFrom dplyr .data %>% group_by left_join select summarise ungroup
#'
#' @keywords internal
#'
#' @noRd
#'
#' @return a data.frame (tibble)
get_rai_primitive <- function(datapkg, use, species, sex, life_stage, ...) {
  # check input data package
  check_datapkg(datapkg)

  # define possible feature values
  uses <- c("n_obs", "n_individuals")

  # check use
  check_value(use, uses, "use", null_allowed = FALSE)
  assert_that(length(use) == 1,
              msg = "use must have length 1")

  # get all identified species if species arg is equal to "all"
  if ("all" %in% species) {
    species <- get_species(datapkg)$scientificName
  }
  # check species
  species <- check_species(datapkg, species)

  if (use == "n_obs") {
    # get number of observations
    n_df <- get_n_obs(datapkg, species = species, sex = sex, life_stage = life_stage, ...)
  } else {
    # get number of individuals
    n_df <- get_n_individuals(datapkg,
                              species = species,
                              sex = sex,
                              life_stage = life_stage,
                              ...
                              )
  }

  # extract deployments
  deployments <- datapkg$deployments

  # get deployment duration (effort) in seconds (standard duration in lubridate)
  dep_effort <- get_effort(datapkg, unit = NULL, ...)

  # calculate RAI
  n_df %>%
    left_join(dep_effort,
              by = "deploymentID") %>%
    group_by(.data$deploymentID,
             .data$scientificName) %>%
    summarise(rai = .data$n * 100 / (as.numeric(.data$effort)/24/60/60)) %>%
    ungroup()
}
