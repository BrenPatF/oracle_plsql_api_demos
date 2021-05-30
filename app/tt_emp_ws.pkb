CREATE OR REPLACE PACKAGE BODY TT_Emp_WS AS
/***************************************************************************************************
Name: tt_emp_ws.pkb                     Author: Brendan Furey                      Date: 21-Sep-2019

Package body component in the Oracle PL/SQL API Demos module. 

The module demonstrates instrumentation and logging, code timing, and unit testing of PL/SQL APIs,
using example APIs writtten against Oracle's HR demo schema. 

    GitHub: https://github.com/BrenPatF/https://github.com/BrenPatF/oracle_plsql_api_demos

There are two main packages and a view, with corresponding unit test packages, a DML API package
in app schema, and a DML API package in lib schema. Note that installation of this module is
dependent on pre-requisite installs of other modules as described in the README

BASE/TEST PROGRAM UNITS
====================================================================================================
|  Package/View    |  Test Package     |  Notes                                                    |
|==================================================================================================|
|  LIB SCHEMA                                                                                      |
|--------------------------------------------------------------------------------------------------|
|  DML_API_Jobs    |  N.A.             |  DML for batch_jobs, job_statistics                       |
|--------------------------------------------------------------------------------------------------|
|  APP SCHEMA                                                                                      |
|--------------------------------------------------------------------------------------------------|
|  DML_API_TT_HR   |  N.A.             |  DML for hr tables for unit testing                       |
|------------------|-------------------|-----------------------------------------------------------|
|  Emp_WS          | *TT_Emp_WS*       |  Save_Emps: Save a list of new employees                  |
|                  |                   |  Get_Dept_Emps: Get department and employee details       |
|------------------|-------------------|-----------------------------------------------------------|
|  Emp_Batch       |  TT_Emp_Batch     |  Load_Emps: Load new/updated employees from file          |
|------------------|-------------------|-----------------------------------------------------------|
|  HR_Test_View_V  |  TT_View_Drivers  |  HR_Test_View_V: View for department and employee details |
====================================================================================================
This file has the TT_Emp_WS package body

***************************************************************************************************/

/***************************************************************************************************

Purely_Wrap_Save_Emps: Unit test wrapper function for Emp_WS.Save_Emps

    Returns the 'actual' outputs, given the inputs for a scenario, with the signature expected for
    the Math Function Unit Testing design pattern, namely:

      Input parameter: 3-level list (type L3_chr_arr) with test inputs as group/record/field
      Return Value: 2-level list (type L2_chr_arr) with test outputs as group/record (with record as
                   delimited fields string)

***************************************************************************************************/
FUNCTION Purely_Wrap_Save_Emps(
              p_inp_3lis                     L3_chr_arr)   -- input 3-list (group, record, field)
              RETURN                         L2_chr_arr IS -- output 2-list (group, record)

  -- do_Save makes the ws call and returns o/p array
  FUNCTION do_Save
              RETURN                                emp_out_arr IS -- output list of lists (group, record)
    l_emp_in_lis        emp_in_arr := emp_in_arr();
    l_emp_out_lis       emp_out_arr;
  BEGIN
    FOR i IN 1..p_inp_3lis(1).COUNT LOOP
      l_emp_in_lis.EXTEND;
      l_emp_in_lis (l_emp_in_lis.COUNT) := emp_in_rec (p_inp_3lis(1)(i)(1), 
                                                       p_inp_3lis(1)(i)(2), 
                                                       p_inp_3lis(1)(i)(3), 
                                                       p_inp_3lis(1)(i)(4));
    END LOOP;
    Emp_WS.Save_Emps (
              p_emp_in_lis        => l_emp_in_lis,
              x_emp_out_lis       => l_emp_out_lis);
    RETURN l_emp_out_lis;
  END do_Save;

  -- get_Tab_Lis: gets the database records inserted into a generic list of strings
  FUNCTION get_Tab_Lis(
              p_last_seq_val                        PLS_INTEGER)  -- employees_seq offset
              RETURN                                L1_chr_arr IS -- list of strings
    l_tab_lis         L1_chr_arr;
  BEGIN

    SELECT Utils.Join_Values(employee_id - p_last_seq_val, last_name, email, job_id, salary)
      BULK COLLECT INTO l_tab_lis
      FROM employees
     ORDER BY employee_id;
    RETURN l_tab_lis;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN NULL;
  END get_Tab_Lis;

  -- get_Arr_Lis converts the ws output array into a generic list of strings
  FUNCTION get_Arr_Lis(
              p_last_seq_val                        PLS_INTEGER,  -- employees_seq offset
              p_emp_out_lis                         emp_out_arr)  -- employee output array (input here)
              RETURN                                L1_chr_arr IS -- list of strings
    l_arr_lis     L1_chr_arr;
  BEGIN
    IF p_emp_out_lis IS NOT NULL THEN
      l_arr_lis := L1_chr_arr();
      l_arr_lis.EXTEND(p_emp_out_lis.COUNT);
      FOR i IN 1..p_emp_out_lis.COUNT LOOP
        l_arr_lis(i) := Utils.Join_Values(
            p_emp_out_lis(i).employee_id - 
                CASE WHEN p_emp_out_lis(i).employee_id > 0 THEN p_last_seq_val ELSE 0 END,
            p_emp_out_lis(i).description);
      END LOOP;
    END IF;
    RETURN l_arr_lis;
  END get_Arr_Lis;

  -- making main block its own function avoids sharing writeable variables
  FUNCTION main_PWA RETURN L2_chr_arr IS
    l_emp_out_lis       emp_out_arr;
    l_tab_lis           L1_chr_arr;
    l_arr_lis           L1_chr_arr;
    l_err_lis           L1_chr_arr;
    l_last_seq_val      PLS_INTEGER;
  BEGIN
      SELECT employees_seq.NEXTVAL
      INTO l_last_seq_val
      FROM DUAL;

    BEGIN
      l_emp_out_lis := do_Save;
      l_tab_lis := get_Tab_Lis(p_last_seq_val => l_last_seq_val);
      l_arr_lis := get_Arr_Lis(p_last_seq_val => l_last_seq_val, p_emp_out_lis => l_emp_out_lis);
    EXCEPTION
      WHEN OTHERS THEN
        l_err_lis := L1_chr_arr(SQLERRM);
    END;
    ROLLBACK;
    RETURN L2_chr_arr(l_tab_lis, l_arr_lis, l_err_lis);
  END main_PWA;

BEGIN

  RETURN main_PWA;

END Purely_Wrap_Save_Emps;

/***************************************************************************************************

Purely_Wrap_Get_Dept_Emps: Unit test wrapper function for Emp_WS.Get_Dept_Emps

    Returns the 'actual' outputs, given the inputs for a scenario, with the signature expected for
    the Math Function Unit Testing design pattern, namely:

      Input parameter: 3-level list (type L3_chr_arr) with test inputs as group/record/field
      Return Value: 2-level list (type L2_chr_arr) with test outputs as group/record (with record as
                   delimited fields string)

***************************************************************************************************/
FUNCTION Purely_Wrap_Get_Dept_Emps(
              p_inp_3lis                     L3_chr_arr)   -- input 3-list (group, record, field)
              RETURN                         L2_chr_arr IS -- output 2-list (group, record)

  -- Create test records for a given scenario for testing Get_Dept_Emps
  PROCEDURE setup_DB(
              p_inp_2lis                     L2_chr_arr) IS -- input list of employees

    l_emp_id            PLS_INTEGER;
    l_mgr_id            PLS_INTEGER;

  BEGIN

    FOR i IN 1..p_inp_2lis.COUNT LOOP

      l_emp_id := DML_API_TT_HR.Ins_Emp(
                            p_emp_ind  => i,
                            p_dep_id   => p_inp_2lis(i)(8),
                            p_mgr_id   => l_mgr_id,
                            p_job_id   => p_inp_2lis(i)(5),
                            p_salary   => p_inp_2lis(i)(6));
      IF i = 1 THEN
        l_mgr_id := l_emp_id;
      END IF;

    END LOOP;

  END setup_DB;

  -- making main block its own function avoids sharing writeable variables
  FUNCTION main_PWA RETURN L2_chr_arr IS
    l_act_2lis        L2_chr_arr := L2_chr_arr();
    l_emp_csr         SYS_REFCURSOR;
  BEGIN

    setup_DB(p_inp_3lis(1));

    Emp_WS.Get_Dept_Emps(p_dep_id  => p_inp_3lis(2)(1)(1),
                         x_emp_csr => l_emp_csr);
    l_act_2lis.EXTEND;
    l_act_2lis(1) := Utils.Cursor_To_List(x_csr => l_emp_csr);
    ROLLBACK;
    RETURN l_act_2lis;

  END main_PWA;

BEGIN

  RETURN main_PWA;

END Purely_Wrap_Get_Dept_Emps;

END TT_Emp_WS;
/
SHO ERR