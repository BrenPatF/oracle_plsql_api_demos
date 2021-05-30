CREATE OR REPLACE PACKAGE TT_View_Drivers AS
/***************************************************************************************************
Name: tt_view_drivers.pks               Author: Brendan Furey                      Date: 21-Sep-2019

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
-------------------|-------------------|-----------------------------------------------------------|
|  HR_Test_View_V  | *TT_View_Drivers* |  HR_Test_View_V: View for department and employee details |
====================================================================================================
This file has the TT_View_Drivers package spec.

***************************************************************************************************/

  FUNCTION Purely_Wrap_HR_Test_View_V(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;

END TT_View_Drivers;
/
