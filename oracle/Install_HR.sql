SET SERVEROUTPUT ON
SET TRIMSPOOL ON
SET PAGES 1000
SET LINES 500
SPOOL Install_HR.log
/***************************************************************************************************

Author:      Brendan Furey
Description: Script for HR schema to do HR changes

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        04-May-2016 1.0   Created
Brendan Furey        11-Sep-2016 1.1   error table etc

***************************************************************************************************/
DEFINE DEMO_USER=&1
REM
REM Run this script from HR schema for Brendan's testing demo
REM

PROMPT Grant all on employees to &DEMO_USER
GRANT ALL ON employees TO &DEMO_USER
/
PROMPT Grant all on departments to &DEMO_USER
GRANT ALL ON departments TO &DEMO_USER
/
PROMPT Grant all on employees_seq to &DEMO_USER
GRANT ALL ON employees_seq TO &DEMO_USER
/
PROMPT Drop ttid from employees, then update_date
ALTER TABLE employees DROP (ttid)
/
ALTER TABLE employees DROP (update_date)
/
PROMPT Drop and recreate err$_employees via DBMS_ERRLOG.create_error_log
DROP TABLE err$_employees
/
BEGIN
  DBMS_ERRLOG.create_error_log (dml_table_name => 'employees');
END;
/
PROMPT Add job_statistic_id to err$_employees
ALTER TABLE err$_employees ADD (job_statistic_id NUMBER)
/
PROMPT Add ttid to err$_employees
ALTER TABLE err$_employees ADD (ttid VARCHAR2(30))
/
GRANT ALL ON err$_employees TO &DEMO_USER
/
PROMPT Add update_date, then ttid to employees
ALTER TABLE employees ADD (update_date DATE)
/
UPDATE employees SET update_date = SYSDATE - 100
/
ALTER TABLE employees ADD (ttid VARCHAR2(30))
/
SPOOL OFF