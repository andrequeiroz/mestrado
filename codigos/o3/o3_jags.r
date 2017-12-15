library(R2jags)
library(DBI)

link <- dbConnect(RSQLite::SQLite(), "../../dados/o3.db")

dados <- dbGetQuery(link, "SELECT * FROM achcar2011")
y <- t(dados)
K <- ncol(dados)
N <- nrow(dados)

dbDisconnect(link)

## jags
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
