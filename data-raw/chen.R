library(tidyverse)
devtools::load_all("../../ggseg/")
devtools::load_all(".")

load("data-raw/geobrain_Chencth.Rda")
chenTh <- geobrain_Chencth %>%
  mutate(label = paste(hemi, gsub(" ", "_", aparc), sep = "_"),
         hemi = case_when(hemi == "lh" ~ "left",
                          hemi == "rh" ~ "right"),
         side = ifelse(id %in% c(1:17, 2000:2009), "lateral", "medial"),
         aparc = ifelse(grepl("wall", aparc), NA, aparc),
         atlas = "chenTh") %>%
  rename(region = aparc,
         cluster = aparc2,
         subid = piece) %>%
  select(-group, -meas) %>%
  mutate(
    long = long - min(long),
    lat = lat - min(lat),
    cluster = factor(as.integer(cluster))
  )


# swap medial and lateral of right hemisphere
minMed <- chenTh %>% filter(hemi=="right" & side == "medial") %>% select(long) %>% min
minLat <- chenTh %>% filter(hemi=="right" & side == "lateral") %>% select(long) %>% min
diff <- minLat - minMed
diff <- 4.25 # adjustment for nicer distances

chenTh <- chenTh %>%
  mutate(long = ifelse(hemi=="right" & side == "lateral",
                       long + diff, long),
         long = ifelse(hemi=="right" & side == "medial",
                       long - diff, long))

chenTh <- as_ggseg_atlas(chenTh)
chenTh <- as_brain_atlas(chenTh)
chenTh$palette <- brain_pals$chenTh
usethis::use_data(chenTh, internal = FALSE, overwrite = TRUE, compress = "xz")




load("data-raw/geobrain_ChenArea.Rda")
chenAr <- geobrain_ChenArea %>%
  mutate(label = paste(hemi, gsub(" ", "_", aparc), sep = "_"),
         hemi = case_when(hemi == "lh" ~ "left",
                          hemi == "rh" ~ "right"),
         side = ifelse(id %in% c(1:20, 2000:2020), "lateral", "medial"),
         aparc = ifelse(grepl("wall", aparc), NA, aparc),
         atlas = "chenAr") %>%
  rename(region = aparc,
         cluster = aparc2,
         subid = piece) %>%
  select(-group, -meas, -`as.numeric(id)`) %>%
  mutate(
    long = long - min(long),
    lat = lat - min(lat),
    cluster = factor(as.integer(cluster))
  )


# swap medial and lateral of right hemisphere
minMed <- chenAr %>% filter(hemi=="right" & side == "medial") %>% select(long) %>% min
minLat <- chenAr %>% filter(hemi=="right" & side == "lateral") %>% select(long) %>% min
diff <- minLat - minMed
diff <- 4.25 # adjustment for nicer distances

chenAr <- chenAr %>%
  mutate(long = ifelse(hemi=="right" & side == "lateral",
                       long + diff, long),
         long = ifelse(hemi=="right" & side == "medial",
                       long - diff, long))

chenAr <- as_ggseg_atlas(chenAr)
chenAr <- as_brain_atlas(chenAr)
chenAr$palette <- brain_pals$chenAr
usethis::use_data(chenAr, internal = FALSE, overwrite = TRUE, compress = "xz")



### 3d atlases ####

folder = "data-raw/mesh3d/chen_area/"
mesh = lapply(list.files(folder, pattern="ply", full.names = T, recursive = T),
              geomorph::read.ply, ShowSpecimen = F)

annots = read_csv(paste0(folder, "annot2filename.csv")) %>%
separate(filename, into=c(NA, NA, "roi"), sep="[.]") %>%
 select(-cluster) %>%
  left_join(chenAr %>% unnest(ggseg) %>%
              mutate(annot = as.integer(.cluster)) %>%
              select(region, hemi, label, annot) %>%
              distinct()) %>%
  left_join(as.data.frame(as.list(brain_pals$chenAr)) %>%
              gather(region, colour) %>%
              mutate(region = gsub("[.]", " ", region),
                     region = gsub("motor premotor", "motor-premotor", region)))


ff <- tibble(files = list.files(folder, pattern="ply", full.names = F, recursive = T),
             atlas = "chenAr_3d") %>%
  filter(!grepl("gclust", files)) %>%
  separate(files, sep="[.]", into=c(NA, NA, "roi"), remove = F) %>%
  mutate(surf = case_when(
    grepl("inflated", files) ~ "inflated",
    grepl("white", files) ~ "white",
    grepl("LCBC", files) ~ "LCBC"),
    hemi = case_when(
      grepl("lh", files) ~ "left",
      grepl("rh", files) ~ "right")
  ) %>%
  left_join(annots)


ff$mesh = list(vb=1)
for(i in 1:length(mesh)){
  ff$mesh[[i]] = list(vb=mesh[[i]]$vb,
                      it=mesh[[i]]$it
  )
}
for(i in 1:length(mesh)){
  ff$mesh[[i]] = list(vb=mesh[[i]]$vb,
                      it=mesh[[i]]$it
  )
}

chenAr_3d <- as_ggseg3d_atlas(ff)

ggseg3d(atlas=chenAr_3d)

usethis::use_data(chenAr_3d, overwrite = TRUE, internal = FALSE, compress = "xz")





folder = "data-raw/mesh3d/chen_thickness//"
mesh = lapply(list.files(folder, pattern="ply", full.names = T, recursive = T),
              geomorph::read.ply, ShowSpecimen = F)

annots = read_csv(paste0(folder, "annot2filename.csv")) %>%
  separate(filename, into=c(NA, NA, "roi"), sep="[.]") %>%
  select(-cluster) %>%
  left_join(chenTh %>% unnest(ggseg) %>%
              mutate(annot = as.integer(.cluster)) %>%
              select(region, hemi, label, annot) %>%
              distinct()) %>%
  left_join(as.data.frame(as.list(brain_pals$chenTh)) %>%
              gather(region, colour) %>%
              mutate(region = gsub("[.]", " ", region),
                     region = gsub("motor premotor ", "motor-premotor-", region)))


ff <- tibble(files = list.files(folder, pattern="ply", full.names = F, recursive = T),
             atlas = "chenTh_3d") %>%
  filter(!grepl("gclust", files)) %>%
  separate(files, sep="[.]", into=c(NA, NA, "roi"), remove = F) %>%
  mutate(surf = case_when(
    grepl("inflated", files) ~ "inflated",
    grepl("white", files) ~ "white",
    grepl("LCBC", files) ~ "LCBC"),
    hemi = case_when(
      grepl("lh", files) ~ "left",
      grepl("rh", files) ~ "right")
  ) %>%
  left_join(annots)


ff$mesh = list(vb=1)
for(i in 1:length(mesh)){
  ff$mesh[[i]] = list(vb=mesh[[i]]$vb,
                      it=mesh[[i]]$it
  )
}
for(i in 1:length(mesh)){
  ff$mesh[[i]] = list(vb=mesh[[i]]$vb,
                      it=mesh[[i]]$it
  )
}

chenTh_3d <- as_ggseg3d_atlas(ff)

ggseg3d(atlas=chenTh_3d)

usethis::use_data(chenTh_3d, overwrite = TRUE, internal = FALSE, compress = "xz")
