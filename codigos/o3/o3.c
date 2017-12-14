#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlite3.h>
#include <math.h>
#include <time.h>
#include <gsl/gsl_randist.h>

#define p_A 0
#define p_B 100
#define p_C 20
#define p_D 1.5
#define p_E 1

double D1(double, double *, double *, double, double, double);
double D2(double, double *, double *, double, double);
double mu_media(double *, double *, double, int);
double mu_cte(double, int);
double mu_R(double, double *, double, double);
double phi_media(double *, double *, double, int);
double phi_cte(double *, double, double, int);
double phi_R(double, double *, double, double);
double CT_sigma2(double *, double *, int, double);
double BT_sigma2(double *, int, double);
double bT_sigma2(double *, double *, double *, int, double, double);
double BT_mu(int, double);
double bT_mu(double *, double *, double *, int, double, double);

int main(void) {

  unsigned long int t = time(NULL);

  int n = 834;
  sqlite3 *db;
  sqlite3_stmt *stmt;
  char query[35] = "SELECT CE AS y FROM achcar2011";
  FILE *f = fopen("/tmp/resultado", "w");
  FILE *f_h = fopen("/tmp/resultado_h", "w");

  double *y;
  y = malloc(n * sizeof (double));

  sqlite3_open("../../dados/o3.db", &db);
  sqlite3_prepare_v2(db, query, strlen(query) + 1, &stmt, NULL);

  for (int i = 0; i < n; i++) {

    sqlite3_step(stmt);
    *(y + i) = sqlite3_column_double(stmt, 0);
    if (!*(y + i)) *(y + i) = 1E-123;
  }

  sqlite3_close(db);

  // setup mcmc
  int burnin = 5000, mc = 10000, thin = 10;
  double h0, *h, p[3], m, C, lambda, x1, x2, candidate, s[3];
  float a[3];

  h = malloc(n * sizeof (double));
  a[0] = a[1] = a[2] = 0;
  s[0] = s[1] = s[2] = 0;

  // valores iniciais dos parâmetros
  p[0] = 0.0;
  p[1] = 0.8;
  p[2] = 0.25;

  // erro do modelo
  double mr = -1.2702800088, sr2 = 4.9337311973;

  const gsl_rng_type *T;
  gsl_rng *engine;
  gsl_rng_env_setup();
  T = gsl_rng_default;
  engine = gsl_rng_alloc(T);

  printf("lambda: ");
  scanf("%lf", &lambda);

  // mcmc (McCormick + ASIS)
  for (int i = 0; i < burnin + mc; i++) {

    printf("%06d: %9.5lf %7.5lf %.5lf\n", i + 1, p[0], p[1], p[2]);

    // estimar h (McCormick)
    m = 0.0;
    C = p[2] / (1 - pow(p[1], 2));

    for (int j = 0; j < n; j++) {

      x1 = D1(m, y + j, p, m, C, lambda);
      x2 = D2(m, y + j, p, C, lambda);
      m -= x1 / x2;
      C = -1 / x2;
      *(h + j) = m + 0 * gsl_ran_gaussian(engine, sqrt(C));
      if (i > (burnin - 1) && (i + 1) % thin == 0) {
        fprintf(f_h, "%d\t%d\t%lf\n", i + 1, j + 1, *(h + j));
      }
    }
    h0 = p[0] + gsl_ran_gaussian(engine, sqrt(*(p + 2) / (1 - pow(*(p + 1), 2))));

    // 3-block GIS-C (ASIS)
    // C
    // estimar sigma2 (MH)
    x1 = (double) n;
    x2 = CT_sigma2(h, p, n, h0);
    candidate = 1 / gsl_ran_gamma(engine, x1 / 2, 2 / x2);

    if (gsl_ran_flat(engine, 0, 1) < exp((p[2] - candidate) / (2 * p_E))) {
      p[2] = candidate;
      a[0]++;
    }

    // estimar phi (MH)
    x1 = phi_media(h, p, h0, n);
    x2 = phi_cte(h, 10e8, h0, n);
    do {
      candidate = x1 / x2 + gsl_ran_gaussian(engine, sqrt(p[2] / x2));
    } while (candidate < -1 || candidate > 1);
    x1 = phi_R(candidate, p, 10e8, h0);
    x2 = phi_R(p[1], p, 10e8, h0);

    if (gsl_ran_flat(engine, 0, 1) < x1 / x2) {
      p[1] = candidate;
      a[1]++;
    }

    // estimar mu (MH)
    x1 = mu_media(h, p, h0, n);
    x2 = mu_cte(10e12, n);

    candidate = x1 / x2 + gsl_ran_gaussian(engine, sqrt(p[2] / x2));

    x1 = mu_R(candidate, p, 10e12, h0);
    x2 = mu_R(p[0], p, 10e12, h0);
    if (gsl_ran_flat(engine, 0, 1) < x1 / x2) {
      p[0] = candidate / (1 - p[1]);
      a[2]++;
    }

    // NC
    // transformar h
    h0 = (h0 - *p) / sqrt(*(p + 2));
    for (int i = 0; i < n; i++) {
      *(h + i) = (*(h + i) - *p) / sqrt(*(p + 2));
    }

    // re-estimar sigma2
    x2 = BT_sigma2(h, n, sr2);
    x1 = x2 * bT_sigma2(y, h, p, n, mr, sr2);

    candidate = x1 + gsl_ran_gaussian(engine, sqrt(x2));
    p[2] = pow(candidate, 2);

    // re-estimar mu
    x2 = BT_mu(n, sr2);
    x1 = x2 * bT_mu(y, h, p, n, mr, sr2);

    candidate = x1 + gsl_ran_gaussian(engine, sqrt(x2));
    p[0] = candidate;

    if (i > (burnin - 1) && (i + 1) % thin == 0) {
      s[0] += p[0];
      s[1] += p[1];
      s[2] += p[2];
      fprintf(f, "%lf\t%lf\t%lf\n", p[0], p[1], p[2]);
    }
  }

  gsl_rng_free(engine);
  free(y);
  free(h);
  fclose(f);
  fclose(f_h);

  printf("\nmu: %11.5lf (%.2f%%)\nphi: %10.5lf (%.2f%%)\nsigma2: %.5lf (%.2f%%)\n",
         s[0] / (mc / thin), a[2] * 100 / (burnin + mc), s[1] / (mc / thin),
         a[1] * 100 / (burnin + mc), s[2] / (mc / thin),
         a[0] * 100 / (burnin + mc));

  t = time(NULL) - t;
  printf("\nTempo de execução: %ldmin %lds (%0.2f Rodadas/s)\n",
   t / 60, t % 60, (float) (burnin + mc) / t);

  return 0;
};

double D1(double x, double *y, double *p, double m, double C, double lambda) {

  double R, result;

  R = pow(*(p + 1), 2) * C / lambda;
  result = -0.5 + pow(*y, 2) / (2 * exp(x));
  result -= (x - (*p * (1 - *(p + 1)) + *(p + 1) * m)) / R;

  return result;
};

double D2(double x, double *y, double *p, double C, double lambda) {

  double R, result;

  R = pow(*(p + 1), 2) * C / lambda;
  result = -pow(*y, 2) / (2 * exp(x)) - 1 / R;

  return result;
};

double mu_media(double *h, double *p, double h0, int n) {
  // conferido
  double result;

  result = *h - *(p + 1) * h0;
  for (int i = 0; i < (n - 1); i++) {
    result += *(h + i + 1) - *(p + 1) * *(h + i);
  }

  return result;
};

double mu_cte(double B, int n) {
  // conferido
  double result;

  result = n + 1 / B;

  return result;
};

double mu_R(double x, double *p, double B, double h0) {
  // conferido
  double result;

  result = exp(-pow(h0 - x / (1 - *(p + 1)), 2) * (1 - pow(*(p + 1), 2)) / (2 * *(p + 2)));
  result *= exp(-pow(x - p_A * (1 - *(p + 1)), 2) / (2 * p_B * pow(1 - *(p + 1), 2)));

  return result;
};

double phi_media(double *h, double *p, double h0, int n) {

  double result;

  result = -(1 - *(p + 1)) * *p * h0;
  for (int i = 0; i < (n - 1); i++) {
    result -= (1 - *(p + 1)) * *p * *(h + i);
  }

  result += h0 * *h;
  for (int i = 0; i < (n - 1); i++) {
    result += *(h + i + 1) * *(h + i);
  }

  return result;
};

double phi_cte(double *h, double B, double h0, int n) {

  double result;

  result = pow(h0, 2) + 1 / B;
  for (int i = 0; i < (n - 1); i++) {
    result += pow(*(h + i), 2);
  }

  return result;
};

double phi_R(double x, double *p, double B, double h0) {

  double result;

  result = sqrt(1 - pow(x, 2)) * pow((1 + x) / 2, p_C - 1) * pow((1 - x) / 2, p_D - 1);
  result *= exp(-(1 - pow(x, 2)) * pow(h0 - *p, 2) / (2 * *(p + 2)));
  result /= exp(-pow(x, 2) / (2 * *(p + 2) * B));

  return result;
};

double CT_sigma2(double *h, double *p, int n, double h0) {
  // conferido
  double result;

  result = pow(h0 - *p, 2) * (1 - pow(*(p + 1), 2));
  result += pow(*h - *p - *(p + 1) * (h0 - *p), 2);
  for (int i = 1; i < n; i++) {
    result += pow(*(h + i) - *p - *(p + 1) * (*(h + i - 1) - *p), 2);
  }

  return result;
};

double BT_sigma2(double *h, int n, double sr2) {
  // conferido
  double result;

  result = 1 / p_E;
  for (int i = 0; i < n; i++) {
    result += pow(*(h + i), 2) / sr2;
  }
  result = 1 / result;

  return result;
};

double bT_sigma2(double *y, double *h, double *p, int n, double mr, double sr2) {
  // conferido
  double result;

  result = 0;
  for (int i = 0; i < n; i++) {
    result += *(h + i) * (log(pow(*(y + i), 2)) - mr - *p) / sr2;
  }

  return result;
};

double BT_mu(int n, double sr2) {
  // conferido
  double result;

  result = 1 / p_B;
  for (int i = 0; i < n; i++) {
    result += 1 / sr2;
  }
  result = 1 / result;

  return result;
};

double bT_mu(double *y, double *h, double *p, int n, double mr, double sr2) {
  // conferido
  double result;

  result = p_A / p_B;
  for (int i = 0; i < n; i++) {
    result += (log(pow(*(y + i), 2)) - mr - sqrt(*(p + 2)) * *(h + i)) / sr2;
  }

  return result;
};
