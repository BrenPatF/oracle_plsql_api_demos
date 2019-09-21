DEFINE app=&1
@..\initspool install_hr
/***************************************************************************************************
Name: install_hr.sql                    Author: Brendan Furey                      Date: 21-Sep-2019

Installation script for hr components in the Oracle PL/SQL API Demos module. 

The module demonstrates instrumentation and logging, code timing, and unit testing of PL/SQL APIs,
using example APIs writtten against Oracle's HR demo schema. 

    GitHub: https://github.com/BrenPatF/https://github.com/BrenPatF/oracle_plsql_api_demos

There are install scripts in the lib, hr and app schemas. Note that installation of this module is
dependent on pre-requisite installs of other modules as described in the README.

INSTALL SCRIPTS
====================================================================================================
|  Script                 |  Notes                                                                 |
|===================================================================================================
|  LIB SCHEMA                                                                                      |
----------------------------------------------------------------------------------------------------
|  install_jobs.sql       |  Creates batch_jobs and related components in lib schema               |
----------------------------------------------------------------------------------------------------
|  grant_jobs_to_app.sql  |  Grants privileges on batch_jobs and related components from lib to    |
|                         |  app schema                                                            |
----------------------------------------------------------------------------------------------------
|  HR SCHEMA                                                                                       |
----------------------------------------------------------------------------------------------------
| *install_hr.sql*        |  Creates hr components                                                 |
|  revert_hr.sql          |  Reverts hr components (undoes install_hr.sql)                         |
----------------------------------------------------------------------------------------------------
|  APP SCHEMA                                                                                      |
----------------------------------------------------------------------------------------------------
|  c_jobs_syns.sql        |  Creates synonyms for batch_jobs and related components in app schema  |
|                         |  to lib schema                                                         |
----------------------------------------------------------------------------------------------------
|  install_api_demos.sql  |  Creates API Demo components in app schema                             |
====================================================================================================
This file has the install script for the batch_jobs and related components in lib schema.

Grants applied to app schema:

    Privilege  Object         Object Type
    =========  =============  ======================================================================
    All        employees_seq  Sequence
    All        departments    Table
    All        employees      Table

Tables altered:

    Tables              Description
    ==================  ============================================================================
    employees           employees (add ttid and update_date)
    job_statistics      Batch job run statistics

Tables created, with grants to app schema:

    Tables              Description
    ==================  ============================================================================
    err$_employees      Error logging for employees

***************************************************************************************************/

PROMPT Grant all on employees to &app
GRANT ALL ON employees TO &app
/
PROMPT Grant all on departments to &app
GRANT ALL ON departments TO &app
/
PROMPT Grant all on employees_seq to &app
GRANT ALL ON employees_seq TO &app
/
PROMPT Add update_date, then ttid to employees
ALTER TABLE employees ADD(update_date DATE)
/
UPDATE employees SET update_date = SYSDATE - 100
/
ALTER TABLE employees ADD(ttid VARCHAR2(30))
/
PROMPT Drop and recreate err$_employees via DBMS_ERRLOG.create_error_log
DROP TABLE err$_employees
/
BEGIN
  DBMS_ERRLOG.create_error_log(dml_table_name => 'employees');
END;
/
PROMPT Add job_statistic_id to err$_employees
ALTER TABLE err$_employees ADD(job_statistic_id NUMBER)
/
GRANT ALL ON err$_employees TO &app
/
@..\endspool