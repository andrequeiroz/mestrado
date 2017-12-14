library(DBI)
library(dplyr)

## base achcar 2011
link <- dbConnect(RSQLite::SQLite(), "/tmp/o3_raw.db")

"SELECT o.infoDay, s.region, MAX(ozone) AS ozone
 FROM ozone AS o
  INNER JOIN stations AS s ON o.codStation = s.codStation
 WHERE o.infoDay < date('2006-01-01') AND s.region IS NOT NULL
 GROUP BY o.infoDay, s.region
 ORDER By o.infoDay, s.region" %>%
    dbGetQuery(link, .) %>%
    mutate(week = c(rep(1:((n() / 5) %/% 7), each = 5 * 7),
                    rep(((n() / 5) %/% 7 + 1),
                        times = 5 * (n() / 5) %% 7))) -> dados

dbDisconnect(link)

dados %>%
    group_by(region) %>%
    summarise(avg = round(mean(ozone, na.rm = TRUE), 3),
              sd = round(sd(ozone, na.rm = TRUE), 3))

ozone <- dados %>%
    group_by(region, week) %>%
    summarise(avg = mean(ozone, na.rm = TRUE)) %>%
    mutate(avg = ifelse(is.nan(avg), NA, avg)) %>%
    tidyr::spread(region, avg) %>%
    select(-week) %>%
    log() %>%
    apply(2, diff)


valor <- function(x) {
    ifelse(is.na(x), "NULL", x)
}

link <- dbConnect(RSQLite::SQLite(), "/tmp/o3.db")
dbSendQuery(link, "PRAGMA foreign_keys = ON")
dbSendQuery(link, "CREATE TABLE achcar2011 (CE REAL, NE REAL, NW REAL, SE REAL,
                    SW REAL)")

dbSendQuery(link, "BEGIN TRANSACTION")
for (i in 1:nrow(ozone)) {
    dbSendQuery(link, paste0("INSERT INTO achcar2011 VALUES (",
                             valor(ozone[i, 1]), ", ", valor(ozone[i, 2]),
                             ", ", valor(ozone[i, 3]), ", ",
                             valor(ozone[i, 4]), ", ", valor(ozone[i, 5]), ")"))
}

dbSendQuery(link, "COMMIT TRANSACTION")

dbClearResult(dbListResults(link)[[1]])
dbDisconnect(link)

## base achcar 2008
link <- dbConnect(RSQLite::SQLite(), "/tmp/o3_raw.db")

"SELECT o.infoDay AS dia, s.region, MAX(ozone) AS ozone
 FROM ozone AS o
  INNER JOIN stations AS s ON o.codStation = s.codStation
 WHERE (o.infoDay > date('1997-12-31') AND o.infoDay < date('2005-01-01')) AND
  s.region IS NOT NULL
 GROUP BY o.infoDay, s.region
 ORDER By o.infoDay, s.region" %>%
    dbGetQuery(link, .) %>%
    mutate(dia = as.Date(dia)) -> dados

dbDisconnect(link)

dados %>%
    group_by(region) %>%
    summarise(avg = round(mean(ozone, na.rm = TRUE), 3),
              sd = round(sd(ozone, na.rm = TRUE), 3))

ozone <- dados %>%
    tidyr::spread(region, ozone) %>%
    mutate(MAMC = apply(.[, -1], 1, max))

link <- dbConnect(RSQLite::SQLite(), "/tmp/o3.db")
dbSendQuery(link, "PRAGMA foreign_keys = ON")
dbSendQuery(link, "CREATE TABLE achcar2008 (dia TEXT NOT NULL, CE REAL, NE REAL,
                    NW REAL, SE REAL, SW REAL, MAMC REAL)")

dbSendQuery(link, "BEGIN TRANSACTION")
for (i in 1:nrow(ozone)) {
    dbSendQuery(link1, paste0("INSERT INTO achcar2008 VALUES (",
                              format(ozone[i, 1], "%Y-%m-%d"), ", ",
                              valor(ozone[i, 2]), ", ", valor(ozone[i, 3]),
                              ", ", valor(ozone[i, 4]), ", ",
                              valor(ozone[i, 5]), ", ", valor(ozone[i, 6]),
                              ", ", valor(ozone[i, 7]), ")"))
}

dbSendQuery(link, "COMMIT TRANSACTION")

dbClearResult(dbListResults(link)[[1]])
dbDisconnect(link)
