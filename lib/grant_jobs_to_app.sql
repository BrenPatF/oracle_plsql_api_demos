DEFINE app=&1
/***************************************************************************************************
Name: grant_jobs_to_app.sql             Author: Brendan Furey                      Date: 21-Sep-2019

Installation script for batch_jobs and related components in the Oracle PL/SQL API Demos module. 

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
| *grant_jobs_to_app.sql* |  Grants privileges on batch_jobs and related components from lib to    |
|                         |  app schema                                                            |
|--------------------------------------------------------------------------------------------------|
|  HR SCHEMA                                                                                       |
|--------------------------------------------------------------------------------------------------|
|  install_hr.sql         |  Creates hr components                                                 |
|  revert_hr.sql          |  Reverts hr components (undoes install_hr.sql)                         |
|--------------------------------------------------------------------------------------------------|
|  APP SCHEMA                                                                                      |
|--------------------------------------------------------------------------------------------------|
|  c_jobs_syns.sql        |  Creates synonyms for batch_jobs and related components in app schema  |
|                         |  to lib schema                                                         |
|-------------------------|------------------------------------------------------------------------|
|  install_api_demos.sql  |  Creates API Demo components in app schema                             |
====================================================================================================
This file grants privileges on batch_jobs and related components from lib to app schema.

Grants applied:

    Privilege           Object                   Object Type
    ==================  =======================  ===================================================
    Select              job_statistics_seq       Sequence
    Select              batch_jobs               Table
    Select              job_statistics           Table
    All                 job_statistics_v         View
    Execute             DML_API_Jobs             Package

***************************************************************************************************/
PROMPT Granting Jobs components to &app...
GRANT SELECT ON job_statistics_seq TO &app
/
GRANT SELECT ON batch_jobs TO &app
/
GRANT SELECT ON job_statistics TO &app
/
GRANT ALL ON job_statistics_v TO &app
/
GRANT EXECUTE ON DML_API_Jobs TO &app
/