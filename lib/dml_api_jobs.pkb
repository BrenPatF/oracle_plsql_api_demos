CREATE OR REPLACE PACKAGE BODY DML_API_Jobs AS
/***************************************************************************************************
Name: dml_api_jobs.pkb                     Author: Brendan Furey                   Date: 21-Sep-2019

Package body component in the Oracle PL/SQL API Demos module. 

The module demonstrates instrumentation and logging, code timing, and unit testing of PL/SQL APIs,
using example APIs writtten against Oracle's HR demo schema. 

    GitHub: https://github.com/BrenPatF/https://github.com/BrenPatF/oracle_plsql_api_demos

There are two main packages and a view, with corresponding unit test packages, a DML API package
in app schema, and a DML API package in lib schema. Note that installation of this module is
dependent on pre-requisite installs of other modules as described in the README.

BASE/TEST PROGRAM UNITS
====================================================================================================
|  Package/View    |  Test Package     |  Notes                                                    |
|===================================================================================================
|  LIB SCHEMA                                                                                      |
----------------------------------------------------------------------------------------------------
| *DML_API_Jobs*   |  N.A.             |  DML for batch_jobs, job_statistics                       |
----------------------------------------------------------------------------------------------------
|  APP SCHEMA                                                                                      |
----------------------------------------------------------------------------------------------------
|  DML_API_TT_HR   |  N.A.             |  DML for hr tables for unit testing                       |
----------------------------------------------------------------------------------------------------
|  Emp_WS          |  TT_Emp_WS        |  Save_Emps: Save a list of new employees                  |
|                  |                   |  Get_Dept_Emps: Get department and employee details       |
----------------------------------------------------------------------------------------------------
|  Emp_Batch       |  TT_Emp_Batch     |  Load_Emps: Load new/updated employees from file          |
----------------------------------------------------------------------------------------------------
|  HR_Test_View_V  |  TT_View_Drivers  |  HR_Test_View_V: View for department and employee details |
====================================================================================================
This file has the DML_API_Jobs package body.

***************************************************************************************************/

PROCEDURE Ins_Job(
            p_batch_job_id                 VARCHAR2,
            p_fail_threshold_perc          NUMBER) IS
BEGIN

  INSERT INTO batch_jobs(
      batch_job_id,
      fail_threshold_perc
  ) VALUES (
      p_batch_job_id, 
      p_fail_threshold_perc
  );

END Ins_Job;

/***************************************************************************************************

Ins_Jbs: Inserts a record in job_statistics table for testing, setting the new ttid column to
         session id if in TRAPIT mode

***************************************************************************************************/
FUNCTION Ins_Jbs(
            p_batch_job_id                 VARCHAR2,      -- batch job id
            p_file_name                    VARCHAR2,      -- original input file name
            p_records_loaded               PLS_INTEGER,   -- records loaded to table
            p_records_failed_et            PLS_INTEGER,   -- records that failed to load via external table
            p_records_failed_db            PLS_INTEGER,   -- records that failed validation in the database
            p_start_time                   DATE,          -- job start time
            p_end_time                     DATE,          -- job end time
            p_job_status                   VARCHAR2)      -- records that failed validation in the database
            RETURN                         PLS_INTEGER IS -- seqeunce-generated uid

  l_uid         PLS_INTEGER;

BEGIN

  INSERT INTO job_statistics (
        job_statistic_id,
        batch_job_id,
        file_name,
        records_loaded,
        records_failed_et,
        records_failed_db,
        start_time,
        end_time,
        job_status,
        ttid
  ) VALUES (
        job_statistics_seq.NEXTVAL,
        p_batch_job_id,
        p_file_name,
        p_records_loaded,
        p_records_failed_et,
        p_records_failed_db,
        p_start_time,
        p_end_time,
        p_job_status,
        Nvl2(SYS_Context('TRAPIT_CTX', 'MODE'), SYS_Context('userenv', 'sessionid'), NULL)

  ) RETURNING job_statistic_id INTO l_uid;
  RETURN l_uid;

END Ins_Jbs;

END DML_API_Jobs;
/
SHO ERR
