library(R2jags)
library(DBI)

link <- dbConnect(RSQLite::SQLite(), "/tmp/svsim2.db")

## svsim.db
dbSendQuery(link, paste0("CREATE TABLE jags (p REAL, s REAL, k INTEGER,
                                             j INTEGER, inf REAL, mu REAL,
                                             phi REAL, sigma2 REAL)"))
tabelas <- dbListTables(link)

for (i in 1:length(tabelas)) {

    p <- as.numeric(gsub("p([0-9]{1,3})s([0-9]{2})", "\\1", tabelas[i])) / 10
    p <- ifelse(p > 1, p / 10, p)
    s <- as.numeric(gsub("p([0-9]{1,3})s([0-9]{2})", "\\2", tabelas[i])) / 10

    for (k in 1:16) {

        dados <- dbGetQuery(link, paste("SELECT y, h FROM", tabelas[i],
                                        "WHERE k =", k))
        y <- dados[, "y"]
        N <- length(y)

        for (rodada in 1:1) {

            result <- jags(data = list("y", "N"), inits = NULL,
                           parameters.to.save = c("mu", "phi", "sigma2"),
                           model.file = "../../modelos/svsim/svsim.jags.model",
                           n.chains = 1, n.iter = 15000, n.burnin = 5000,
                           n.thin = 10)

            result <- result$BUGSoutput$sims.list
            j <- 1 # rep((rodada - 1) * 8 + 1:8, each = 1000)

            for (z in 1:1000) {
                dbSendQuery(link, paste0("INSERT INTO jags VALUES (", p, ", ",
                                         s, ", ", k, ", ", j, ", ", 0, ", ",
                                         round(result$mu[z], 6), ", ",
                                         round(result$phi[z], 6), ", ",
                                         round(result$sigma2[z], 6), ")"))
            }
        }
    }
}

dbClearResult(dbListResults(link)[[1]])
dbDisconnect(link)

## rodada
dados <- dbGetQuery(link, "SELECT y, h FROM p099s05 WHERE k = 1")
y <- dados[, "y"]
N <- length(y)

## 8 chains
result <- jags.parallel(data = list("y", "N"), inits = NULL,
                        parameters.to.save = c("mu", "phi", "sigma2"),
                        model.file = "../../modelos/svsim/svsim.jags.model",
                        n.chains = 8, n.iter = 15000, n.burnin = 5000,
                        n.thin = 10)

## 1 chain
result <- jags(data = list("y", "N"), inits = NULL,
               parameters.to.save = c("mu", "phi", "sigma2"),
               model.file = "../../modelos/svsim/svsim.jags.model",
               n.chains = 1, n.iter = 15000, n.burnin = 5000, n.thin = 10)

plot(result)
traceplot(result)
