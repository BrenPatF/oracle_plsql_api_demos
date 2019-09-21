CREATE OR REPLACE PACKAGE BODY TT_Emp_Batch AS
/***************************************************************************************************
Name: tt_emp_batch.pkb                        Author: Brendan Furey                Date: 21-Sep-2019

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
|  Emp_Batch       | *TT_Emp_Batch*    |  Load_Emps: Load new/updated employees from file          |
----------------------------------------------------------------------------------------------------
|  HR_Test_View_V  |  TT_View_Drivers  |  HR_Test_View_V: View for department and employee details |
====================================================================================================
This file has the TT_Emp_Batch package body.

***************************************************************************************************/

/***************************************************************************************************

Load_Emps: Main procedure for testing Emp_Batch.Load_Emps procedure

***************************************************************************************************/
PROCEDURE Load_Emps IS

  PROC_NM                 CONSTANT VARCHAR2(30) := 'Load_Emps';
  FMT_DATE                CONSTANT VARCHAR2(30) := 'DD-MON-YYYY';
  FMT_DATETIME            CONSTANT VARCHAR2(30) := 'DD-MON-YYYY hh24:mi:ss';
  DAT_NAME                CONSTANT VARCHAR2(20) := 'employees.dat';
  SECONDS_IN_DAY          CONSTANT PLS_INTEGER := 86400;


  l_act_3lis                       L3_chr_arr := L3_chr_arr();
  l_sces_4lis                      L4_chr_arr;
  l_scenarios                      Trapit.scenarios_rec;

  -- Database setup procedure for testing Load_Emps
  FUNCTION setup_DB(
              p_file_name                    VARCHAR2,     -- data file inputs
              p_fil_2lis                     L2_chr_arr,   -- data file inputs
              p_emp_2lis                     L2_chr_arr,   -- employees inputs
              p_jbs_2lis                     L2_chr_arr)   -- job statistics inputs
              RETURN                         L1_num_arr IS -- 2-element output list (emp, jbs last sequence #s)
    l_last_seq_emp       PLS_INTEGER;
    l_last_seq_jbs       PLS_INTEGER;
    l_emp_id             PLS_INTEGER;
    l_fil_lis            L1_chr_arr := L1_chr_arr();
    l_line               VARCHAR2(32767);
    l_dummy              PLS_INTEGER;
  BEGIN

    SELECT job_statistics_seq.NEXTVAL
      INTO l_last_seq_jbs
      FROM DUAL;

    IF p_jbs_2lis IS NOT NULL THEN

      FOR i IN 1..p_jbs_2lis.COUNT LOOP

        l_dummy := DML_API_Jobs.Ins_jbs (
                            p_batch_job_id      => p_jbs_2lis(i)(2),
                            p_file_name         => p_jbs_2lis(i)(3),
                            p_records_loaded    => p_jbs_2lis(i)(4),
                            p_records_failed_et => p_jbs_2lis(i)(5),
                            p_records_failed_db => p_jbs_2lis(i)(6),
                            p_start_time        => To_Date(p_jbs_2lis(i)(7), FMT_DATETIME),
                            p_end_time          => To_Date(p_jbs_2lis(i)(8), FMT_DATETIME),
                            p_job_status        => p_jbs_2lis(i)(9));
      END LOOP;

    END IF;

    SELECT employees_seq.NEXTVAL
      INTO l_last_seq_emp
      FROM DUAL;

    IF p_emp_2lis IS NOT NULL THEN

      FOR i IN 1..p_emp_2lis.COUNT LOOP

        l_dummy := DML_API_TT_HR.Ins_Emp (
                            p_emp_ind     => i,
                            p_dep_id      => p_emp_2lis(i)(8),
                            p_mgr_id      => p_emp_2lis(i)(7),
                            p_job_id      => p_emp_2lis(i)(5),
                            p_salary      => p_emp_2lis(i)(6),
                            p_last_name   => p_emp_2lis(i)(2),
                            p_email       => p_emp_2lis(i)(3),
                            p_hire_date   => p_emp_2lis(i)(4),
                            p_update_date => To_Date(p_emp_2lis(i)(9), FMT_DATETIME));
      END LOOP;

    END IF;

    l_fil_lis.EXTEND(p_fil_2lis.COUNT);
    FOR i IN 1..p_fil_2lis.COUNT LOOP
      l_line := p_fil_2lis(i)(1);
      l_emp_id := Substr(l_line, 1, Instr(l_line, ',', 1) - 1);
      IF l_emp_id IS NOT NULL THEN
        l_line := (l_emp_id + l_last_seq_emp) || Substr(l_line, Instr(l_line, ',', 1));
      END IF;
      l_fil_lis(i) := l_line;
    END LOOP;
    Utils.Write_File(DAT_NAME, l_fil_lis);
    RETURN L1_num_arr(l_last_seq_emp, l_last_seq_jbs);

  END setup_DB;

  -- Get_Tab_Lis: gets the database records inserted into a generic list of strings
  FUNCTION Get_Tab_Lis(
              p_last_seq_emp                 PLS_INTEGER)  -- last employees sequence #
              RETURN                         L1_chr_arr IS -- output list of records
    l_tab_lis           L1_chr_arr;
  BEGIN

    SELECT Utils.Join_Values(
               employee_id - p_last_seq_emp,
               last_name,
               email,
               To_Char(hire_date, FMT_DATE),
               job_id,
               salary,
               To_Char(update_date, FMT_DATETIME),
               SECONDS_IN_DAY*(SYSDATE - update_date))
      BULK COLLECT INTO l_tab_lis
      FROM employees
     ORDER BY employee_id;
    RETURN l_tab_lis;

  END Get_Tab_Lis;

  -- Get_Err_Lis: gets the database error records inserted into a generic list of strings
  FUNCTION Get_Err_Lis(
              p_last_seq_emp                 PLS_INTEGER,  -- last employees sequence #
              p_last_seq_jbs                 PLS_INTEGER)  -- last job_statistics sequence #
              RETURN                         L1_chr_arr IS -- output list of records
    l_err_lis           L1_chr_arr;
  BEGIN

    SELECT Utils.Join_Values(
              job_statistic_id - p_last_seq_jbs,
              ORA_ERR_TAG$,
              Replace(ORA_ERR_MESG$, Chr(10)),
              ORA_ERR_OPTYP$,
              employee_id - p_last_seq_emp,
              last_name,
              email,
              hire_date, -- character, formatted via nls_date_format
              job_id,
              salary)
    BULK COLLECT INTO l_err_lis
    FROM err$_employees;
    RETURN l_err_lis;

  END Get_Err_Lis;

  -- Get_Jbs_Lis: gets the job_statistics_v records inserted into a generic list of strings
  FUNCTION Get_Jbs_Lis(
              p_last_seq_jbs                 PLS_INTEGER)  -- last job_statistics sequence #
              RETURN                         L1_chr_arr IS -- output list of records
    l_jbs_lis     L1_chr_arr;
  BEGIN

    SELECT Utils.Join_Values(
               job_statistic_id - p_last_seq_jbs,
               batch_job_id,
               file_name,
               records_loaded,
               records_failed_et,
               records_failed_db,
               To_Char(start_time, FMT_DATETIME),
               To_Char(end_time, FMT_DATETIME),
               SECONDS_IN_DAY*(SYSDATE - start_time),
               SECONDS_IN_DAY*(SYSDATE - end_time),
               job_status)
      BULK COLLECT INTO l_jbs_lis
      FROM job_statistics_v
     ORDER BY job_statistic_id;
    RETURN l_jbs_lis;

  END Get_Jbs_Lis;

  /***************************************************************************************************

  purely_Wrap_API: Design pattern has the API call wrapped in a 'pure' function, called once per 
                   scenario, with the output 'actuals' array including everything affected by the API,
                   whether as output parameters, or on database tables, etc. The inputs are also
                   extended from the API parameters to include any other effective inputs

  ***************************************************************************************************/
  FUNCTION purely_Wrap_API(
              p_inp_3lis                     L3_chr_arr)   -- input 3-list (group, record, field)
              RETURN                         L2_chr_arr IS -- output 2-list (group, record)

    l_tab_lis           L1_chr_arr;
    l_err_lis           L1_chr_arr;
    l_jbs_lis           L1_chr_arr;
    l_exc_lis           L1_chr_arr;
    l_last_seq_emp      PLS_INTEGER;
    l_last_seq_jbs      PLS_INTEGER;
    l_seq_lis           L1_num_arr;

  BEGIN

    l_seq_lis:= setup_DB(p_file_name => p_inp_3lis(1)(1)(1), -- data file name
                         p_fil_2lis  => p_inp_3lis(2),       -- data file inputs
                         p_emp_2lis  => p_inp_3lis(5),       -- employees
                         p_jbs_2lis  => p_inp_3lis(4));      -- job_statistics
    l_last_seq_emp := l_seq_lis(1);
    l_last_seq_jbs := l_seq_lis(2);
    BEGIN

      Emp_Batch.Load_Emps(p_file_name  => p_inp_3lis(1)(1)(1), 
                          p_file_count => p_inp_3lis(1)(1)(2));

    EXCEPTION
      WHEN OTHERS THEN
        l_exc_lis := L1_chr_arr (SQLERRM);
    END;
    Utils.Delete_File(DAT_NAME);

    l_tab_lis := Get_Tab_Lis(p_last_seq_emp => l_last_seq_emp);
    l_err_lis := Get_Err_Lis(p_last_seq_emp => l_last_seq_emp, 
                             p_last_seq_jbs => l_last_seq_jbs);
    l_jbs_lis := Get_Jbs_Lis(p_last_seq_jbs => l_last_seq_jbs);

    ROLLBACK;

    DELETE err$_employees; -- DML logging does auto transaction
    DELETE job_statistics_v; -- job statistics done via auto transaction
    COMMIT;
    RETURN  L2_chr_arr(l_tab_lis,
                       l_err_lis,
                       l_jbs_lis,
                       l_exc_lis);

  END purely_Wrap_API;

BEGIN
--
-- Every testing main section should be similar to this, with reading of the scenarios from JSON
-- via Trapit into array, any initial setup required, then loop over scenarios making a 'pure'
-- call to specific, local purely_Wrap_API, finally passing output array to Trapit to write the
-- output JSON file
--
  l_scenarios := Trapit.Get_Inputs(p_package_nm   => $$PLSQL_UNIT,
                                   p_procedure_nm => PROC_NM);
  l_sces_4lis := l_scenarios.scenarios_4lis;
  l_act_3lis.EXTEND(l_sces_4lis.COUNT);

  FOR i IN 1..l_sces_4lis.COUNT LOOP

    l_act_3lis(i) := purely_Wrap_API(l_sces_4lis(i));

  END LOOP;

  Trapit.Set_Outputs(p_package_nm    => $$PLSQL_UNIT,
                     p_procedure_nm  => PROC_NM,
                     p_act_3lis      => l_act_3lis);

END Load_Emps;

END TT_Emp_Batch;
/
SHO ERR
