# Eksport Cash Usage Database (xlsx) do plików strony: data/cud.json, data/cash_usage_database.csv,
# data/cash_usage_database.xlsx.
# Użycie:  Rscript eksport_danych.R ../RRRRMMDD_Cash\ Usage\ Database.xlsx
# Bez argumentu bierze najnowszy plik *_Cash Usage Database.xlsx z katalogu nadrzędnego.

suppressPackageStartupMessages({
  library(openxlsx)
  library(jsonlite)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 1) {
  src <- args[1]
} else {
  cand <- list.files("..", pattern = "^[0-9]{8}_Cash Usage Database\\.xlsx$", full.names = TRUE)
  if (!length(cand)) stop("Brak pliku RRRRMMDD_Cash Usage Database.xlsx w katalogu nadrzędnym")
  src <- sort(cand, decreasing = TRUE)[1]
}
stamp <- regmatches(basename(src), regexpr("^[0-9]{8}", basename(src)))
updated <- format(as.Date(stamp, "%Y%m%d"), "%Y-%m-%d")
message("Źródło: ", src, " (", updated, ")")

d <- read.xlsx(src, sheet = "Cash Usage Database")
need <- c("ISO2", "country_name", "study_year", "cash_usage_volume", "cash_usage_value",
          "institution", "source", "source_link")
stopifnot(all(need %in% names(d)))

# openxlsx zwraca tekst z encjami XML/HTML (np. "T&#252;rkiye", "&amp;") – dekodujemy.
unent <- function(x) {
  vapply(x, function(s) {
    if (is.na(s)) return(NA_character_)
    s <- sub('^xml:space="preserve">', "", s)
    m <- gregexpr("&#([0-9]+);", s)
    regmatches(s, m) <- lapply(regmatches(s, m), function(e)
      vapply(as.integer(sub("&#([0-9]+);", "\\1", e)), intToUtf8, ""))
    s <- gsub("&lt;", "<", s, fixed = TRUE)
    s <- gsub("&gt;", ">", s, fixed = TRUE)
    s <- gsub("&quot;", "\"", s, fixed = TRUE)
    s <- gsub("&apos;", "'", s, fixed = TRUE)
    gsub("&amp;", "&", s, fixed = TRUE)
  }, "", USE.NAMES = FALSE)
}
for (v in c("ISO2", "country_name", "institution", "source", "source_link")) d[[v]] <- unent(d[[v]])

num <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  ifelse(is.na(x), NA, round(x, 4))
}
d$cash_usage_volume <- num(d$cash_usage_volume)
d$cash_usage_value  <- num(d$cash_usage_value)
d$study_year <- as.integer(d$study_year)
d <- d[order(d$ISO2, -d$study_year), ]

# Przypisy: "*" i "**" na końcu nazwy źródła odsyłają do arkusza "footnotes".
fn <- read.xlsx(src, sheet = "footnotes", colNames = FALSE)[[1]]
fn <- unent(trimws(fn[!is.na(fn)]))
mark <- regmatches(d$source, regexpr("\\*+$", d$source))
d$note <- ""
d$note[grepl("\\*+$", d$source)] <- mark
d$source_clean <- trimws(sub("\\*+$", "", d$source))

split_links <- function(s) {
  if (is.na(s) || !nzchar(s)) return(character(0))
  trimws(strsplit(s, ";", fixed = TRUE)[[1]])
}

rows <- lapply(seq_len(nrow(d)), function(i) {
  list(
    iso = d$ISO2[i], country = d$country_name[i], year = d$study_year[i],
    vol = if (is.na(d$cash_usage_volume[i])) NULL else d$cash_usage_volume[i],
    val = if (is.na(d$cash_usage_value[i])) NULL else d$cash_usage_value[i],
    inst = d$institution[i], src = d$source_clean[i], note = d$note[i],
    links = I(split_links(d$source_link[i]))
  )
})

out <- list(
  updated = updated,
  n_obs = nrow(d),
  n_countries = length(unique(d$ISO2)),
  year_min = min(d$study_year), year_max = max(d$study_year),
  footnotes = as.list(fn),
  rows = rows
)
dir.create("data", showWarnings = FALSE)
writeLines(toJSON(out, auto_unbox = TRUE, null = "null", na = "null", digits = NA), "data/cud.json", useBytes = TRUE)

csv <- data.frame(
  ISO2 = d$ISO2, country_name = d$country_name, study_year = d$study_year,
  cash_usage_volume = d$cash_usage_volume, cash_usage_value = d$cash_usage_value,
  institution = d$institution, source = d$source, source_link = d$source_link
)
write.csv(csv, "data/cash_usage_database.csv", row.names = FALSE, na = "", fileEncoding = "UTF-8")
file.copy(src, "data/cash_usage_database.xlsx", overwrite = TRUE)

message(sprintf("Zapisano: %d obserwacji, %d krajów, lata %d–%d",
                out$n_obs, out$n_countries, out$year_min, out$year_max))
