library(R2jags)
library(DBI)

link <- dbConnect(RSQLite::SQLite(), "/tmp/o3.db")

dados <- dbGetQuery(link, "SELECT * FROM achcar2011")
y <- t(dados)
K <- ncol(dados)
N <- nrow(dados)

## jags
dbSendQuery(link, paste0("CREATE TABLE jags (model INTEGER, region TEXT,
                           inf INTEGER, mu REAL, phi REAL, sigma REAL,
                           sigmaomega REAL)"))

result <- jags(data = list("y", "K", "N"), inits = NULL,
               parameters.to.save = c("mu", "phi", "sigma"),
               model.file = "../../modelos/o3/o3.jags.model1", n.chains = 1,
               n.iter = 15000, n.burnin = 5000, n.thin = 10)

result <- result$BUGSoutput$sims.list

for (i in 1:5) {
    for (z in 1:1000) {
        dbSendQuery(link, paste0("INSERT INTO jags VALUES (", 1, ", '",
                                 rownames(y)[i], "', ", 0, ", ",
                                 round(result$mu[z, i], 6), ", ",
                                 round(result$phi[z, i], 6), ", ",
                                 round(result$sigma[z, i], 6), ", NULL)"))
    }

    result <- jags(data = list("y", "K", "N"), inits = NULL,
                   parameters.to.save = c("mu", "phi", "sigma", "sigmaomega"),
                   model.file = "../../modelos/o3/o3.jags.model2", n.chains = 1,
                   n.iter = 15000, n.burnin = 5000, n.thin = 10)

    result <- result$BUGSoutput$sims.list
}

for (i in 1:5) {
    for (z in 1:1000) {
        dbSendQuery(link, paste0("INSERT INTO jags VALUES (", 2, ", '",
                                 rownames(y)[i], "', ", 0, ", ",
                                 round(result$mu[z, i], 6), ", ",
                                 round(result$phi[z, i], 6), ", ",
                                 round(result$sigma[z, i], 6), ", ",
                                 round(result$sigmaomega[z], 6), ")"))
    }
}

result <- jags(data = list("y", "K", "N"), inits = NULL,
               parameters.to.save = c("mu", "phi", "sigma"),
               model.file = "../../modelos/o3/o3.jags.model3",
               n.chains = 1, n.iter = 15000, n.burnin = 5000, n.thin = 10)

result <- result$BUGSoutput$sims.list

for (i in 1:5) {
    for (z in 1:1000) {
        dbSendQuery(link, paste0("INSERT INTO jags VALUES (", 3, ", '",
                                 rownames(y)[i], "', ", 0, ", ",
                                 round(result$mu[z, i], 6), ", ",
                                 round(result$phi[z, i], 6), ", ",
                                 round(result$sigma[z, i], 6), ", NULL)"))
    }
}

result <- jags(data = list("y", "K", "N"), inits = NULL,
               parameters.to.save = c("mu", "phi", "sigma", "sigmaomega"),
               model.file = "../../modelos/o3/o3.jags.model4", n.chains = 1,
               n.iter = 15000, n.burnin = 5000, n.thin = 10)

result <- result$BUGSoutput$sims.list

for (i in 1:5) {
    for (z in 1:1000) {
        dbSendQuery(link, paste0("INSERT INTO jags VALUES (", 4, ", '",
                                 rownames(y)[i], "', ", 0, ", ",
                                 round(result$mu[z, i], 6), ", ",
                                 round(result$phi[z, i], 6), ", ",
                                 round(result$sigma[z, i], 6), ", ",
                                 round(result$sigmaomega[z], 6), ")"))
    }
}

dbClearResult(dbListResults(link)[[1]])
dbDisconnect(link)

## rodada
## 8 chains
result <- jags.parallel(data = list("y", "K", "N"), inits = NULL,
                        parameters.to.save = c("mu", "phi", "sigma"),
                        model.file = "../../modelos/o3/o3.jags.model1",
                        n.chains = 8, n.iter = 15000, n.burnin = 5000,
                        n.thin = 10)

## 1 chain
result <- jags(data = list("y", "K", "N"), inits = NULL,
               parameters.to.save = c("mu", "phi", "sigma"),
               model.file = "../../modelos/o3/o3.jags.model1",
               n.chains = 1, n.iter = 15000, n.burnin = 5000, n.thin = 10)

result <- jags(data = list("y", "K", "N"), inits = NULL,
               parameters.to.save = c("mu", "phi", "sigma", "sigmaomega"),
               model.file = "../../modelos/o3/o3.jags.model2",
               n.chains = 1, n.iter = 15000, n.burnin = 5000, n.thin = 10)

result <- jags(data = list("y", "K", "N"), inits = NULL,
               parameters.to.save = c("mu", "phi", "sigma"),
               model.file = "../../modelos/o3/o3.jags.model3",
               n.chains = 1, n.iter = 15000, n.burnin = 5000, n.thin = 10)

result <- jags(data = list("y", "K", "N"), inits = NULL,
               parameters.to.save = c("mu", "phi", "sigma", "sigmaomega"),
               model.file = "../../modelos/o3/o3.jags.model4",
               n.chains = 1, n.iter = 15000, n.burnin = 5000, n.thin = 10)

plot(result)
