# useful pfas fns
# (c) Are Sæle Bruvold 2024
# obabel documentation: https://www.mankier.com/1/obabel

## pcprop
pcprop_from_name <-
  function(in_name,
           property = c(
             "XLogP",
             "CanonicalSMILES",
             "MolecularFormula",
             "MolecularWeight",
             "ExactMass",
             "TPSA",
             "HeavyAtomCount",
             "Charge",
             "InChI"
           )) {
    in_name <- str_replace_all(in_name, " ", "%20")
    
    if (length(property) == 1) {
      if (property == "all") {
        property <-
          c(
            "XLogP",
            "CanonicalSMILES",
            "MolecularFormula",
            "MolecularWeight",
            "ExactMass",
            "TPSA",
            "HeavyAtomCount",
            "Charge",
            "InChI"
          )
      }
      else {
        out_type = "/TXT"
      }
    }
    
    if (length(property) > 1) {
      out_type = "/CSV"
    }
    
    out <- system(
      paste0(
        "curl https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/",
        in_name,
        "/property/",
        str_c(property, collapse = ","),
        out_type
      ),
      intern = TRUE,
      ignore.stderr = TRUE
    )
    # remember max 5 requests per second api limitation of pubchem
    Sys.sleep(0.2)
    
    if (length(property) == 1) {
      out <- out %>% as_tibble() %>% rename_with( ~ property, 1)
    } else {
      out <- read.csv(text = out)
    }
    return(out)
  }

# retrieve all obprop information
obprop_retriever <- function(in_structure) {
  # create temporary file and send to obprop
  with_tempfile("temp_file.mol",
                {
                  write_lines(in_structure, file = temp_file.mol)
                  system(paste("obprop", temp_file.mol),
                         intern = TRUE,
                         ignore.stderr = TRUE)
                }, fileext = ".mol") %>%
    strsplit("\\s{1,}") %>%
    #remove list elements with only one vector element:
    keep(~ length(.x) > 1) %>%
    #quasiquation and walrus operator to assign name
    map(~ tibble(!!.x[1] := .x[2])) %>% bind_cols() %>%
    select(-1) %>%
    #convert all columns not containing letters to numeric:
    mutate(across(-matches("[a-zA-Z]"), as.numeric))
}

## structure drawer
structure_drawer_smiles <- function(smiles, outdir) {
  # check if input
  if (smiles == "" | is.na(smiles)) {
    warning("no smiles detected.")
  }# to ensure ending outdir with /
  if (str_detect(outdir, "/$") == FALSE) {
    outdir <- paste0(outdir, "/")
  }
  
  map2(smiles,
       outdir,
       ~ system(
         paste0("obabel ", "'-:", .x, "'", " -O ", .y, "'", .x, "'", ".svg"),
         intern = FALSE,
         ignore.stderr = FALSE
       ))
}


## To generate docx from gt html table, pandoc can be used:
# pandoc test2.html -o test3.docx

## To resize images in docx, a lua-filter can be applied. Otherwise, it may be changed in word using the following VB macro:
# Dim i As Long
# With ActiveDocument
# For i = 1 To .InlineShapes.Count
# With .InlineShapes(i)
# .LockAspectRatio = msoTrue
# 'set either the width or the height and delete the line you don't need
# .Width = CentimetersToPoints(5)
# .Height = CentimetersToPoints(5)
# End With
# Next i
# End With


## Make obprop extracter from molfile.
