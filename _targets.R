# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)
# library(tarchetypes) # Load other packages as needed.

# Set target options:
tar_option_set(
  packages = c("janitor", "tidyverse", "tibble", "ggmap", "readODS") # packages that your targets need to run
  # format = "qs", # Optionally set the default storage format. qs is fast.
  #
  # For distributed computing in tar_make(), supply a {crew} controller
  # as discussed at https://books.ropensci.org/targets/crew.html.
  # Choose a controller that suits your needs. For example, the following
  # sets a controller with 2 workers which will run as local R processes:
  #
  #   controller = crew::crew_controller_local(workers = 2)
  #
  # Alternatively, if you want workers to run on a high-performance computing
  # cluster, select a controller from the {crew.cluster} package. The following
  # example is a controller for Sun Grid Engine (SGE).
  # 
  #   controller = crew.cluster::crew_controller_sge(
  #     workers = 50,
  #     # Many clusters install R as an environment module, and you can load it
  #     # with the script_lines argument. To select a specific verison of R,
  #     # you may need to include a version string, e.g. "module load R/4.3.0".
  #     # Check with your system administrator if you are unsure.
  #     script_lines = "module load R"
  #   )
  #
  # Set other options as needed.
)

# tar_make_clustermq() is an older (pre-{crew}) way to do distributed computing
# in {targets}, and its configuration for your machine is below.
options(clustermq.scheduler = "multicore")

# tar_make_future() is an older (pre-{crew}) way to do distributed computing
# in {targets}, and its configuration for your machine is below.
# Install packages {{future}}, {{future.callr}}, and {{future.batchtools}} to allow use_targets() to configure tar_make_future() options.

# Run the R scripts in the R/ folder with your custom functions:
# tar_source()
# source("other_functions.R") # Source other scripts as needed.

# Replace the target list below with your own:
list(
  tar_target(
    stadia_map,
    get_stadiamap(
      bbox = c(-10, 57.5, 50, 81),
      zoom = 5,
      maptype = "alidade_smooth"
    )
  ),
  tar_target(
    pfas_loqs,
    read_ods("data/Kjemidatabasen_03_2023.ods", sheet = "ORGANIC") %>% clean_names() %>% select(
      sample_id_o = sample_1,
      year = cruise_3,
      station,
      core_id = sample_8,
      sdepth_from = sample_interval_top_bottom,
      sdepth_to = x10,
      longitude = dde,
      latitude = ddn,
      depth = mbsl,
      c(pfosa:pf_te_a)
    ) %>%
      # filter(if_any(all_of(pfases), ~.x != "nr")) %>%
      slice(-1) %>%
      mutate(across(matches("pf"), ~ if_else(str_detect(.x, "<"), str_replace(.x, "<", ""), NA) %>%
        str_replace(",", ".") %>%
        as.numeric())) %>%
      select(sample_id_o, year, matches("pf")) %>%
      pivot_longer(matches("pf"), names_to = "pfas", values_to = "loq") %>%
      group_by(year, pfas) %>% distinct(loq) %>%
      group_by(pfas) %>%
      summarise(
        max_loq = max(loq, na.rm = TRUE)
      )
  )
)
