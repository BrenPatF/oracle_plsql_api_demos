CREATE OR REPLACE PACKAGE DML_API_Jobs AS
/***************************************************************************************************
Name: dml_api_jobs.pks                     Author: Brendan Furey                   Date: 21-Sep-2019

Package spec component in the Oracle PL/SQL API Demos module. 

The module demonstrates instrumentation and logging, code timing, and unit testing of PL/SQL APIs,
using example APIs writtten against Oracle's HR demo schema. 

    GitHub: https://github.com/BrenPatF/https://github.com/BrenPatF/oracle_plsql_api_demos

There are two main packages and a view, with corresponding unit test packages, a DML API package
in app schema, and a DML API package in lib schema. Note that installation of this module is
dependent on pre-requisite installs of other modules as described in the README.

BASE/TEST PROGRAM UNITS
====================================================================================================
|  Package/View    |  Test Package     |  Notes                                                    |
|==================================================================================================|
|  LIB SCHEMA                                                                                      |
|--------------------------------------------------------------------------------------------------|
| *DML_API_Jobs*   |  N.A.             |  DML for batch_jobs, job_statistics                       |
|--------------------------------------------------------------------------------------------------|
|  APP SCHEMA                                                                                      |
|--------------------------------------------------------------------------------------------------|
|  DML_API_TT_HR   |  N.A.             |  DML for hr tables for unit testing                       |
|------------------|-------------------|-----------------------------------------------------------|
|  Emp_WS          |  TT_Emp_WS        |  Save_Emps: Save a list of new employees                  |
|                  |                   |  Get_Dept_Emps: Get department and employee details       |
|------------------|-------------------|-----------------------------------------------------------|
|  Emp_Batch       |  TT_Emp_Batch     |  Load_Emps: Load new/updated employees from file          |
|------------------|-------------------|-----------------------------------------------------------|
|  HR_Test_View_V  |  TT_View_Drivers  |  HR_Test_View_V: View for department and employee details |
====================================================================================================
This file has the DML_API_Jobs package spec.

***************************************************************************************************/

PROCEDURE Ins_Job(
            p_batch_job_id                 VARCHAR2,
            p_fail_threshold_perc          NUMBER);

FUNCTION Ins_Jbs(
            p_batch_job_id                 VARCHAR2,
            p_file_name                    VARCHAR2,
            p_records_loaded               PLS_INTEGER,
            p_records_failed_et            PLS_INTEGER,
            p_records_failed_db            PLS_INTEGER,
            p_start_time                   DATE,
            p_end_time                     DATE,
            p_job_status                   VARCHAR2)
            RETURN                         PLS_INTEGER;

END DML_API_Jobs;
/
SHO ERR
