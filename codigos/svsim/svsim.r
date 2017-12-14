library(DBI)

## simular os dados a partir de kastner e frühwirth-schnatter 2014
sv_data <- function(n, mu, phi, sigma) {

    h0 <- rnorm(1, mu, sigma / sqrt(1 - phi ** 2))
    h <- rep(mu + phi * (h0 - mu) + sigma * rnorm(1), n)
    y <- rep(exp(h[1] / 2) * rnorm(1), n)

    for (i in 2:n) {
        h[i] <- mu + phi * (h[i -1] - mu) + sigma * rnorm(1)
        y[i] <- exp(h[i] / 2) * rnorm(1)
    }
    return(data.frame(y = round(y, 6), h = round(h, 6)))
}

set.seed(1655)

link <- dbConnect(RSQLite::SQLite(), "/tmp/svsim2.db")

insert <- function(p, s, tabela, k){

    dbSendQuery(link, paste("CREATE TABLE", tabela,
                            "(k INTEGER, y REAL, h REAL)"))

    for (i in 1:k) {
        dados <- sv_data(n = 1461, mu = -5.4, phi = p, sigma = s)
        for (j in 1:nrow(dados)) {
            dbSendQuery(link, paste0("INSERT INTO ", tabela, " VALUES (", i,
                                     ", ", dados[j, 1], ", ", dados[j, 2], ")"))
        }
    }
}


valores <- expand.grid(p = c(0.5, 0.8, 0.9, 0.99), s = c(0.3, 0.5, 0.1))
valores <- transform(valores, tabela = gsub("\\.", "",
                                            paste0("p", p, "s", s)), k = 16)
apply(valores, 1, function(x) insert(p = as.numeric(x[1]), s = as.numeric(x[2]),
                                     tabela = x[3], k = x[4]))

dbClearResult(dbListResults(link)[[1]])
dbDisconnect(link)
