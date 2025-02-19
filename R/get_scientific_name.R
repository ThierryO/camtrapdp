#' Get scientific name based on its input_vernacular name
#'
#' This function returns the scientific name(s) of a vector of input_vernacular
#' names based on the taxonomic information in metadata slot `taxonomic` of the
#' given  camera trap data package.
#' 
#' The match is performed case insensitively.
#' 
#' If a vernacular name is not valid, an error is returned
#'
#' @param datapkg a camera trap data package object, as returned by
#'   `read_camtrap_dp()`.
#' @param vernacular_name a character vector with input vernacular name(s)
#'
#' @importFrom dplyr .data %>% across filter if_any mutate pull starts_with
#' @importFrom glue glue
#' @importFrom purrr map_chr
#'
#' @export
#'
#' @return a character vector of scientific name(s)
#'
#' @examples
#' # one or more vernacular names
#' get_scientific_name(mica, "beech marten")
#' get_scientific_name(mica, c("beech marten", "mallard"))
#' # vernacular names can be passed in different languages 
#' get_scientific_name(mica, c("beech marten", "wilde eend"))
#' # the search is performed case insensitively
#' get_scientific_name(mica, c("MaLLarD"))
#' # error is returned if at least one invalid vernacular name is passed
#' \dontrun{
#' get_scientfic_name(mica, "this is a bad vernacular name")
#' # a scientific name is an invalid vernacular name of course
#' get_scientific_name(mica, c("Castor fiber", "wilde eend"))
#' }
get_scientific_name <- function(datapkg, vernacular_name) {

  all_sn_vn <- get_species(datapkg) # datapkg check happens in get_species

  # get vernacular names for check
  all_vn <- 
    all_sn_vn %>%
    select(starts_with("vernacularName"))
  # check validity verncular_name argument
  check_value(arg = tolower(vernacular_name), 
              options = unlist(all_vn) %>% tolower(), 
              arg_name = "vernacular_name", null_allowed = FALSE)
  
  input_vernacular <- vernacular_name

  all_sn_vn <-
    all_sn_vn %>%
    mutate(across(starts_with("vernacularName"), ~ tolower(.)))
  
  map_chr(
    input_vernacular, 
    function(v) {
      # search within the columns with vernacular names
      sc_n <- 
        all_sn_vn %>%
        filter(if_any(starts_with("vernacularName"),
                      ~ tolower(.) %in% tolower(v))) %>%
        pull(.data$scientificName)
      if (length(sc_n) == 0) {
        message(glue("{v} is not a valid vernacular name."))
        sc_n <- NA_character_
      }
      sc_n
    })
}
