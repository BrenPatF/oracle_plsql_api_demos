DEFINE app=&1
@..\initspool install_jobs
/***************************************************************************************************
Name: install_jobs.sql                  Author: Brendan Furey                      Date: 21-Sep-2019

Installation script for batch_jobs and related components in the Oracle PL/SQL API Demos module. 

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
| *install_jobs.sql*      |  Creates batch_jobs and related components in lib schema               |
----------------------------------------------------------------------------------------------------
|  grant_jobs_to_app.sql  |  Grants privileges on batch_jobs and related components from lib to    |
|                         |  app schema                                                            |
----------------------------------------------------------------------------------------------------
|  HR SCHEMA                                                                                       |
----------------------------------------------------------------------------------------------------
|  install_hr.sql         |  Creates hr components                                                 |
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

Components created, with grants from lib to app schema:

    Sequences           Description
    ==================  ============================================================================
    job_statistics_seq  For job_statistics primary key

    Tables              Description
    ==================  ============================================================================
    batch_jobs          Batch job data
    job_statistics      Batch job run statistics

    Views               Description
    ==================  ============================================================================
    job_statistics_v    View on job_statistics with sys_context condition for unit testing

    Packages            Description
    ==================  ============================================================================
    DML_API_Jobs        DML for batch_jobs, job_statistics

***************************************************************************************************/
PROMPT Create job_statistics_seq
DROP SEQUENCE job_statistics_seq
/
CREATE SEQUENCE job_statistics_seq START WITH 1
/
PROMPT Create batch_jobs
DROP TABLE job_statistics
/
DROP TABLE batch_jobs
/
CREATE TABLE batch_jobs (
        batch_job_id        VARCHAR2(30) NOT NULL,
        fail_threshold_perc NUMBER,
        CONSTRAINT bjb_pk PRIMARY KEY (batch_job_id)
)
/
PROMPT Create job_statistics
CREATE TABLE job_statistics (
        job_statistic_id        NUMBER NOT NULL,
        batch_job_id            NOT NULL,
        file_name               VARCHAR2(60) NOT NULL,
        records_loaded          NUMBER,
        records_failed_et       NUMBER,
        records_failed_db       NUMBER,
        start_time              DATE,
        end_time                DATE,
        job_status              VARCHAR2(1),
        ttid                    VARCHAR2(30),
        CONSTRAINT jbs_pk PRIMARY KEY (job_statistic_id),
        CONSTRAINT jbs_bjb_fk FOREIGN KEY (batch_job_id) REFERENCES batch_jobs (batch_job_id),
        CONSTRAINT jbs_job_status_chk CHECK (job_status IN ('S', 'F'))
)
/
PROMPT job_statistics_v view
CREATE OR REPLACE VIEW job_statistics_v AS
SELECT job_statistic_id,
       batch_job_id,
       file_name,
       records_loaded,
       records_failed_et,
       records_failed_db,
       start_time,
       end_time,
       job_status,
       ttid
  FROM job_statistics
 WHERE (ttid = SYS_Context('userenv', 'sessionid') OR
        SYS_Context('TRAPIT_CTX', 'MODE') IS NULL)
/
PROMPT Create DML_API_Jobs package
@dml_api_jobs.pks
@dml_api_jobs.pkb

PROMPT Grant access to &app (skip if none passed)
WHENEVER SQLERROR EXIT
EXEC IF '&app' = 'none' THEN RAISE_APPLICATION_ERROR(-20000, 'Skipping schema grants'); END IF;
@grant_jobs_to_app &app

@..\endspool