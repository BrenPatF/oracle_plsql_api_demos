SET SERVEROUTPUT ON
SET TRIMSPOOL ON
SET PAGES 1000
SET LINES 500
SPOOL Install_SYS.log
/***************************************************************************************************

Author:      Brendan Furey
Description: Script for SYS schema to create the new schema for Brendan's TRAPIT API testing
             framework design patterns demo. """Directory needs to be changed"""

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        04-May-2016 1.0   Created
Brendan Furey        11-Sep-2016 1.1   Directory
Brendan Furey        01-Mar-2018 1.2   INHERIT PRIVILEGES to avoid ORA-06598 from 12c security

***************************************************************************************************/
REM
REM Run this script from sys schema to create new schema for Brendan's testing demo
REM

DEFINE DEMO_USER=&1

CREATE USER &DEMO_USER IDENTIFIED BY &DEMO_USER
DEFAULT TABLESPACE "USERS"
TEMPORARY TABLESPACE "TEMP";

-- SYSTEM PRIVILEGES
GRANT CREATE SESSION TO &DEMO_USER ;
GRANT ALTER SESSION TO &DEMO_USER ;
GRANT CREATE TABLE TO &DEMO_USER ;
GRANT CREATE TYPE TO &DEMO_USER ;
GRANT CREATE PUBLIC SYNONYM TO &DEMO_USER ;
GRANT CREATE SYNONYM TO &DEMO_USER ;
GRANT CREATE SEQUENCE TO &DEMO_USER ;
GRANT CREATE VIEW TO &DEMO_USER ;
GRANT UNLIMITED TABLESPACE TO &DEMO_USER ;
GRANT CREATE PROCEDURE TO &DEMO_USER ;

GRANT INHERIT PRIVILEGES ON USER sys TO &DEMO_USER;

PROMPT Directory input_dir - change to a writeable directory on your system
CREATE OR REPLACE DIRECTORY input_dir AS 'C:\input'
/
GRANT ALL ON DIRECTORY input_dir TO PUBLIC
/
GRANT EXECUTE ON UTL_File TO PUBLIC
/
SPOOL OFF