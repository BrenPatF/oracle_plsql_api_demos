DEFINE app=&1
@..\initspool revert_hr
/***************************************************************************************************
Name: revert_hr.sql                     Author: Brendan Furey                      Date: 21-Sep-2019

Revert script for hr components in the Oracle PL/SQL API Demos module.

The module demonstrates instrumentation and logging, code timing, and unit testing of PL/SQL APIs,
using example APIs writtten against Oracle's HR demo schema. 

    GitHub: https://github.com/BrenPatF/https://github.com/BrenPatF/oracle_plsql_api_demos

There are install scripts in the lib, hr and app schemas. Note that installation of this module is
dependent on pre-requisite installs of other modules as described in the README.

INSTALL SCRIPTS
====================================================================================================
|  Script                 |  Notes                                                                 |
|==================================================================================================|
|  LIB SCHEMA                                                                                      |
|--------------------------------------------------------------------------------------------------|
|  install_jobs.sql       |  Creates batch_jobs and related components in lib schema               |
|-------------------------|------------------------------------------------------------------------|
|  grant_jobs_to_app.sql  |  Revokes privileges on batch_jobs and related components from lib to   |
|                         |  app schema                                                            |
|--------------------------------------------------------------------------------------------------|
|  HR SCHEMA                                                                                       |
|--------------------------------------------------------------------------------------------------|
|  install_hr.sql         |  Creates hr components                                                 |
| *revert_hr.sql*         |  Reverts hr components (undoes install_hr.sql)                         |
|--------------------------------------------------------------------------------------------------|
|  APP SCHEMA                                                                                      |
|--------------------------------------------------------------------------------------------------|
|  c_jobs_syns.sql        |  Creates synonyms for batch_jobs and related components in app schema  |
|                         |  to lib schema                                                         |
|-------------------------|------------------------------------------------------------------------|
|  install_api_demos.sql  |  Creates API Demo components in app schema                             |
====================================================================================================
This file has the install script for the batch_jobs and related components in lib schema.

Revokes applied to app schema:

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

PROMPT Revoke all on employees to &app
REVOKE ALL ON employees FROM &app
/
PROMPT Revoke all on departments to &app
REVOKE ALL ON departments FROM &app
/
PROMPT Revoke all on employees_seq to &app
REVOKE ALL ON employees_seq FROM &app
/
PROMPT Drop update_date, then ttid from employees
ALTER TABLE employees DROP(update_date)
/
ALTER TABLE employees DROP(ttid)
/
PROMPT Drop err$_employees
DROP TABLE err$_employees
/
@..\endspool