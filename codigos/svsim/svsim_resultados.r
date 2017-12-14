library(DBI)
library(dplyr)

link <- dbConnect(RSQLite::SQLite(), "/tmp/svsim_resultados.db")

## dados
dados <- read.table("/tmp/resultado_h") %>%
    group_by(V2) %>%
    summarise(media = mean(V3), llim = quantile(V3, 0.025),
              mediana = median(V3), ulim = quantile(V3, 0.975)) %>%
    ungroup()

fase <- 4
p <- 0.9
s <- 0.5
k <- 1

## h
dbSendQuery(link, paste0("CREATE TABLE IF NOT EXISTS h (fase INTEGER, p REAL,
                           s REAL, k INTEGER, t INTEGER, media REAL, inf REAL,
                           mediana REAL, sup REAL)"))

for (z in 1:nrow(dados)) {
    dbSendQuery(link, paste0("INSERT INTO h VALUES (", fase, ", ", p, ", ", s,
                             ", ", k, ", ", z, ", ", round(dados[z, "media"], 6),
                             ", ", round(dados[z, "llim"], 6), ", ",
                             round(dados[z, "mediana"], 6), ", ",
                             round(dados[z, "ulim"], 6), ")"))
}

dbClearResult(dbListResults(link)[[1]])
dbDisconnect(link)

## valores estimados
link <- dbConnect(drv, "/tmp/svsim_resultados.db")
## dbSendQuery(link, paste0("CREATE TABLE IF NOT EXISTS resultados (p REAL,
##                            s REAL, k INTEGER, t INTEGER, mu REAL, phi REAL,
##                            sigma2 REAL)"))

## dados
dados <- read.table("/tmp/resultado")
p <- 0.5
s <- 0.1
k <- 1

for (z in 1:nrow(dados)) {
    dbSendQuery(link, paste0("INSERT INTO resultados VALUES (", p, ", ", s,
                             ", ", k, ", ", z, ", ", round(dados[z, "V1"], 6),
                             ", ", round(dados[z, "V2"], 6), ", ",
                             round(dados[z, "V3"], 6), ")"))
}

dbClearResult(dbListResults(link)[[1]])
dbDisconnect(link)
