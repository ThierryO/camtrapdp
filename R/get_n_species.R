#' Get number of identified species for each deployment
#'
#' Function to get the number of identified species per deployment.
#'
#' @param datapkg a camera trap data package object, as returned by
#'   `read_camtrap_dp()`.
#' @param ... filter predicates for filtering on deployments
#'
#' @importFrom dplyr .data %>% bind_rows count distinct filter group_by mutate
#'   pull select ungroup
#'
#' @export

#' @return a tibble (data.frame) with the following columns:
#'   - `deploymentID`: deployment unique identifier
#'   - `n`: (integer) number of observed and identified species
#'
#' @examples
#'
#' # get number of species
#' get_n_species(mica)
#'
#' # get number of species for deployments with latitude >= 51.18
#' get_n_species(mica, pred_gte("latitude", 51.18))
#'
get_n_species <- function(datapkg, ...) {

  # check input data package
  check_datapkg(datapkg)

  # extract observations and deployments
  observations <- datapkg$observations
  deployments <- datapkg$deployments

  # apply filtering
  deployments <- apply_filter_predicate(
    df = deployments,
    verbose = TRUE,
    ...)

  # get deployments without observations among the filtered deployments
  deployments_no_obs <- get_dep_no_obs(
    datapkg,
    pred_in("deploymentID",deployments$deploymentID)
  )

  # get species detected by each deployment after filtering
  species <-
    observations %>%
    filter(.data$deploymentID %in% deployments$deploymentID) %>%
    distinct(.data$deploymentID, .data$scientificName)

  # get deployments with unidentified observations
  unidentified_obs <-
    species %>%
    filter(is.na(.data$scientificName)) %>%
    pull(.data$deploymentID)

  # get amount of species detected by each deployment
  n_species <-
    species %>%
    group_by(.data$deploymentID) %>%
    count() %>%
    ungroup()

  # remove the count of NA as species and set n as integer
  n_species <- n_species %>%
    mutate(n = ifelse(.data$deploymentID %in% unidentified_obs,
                      as.integer(.data$n - 1),
                      as.integer(.data$n)
    ))

  # set up n = NA (number of species) for deployments without observations
  deployments_no_obs <-
    deployments_no_obs %>%
    select(.data$deploymentID) %>%
    mutate(n = NA_integer_)

  # add them to n_species and return
  n_species %>% bind_rows(deployments_no_obs)
}
