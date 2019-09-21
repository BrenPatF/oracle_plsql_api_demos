CREATE OR REPLACE PACKAGE BODY Emp_Batch AS
/***************************************************************************************************
Name: emp_batch.pkb                        Author: Brendan Furey                   Date: 21-Sep-2019

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
|  DML_API_Jobs    |  N.A.             |  DML for batch_jobs, job_statistics                       |
----------------------------------------------------------------------------------------------------
|  APP SCHEMA                                                                                      |
----------------------------------------------------------------------------------------------------
|  DML_API_TT_HR   |  N.A.             |  DML for hr tables for unit testing                       |
----------------------------------------------------------------------------------------------------
|  Emp_WS          |  TT_Emp_WS        |  Save_Emps: Save a list of new employees                  |
|                  |                   |  Get_Dept_Emps: Get department and employee details       |
----------------------------------------------------------------------------------------------------
| *Emp_Batch*      |  TT_Emp_Batch     |  Load_Emps: Load new/updated employees from file          |
----------------------------------------------------------------------------------------------------
|  HR_Test_View_V  |  TT_View_Drivers  |  HR_Test_View_V: View for department and employee details |
====================================================================================================
This file has the Emp_Batch package body.

***************************************************************************************************/

/***************************************************************************************************

Load_Emps: Load new/updated employees from file via external table, logging errors to err$ table

***************************************************************************************************/
PROCEDURE Load_Emps(
            p_file_name                    VARCHAR2,       -- original file name
            p_file_count                   PLS_INTEGER) IS -- number of lines in file

  CUSTOM_EXCEP                  EXCEPTION;
  PRAGMA EXCEPTION_INIT(CUSTOM_EXCEP, -20000);

  BATCH_JOB_ID                   CONSTANT VARCHAR2(30) := 'LOAD_EMPS';
  API_LOG_ID                     CONSTANT PLS_INTEGER := Log_Set.Entry_Point(
                                                                     p_plsql_unit => $$PLSQL_UNIT,
                                                                     p_api_nm     => BATCH_JOB_ID,
                                                                     p_config_key => 'BATCH');
  FUNCTION ins_Jbs(p_records_loaded    PLS_INTEGER,
                   p_records_failed_et PLS_INTEGER,
                   p_records_failed_db PLS_INTEGER,
                   p_start_time        DATE,
                   p_job_status        VARCHAR2)
                   RETURN              PLS_INTEGER IS

    PRAGMA AUTONOMOUS_TRANSACTION;
    l_uid                   PLS_INTEGER;

  BEGIN

    l_uid := DML_API_Jobs.Ins_Jbs(
                          p_batch_job_id      => BATCH_JOB_ID,
                          p_file_name         => p_file_name,
                          p_records_loaded    => p_records_loaded,
                          p_records_failed_et => p_records_failed_et,
                          p_records_failed_db => p_records_failed_db,
                          p_start_time        => p_start_time,
                          p_end_time          => SYSDATE,
                          p_job_status        => p_job_status);

    COMMIT;
    RETURN l_uid;

  END ins_Jbs;

  PROCEDURE check_Not_Processed IS
    l_dummy PLS_INTEGER;
  BEGIN

    SELECT 1 INTO l_dummy
      FROM job_statistics
     WHERE batch_job_id = BATCH_JOB_ID
       AND file_name    = p_file_name
       AND job_status   = 'S';
    Log_Set.Raise_Error('File has already been processed successfully!');

  EXCEPTION
    WHEN NO_DATA_FOUND THEN NULL;
  END check_Not_Processed;

  FUNCTION merge_Emp
    RETURN                                   PLS_INTEGER IS
  BEGIN

    MERGE INTO hr.employees tgt
    USING (SELECT employee_id,
                 last_name,
                 email,
                 hire_date,
                 job_id,
                 To_Number(salary) salary
            FROM employees_et
           MINUS
          SELECT To_Char(employee_id),
                 last_name,
                 email,
                 To_Char (hire_date, 'DD-MON-YYYY'),
                 job_id,
                 salary
            FROM hr.employees) src
       ON (tgt.employee_id = src.employee_id)
     WHEN MATCHED THEN
    UPDATE SET   tgt.last_name          = src.last_name,
                 tgt.email              = src.email,
                 tgt.hire_date          = To_Date (src.hire_date, 'DD-MON-YYYY'),
                 tgt.job_id             = src.job_id,
                 tgt.salary             = src.salary,
                 tgt.update_date        = SYSDATE,
                 tgt.ttid               = Nvl2(SYS_Context('TRAPIT_CTX', 'MODE'), SYS_Context('userenv', 'sessionid'), NULL)
    LOG ERRORS INTO hr.err$_employees REJECT LIMIT UNLIMITED;
    RETURN SQL%ROWCOUNT;

  END merge_Emp;

  FUNCTION insert_Emp
    RETURN                                   PLS_INTEGER IS
  BEGIN

    INSERT INTO hr.employees(
                   employee_id,
                   last_name,
                   email,
                   hire_date,
                   job_id,
                   salary,
                   update_date,
                   ttid
    )
    SELECT         employees_seq.NEXTVAL,
                   src.last_name,
                   src.email,
                   To_Date (src.hire_date, 'DD-MON-YYYY'),
                   src.job_id,
                   src.salary,
                   SYSDATE,
                   Nvl2(SYS_Context('TRAPIT_CTX', 'MODE'), SYS_Context('userenv', 'sessionid'), NULL)
      FROM employees_et src
     WHERE src.employee_id IS NULL
    LOG ERRORS INTO hr.err$_employees REJECT LIMIT UNLIMITED;
    RETURN SQL%ROWCOUNT;

  END insert_Emp;

  PROCEDURE insert_Err(
              p_start_time                   DATE,
              p_n_updated                    PLS_INTEGER,
              p_n_inserted                   PLS_INTEGER) IS
    l_n_errors_et           PLS_INTEGER;
    l_n_errors_db           PLS_INTEGER;
    l_fail_threshold_perc   PLS_INTEGER;
    l_uid                   PLS_INTEGER;
    l_status                VARCHAR2(1) := 'S';
  BEGIN

    SELECT fail_threshold_perc
      INTO l_fail_threshold_perc
      FROM batch_jobs
     WHERE batch_job_id = BATCH_JOB_ID;
    Log_Set.Put_Line(p_log_id => API_LOG_ID, p_line_text => 'insert_Err, l_fail_threshold_perc: ' || l_fail_threshold_perc);
  
    INSERT INTO hr.err$_employees (
           ORA_ERR_MESG$,
           ORA_ERR_OPTYP$,
           employee_id,
           last_name,
           email,
           hire_date,
           job_id,
           salary,
           ttid
    )
    SELECT 'Employee not found',
           'PK',
           src.employee_id,
           src.last_name,
           src.email,
           src.hire_date,
           src.job_id,
           src.salary,
           Nvl2(SYS_Context('TRAPIT_CTX', 'MODE'), SYS_Context('userenv', 'sessionid'), NULL)
      FROM employees_et src
      LEFT JOIN hr.employees tgt
          ON tgt.employee_id = src.employee_id
     WHERE src.employee_id IS NOT NULL
       AND tgt.employee_id IS NULL;
    Log_Set.Put_Line(p_log_id => API_LOG_ID, p_line_text => 'insert_Err, INSERT err$_employees: ' || SQL%ROWCOUNT);

    SELECT COUNT(*) INTO l_n_errors_db
      FROM hr.err$_employees
     WHERE job_statistic_id IS NULL;
    Log_Set.Put_Line(p_log_id => API_LOG_ID, p_line_text => 'insert_Err, l_n_errors_db: ' || l_n_errors_db);
  
    SELECT p_file_count - COUNT(*) INTO l_n_errors_et
      FROM employees_et;
    Log_Set.Put_Line(p_log_id => API_LOG_ID, p_line_text => 'insert_Err, l_n_errors_et: ' || l_n_errors_et);
  
    IF 100 * (l_n_errors_et + l_n_errors_db) / (l_n_errors_et + l_n_errors_db + p_n_inserted + p_n_updated) >= l_fail_threshold_perc THEN
  
      l_status := 'F';
  
    END IF;

    l_uid := ins_Jbs(p_records_loaded    => p_n_inserted + p_n_updated,
                     p_records_failed_et => l_n_errors_et,
                     p_records_failed_db => l_n_errors_db,
                     p_start_time        => p_start_time,
                     p_job_status        => l_status);
    Log_Set.Put_Line(p_log_id => API_LOG_ID, p_line_text => 'insert_Err, ins_Jbs, l_uid: ' || l_uid);

    UPDATE hr.err$_employees
       SET job_statistic_id = l_uid
     WHERE job_statistic_id IS NULL;
    Log_Set.Put_Line(p_log_id => API_LOG_ID, p_line_text => 'insert_Err, UPDATE err$_employees: ' || SQL%ROWCOUNT);

    IF l_status = 'F'  THEN
      Log_Set.Raise_Error('Batch failed with too many invalid records!');
    END IF;
    
  END insert_Err;

  PROCEDURE main IS
    l_n_updated             PLS_INTEGER;
    l_n_inserted            PLS_INTEGER;
    l_start_time            DATE := SYSDATE;
  BEGIN

    check_Not_Processed;
    Log_Set.Put_Line(p_log_id => API_LOG_ID, p_line_text => 'check_Not_Processed done');
    l_n_updated := merge_Emp;
    Log_Set.Put_Line(p_log_id => API_LOG_ID, p_line_text => 'merge_Emp updated: ' || l_n_updated);
    l_n_inserted := insert_Emp;
    Log_Set.Put_Line(p_log_id => API_LOG_ID, p_line_text => 'insert_Emp inserted: ' || l_n_inserted);
    insert_Err(p_start_time   => l_start_time,
               p_n_updated    => l_n_updated, 
               p_n_inserted   => l_n_inserted);

  END main;

BEGIN

  main;
  Log_Set.Exit_Point(p_log_id => API_LOG_ID,
                     p_text   => BATCH_JOB_ID);

EXCEPTION
  WHEN CUSTOM_EXCEP THEN
    RAISE;
  WHEN OTHERS THEN
    Log_Set.Write_Other_Error;

END Load_Emps;

END Emp_Batch;
/
SHO ERR
