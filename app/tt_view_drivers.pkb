CREATE OR REPLACE PACKAGE BODY TT_View_Drivers AS
/***************************************************************************************************
Name: tt_view_drivers.pkb               Author: Brendan Furey                      Date: 21-Sep-2019

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
|==================================================================================================|
|  LIB SCHEMA                                                                                      |
|--------------------------------------------------------------------------------------------------|
|  DML_API_Jobs    |  N.A.             |  DML for batch_jobs, job_statistics                       |
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
|  HR_Test_View_V  | *TT_View_Drivers* |  HR_Test_View_V: View for department and employee details |
====================================================================================================
This file has the TT_View_Drivers package body.

***************************************************************************************************/
  VIEW_NAME             CONSTANT VARCHAR2(61) := 'HR_Test_View_V';
  PROC_NM               CONSTANT VARCHAR2(30) := 'HR_Test_View_V';
  SEL_LIS               CONSTANT L1_chr_arr := L1_chr_arr('last_name', 'department_name', 'manager',
                                                          'salary', 'sal_rat', 'sal_rat_g');

/***************************************************************************************************

HR_Test_View_V: TRAPIT procedure to test view HR_Test_View_V

***************************************************************************************************/

-- Create test records for a given scenario for testing view
PROCEDURE setup_DB(
            p_inp_2lis                     L2_chr_arr) IS -- input list, employees
  l_emp_id            PLS_INTEGER;
  l_mgr_id            PLS_INTEGER;
BEGIN
  FOR i IN 1..p_inp_2lis.COUNT LOOP
    l_emp_id := DML_API_TT_HR.Ins_Emp (
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

/***************************************************************************************************
Purely_Wrap_HR_Test_View_V: Unit test wrapper function for Utils.View_To_List

    Returns the 'actual' outputs, given the inputs for a scenario, with the signature expected for
    the Math Function Unit Testing design pattern, namely:

      Input parameter: 3-level list (type L3_chr_arr) with test inputs as group/record/field
      Return Value: 2-level list (type L2_chr_arr) with test outputs as group/record (with record as
                   delimited fields string)
***************************************************************************************************/
FUNCTION Purely_Wrap_HR_Test_View_V(
            p_inp_3lis                     L3_chr_arr)   -- input 3-list (group, record, field)
            RETURN                         L2_chr_arr IS -- output 2-list (group, record)
  l_act_2lis        L2_chr_arr := L2_chr_arr();
BEGIN
  setup_DB(p_inp_3lis(1));
  l_act_2lis.EXTEND;
  l_act_2lis(1) := Utils.View_To_List(
                          p_view_name         => VIEW_NAME,
                          p_sel_value_lis     => SEL_LIS,
                          p_where             => p_inp_3lis(2)(1)(1));
  ROLLBACK;
  RETURN l_act_2lis;

END Purely_Wrap_HR_Test_View_V;

END TT_View_Drivers;
/
SHO ERR