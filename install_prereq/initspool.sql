SET PAGES 10000
SET lines 1000
COLUMN "Database"       FORMAT A20
COLUMN "Time"           FORMAT A20
COLUMN "Version"        FORMAT A30
COLUMN "Session"        FORMAT 9999990
COLUMN "OS User"        FORMAT A10
COLUMN "Machine"        FORMAT A20
SET SERVEROUTPUT ON
SET TRIMSPOOL ON
SPOOL &1..log
SELECT 'Start: ' || dbs.name "Database", To_Char (SYSDATE,'DD-MON-YYYY HH24:MI:SS') "Time",
        Substr(ver.banner_full, Instr(ver.banner_full, 'Version')) "Version"
  FROM v$database dbs,  v$version ver
 WHERE ver.banner LIKE 'Oracle%';
