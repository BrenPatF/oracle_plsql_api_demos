CREATE OR REPLACE PACKAGE BODY DML_API_TT_HR AS
/***************************************************************************************************
Name: dml_api_tt_hr.pkb                    Author: Brendan Furey                   Date: 21-Sep-2019

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
| *DML_API_TT_HR*  |  N.A.             |  DML for hr tables for unit testing                       |
----------------------------------------------------------------------------------------------------
|  Emp_WS          |  TT_Emp_WS        |  Save_Emps: Save a list of new employees                  |
|                  |                   |  Get_Dept_Emps: Get department and employee details       |
----------------------------------------------------------------------------------------------------
| Emp_Batch      |  TT_Emp_Batch     |  Load_Emps: Load new/updated employees from file          |
----------------------------------------------------------------------------------------------------
|  HR_Test_View_V  |  TT_View_Drivers  |  HR_Test_View_V: View for department and employee details |
====================================================================================================
This file has the DML_API_TT_HR package body.

***************************************************************************************************/
FUNCTION Ins_Emp(
           p_emp_ind                       PLS_INTEGER,           -- employee index
           p_dep_id                        PLS_INTEGER,           -- department id
           p_mgr_id                        PLS_INTEGER,           -- manager id
           p_job_id                        VARCHAR2,              -- job id
           p_salary                        PLS_INTEGER,           -- salary
           p_last_name                     VARCHAR2 DEFAULT NULL, -- last name
           p_email                         VARCHAR2 DEFAULT NULL, -- email address
           p_hire_date                     DATE DEFAULT SYSDATE,  -- hire date
           p_update_date                   DATE DEFAULT SYSDATE)  -- update date
           RETURN                          PLS_INTEGER IS         -- employee id created
  l_emp_id PLS_INTEGER;
BEGIN

  INSERT INTO employees (
        employee_id,
        last_name,
        email,
        hire_date,
        job_id,
        salary,
        manager_id,
        department_id,
        update_date,
        ttid
  ) VALUES (
        employees_seq.NEXTVAL,
        Nvl (p_last_name, c_ln_pre || p_emp_ind),
        Nvl (p_email, c_em_pre || p_emp_ind),
        p_hire_date,
        p_job_id,
        p_salary,
        p_mgr_id,
        p_dep_id,
        p_update_date,
        SYS_Context('userenv', 'sessionid')
  ) RETURNING employee_id
         INTO l_emp_id;

  RETURN l_emp_id;

END Ins_Emp;

END DML_API_TT_HR;
/
SHO ERR
