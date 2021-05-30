DEFINE lib=&1
/***************************************************************************************************
Name: c_jobs_syns.sql                   Author: Brendan Furey                      Date: 21-Sep-2019

Installation script for API Demo components in the Oracle PL/SQL API Demos module. 

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
|  grant_jobs_to_app.sql  |  Grants privileges on batch_jobs and related components from lib to    |
|                         |  app schema                                                            |
|--------------------------------------------------------------------------------------------------|
|  HR SCHEMA                                                                                       |
|--------------------------------------------------------------------------------------------------|
|  install_hr.sql         |  Creates hr components                                                 |
|  revert_hr.sql          |  Reverts hr components (undoes install_hr.sql)                         |
|--------------------------------------------------------------------------------------------------|
|  APP SCHEMA                                                                                      |
|--------------------------------------------------------------------------------------------------|
| *c_jobs_syns.sql*       |  Creates synonyms for batch_jobs and related components in app schema  |
|                         |  to lib schema                                                         |
|-------------------------|------------------------------------------------------------------------|
|  install_api_demos.sql  |  Creates API Demo components in app schema                             |
====================================================================================================
This file creates synonyms for batch_jobs and related components in app schema to lib schema.

Synonyms created:

    Synonym             Object Type
    ==================  ============================================================================
    job_statistics_seq  Sequence
    batch_jobs          Table
    job_statistics      Table
    job_statistics_v    View
    DML_API_Jobs        Package

***************************************************************************************************/
PROMPT Creating synonyms for &lib Jobs components...
CREATE OR REPLACE SYNONYM job_statistics_seq FOR &lib..job_statistics_seq
/
CREATE OR REPLACE SYNONYM batch_jobs FOR &lib..batch_jobs
/
CREATE OR REPLACE SYNONYM job_statistics FOR &lib..job_statistics
/
CREATE OR REPLACE SYNONYM job_statistics_v FOR &lib..job_statistics_v
/
CREATE OR REPLACE SYNONYM DML_API_Jobs FOR &lib..DML_API_Jobs
/