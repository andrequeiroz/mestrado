#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <sqlite3.h>

#define INPUTDATA "./o3_raw"
#define DATABASE "/tmp/o3_raw.db"
#define TABLE "CREATE TABLE IF NOT EXISTS ozone (infoDay TEXT NOT NULL, infoHour INTEGER NOT NULL, codStation INTEGER NOT NULL, ozone REAL, FOREIGN KEY (codStation) REFERENCES stations (codStation))"
#define BUFFER_SIZE 256

int main(int argc, char **argv) {

  sqlite3 * db;
  sqlite3_stmt * stmt;
  char * sErrMsg = 0;
  char * tail = 0;
  int nRetCode;
  int n = 0;

  clock_t cStartClock;

  FILE * pFile;
  char sInputBuf [BUFFER_SIZE] = "\0";

  char * sID = 0;
  char * sIH = 0;
  char * sCS = 0;
  char * sOZ = 0;

  char sSQL [BUFFER_SIZE] = "\0";

  sqlite3_open(DATABASE, &db);
  sqlite3_exec(db, TABLE, NULL, NULL, &sErrMsg);
  sqlite3_exec(db, "PRAGMA foreign_keys = ON", NULL, NULL, &sErrMsg);
  sqlite3_exec(db, "PRAGMA synchronous = OFF", NULL, NULL, &sErrMsg);
  sqlite3_exec(db, "PRAGMA journal_mode = MEMORY", NULL, NULL, &sErrMsg);

  cStartClock = clock();

  sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);

  pFile = fopen(INPUTDATA, "r");
  while (!feof(pFile)) {

    fgets(sInputBuf, BUFFER_SIZE, pFile);

    sID = strtok(sInputBuf, "\t");
    sIH = strtok(NULL, "\t");
    sCS = strtok(NULL, "\t");
    sOZ = strtok(NULL, "\t");

    sprintf(sSQL, "INSERT INTO ozone VALUES ('%s', %s, %s, %s)", sID, sIH, sCS, sOZ);
    sqlite3_exec(db, sSQL, NULL, NULL, &sErrMsg);

    n++;
  }
  fclose(pFile);

  sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);

  printf("Imported %d records in %4.2f sec\n", n, (clock() - cStartClock) / (double)CLOCKS_PER_SEC);

  sqlite3_close(db);
  return 0;
};
