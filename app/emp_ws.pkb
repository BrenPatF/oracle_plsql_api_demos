CREATE OR REPLACE PACKAGE BODY Emp_WS AS
/***************************************************************************************************
Name: emp_ws.pkb                        Author: Brendan Furey                      Date: 21-Sep-2019

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
| *Emp_WS*         |  TT_Emp_WS        |  Save_Emps: Save a list of new employees                  |
|                  |                   |  Get_Dept_Emps: Get department and employee details       |
|------------------|-------------------|-----------------------------------------------------------|
|  Emp_Batch       |  TT_Emp_Batch     |  Load_Emps: Load new/updated employees from file          |
|------------------|-------------------|-----------------------------------------------------------|
|  HR_Test_View_V  |  TT_View_Drivers  |  HR_Test_View_V: View for department and employee details |
====================================================================================================
This file has the Emp_WS package body.

***************************************************************************************************/

/***************************************************************************************************

Save_Emps: Save a list of new employees to database, returning list of ids with same in words,
           or zero plus error message, in output list

***************************************************************************************************/
PROCEDURE Save_Emps(
            p_emp_in_lis                   emp_in_arr,     -- list of employees to insert
            x_emp_out_lis              OUT emp_out_arr) IS -- list of employee results
  API_NM                         CONSTANT VARCHAR2(30) := 'Save_Emps';
  API_LOG_ID                     CONSTANT PLS_INTEGER := Log_Set.Entry_Point(
                                                                     p_plsql_unit => $$PLSQL_UNIT,
                                                                     p_api_nm     => API_NM,
                                                                     p_config_key => 'APPINFO');

  l_emp_out_lis        emp_out_arr;
  bulk_errors          EXCEPTION;
  PRAGMA               EXCEPTION_INIT (bulk_errors, -24381);
  n_err                PLS_INTEGER := 0;

BEGIN
  FORALL i IN 1..p_emp_in_lis.COUNT
    SAVE EXCEPTIONS
    INSERT INTO employees (
        employee_id,
        last_name,
        email,
        hire_date,
        job_id,
        salary,
        ttid
    ) VALUES (
        employees_seq.NEXTVAL,
        p_emp_in_lis(i).last_name,
        p_emp_in_lis(i).email,
        SYSDATE,
        p_emp_in_lis(i).job_id,
        p_emp_in_lis(i).salary,
        Nvl2(SYS_Context('TRAPIT_CTX', 'MODE'), SYS_Context('userenv', 'sessionid'), NULL)
    )
    RETURNING emp_out_rec(employee_id, To_Char(To_Date(employee_id,'J'),'JSP')) 
        BULK COLLECT INTO x_emp_out_lis;
  Log_Set.Exit_Point(p_log_id => API_LOG_ID,
                     p_text   => API_NM || ', ' || x_emp_out_lis.COUNT || ' inserted');
EXCEPTION
  WHEN bulk_errors THEN

    l_emp_out_lis := x_emp_out_lis;

    FOR i IN 1 .. SQL%Bulk_Exceptions.COUNT LOOP
      IF i > x_emp_out_lis.COUNT THEN
        x_emp_out_lis.Extend;
      END IF;
      x_emp_out_lis (SQL%Bulk_Exceptions(i).Error_Index) := emp_out_rec (0, SQLERRM (- (SQL%Bulk_Exceptions(i).Error_Code)));
    END LOOP;
    Log_Set.Put_Line(p_log_id => API_LOG_ID, p_line_text => 'sql%BULK_EXCEPTIONS.COUNT: ' || sql%BULK_EXCEPTIONS.COUNT);

    FOR i IN 1..p_emp_in_lis.COUNT LOOP
      IF i > x_emp_out_lis.COUNT THEN
        x_emp_out_lis.Extend;
      END IF;
      IF x_emp_out_lis(i).employee_id = 0 THEN
        n_err := n_err + 1;
      ELSE
        x_emp_out_lis(i) := l_emp_out_lis(i - n_err);
      END IF;
    END LOOP;
    Log_Set.Exit_Point(p_log_id => API_LOG_ID,
                       p_text   => API_NM || ', x_emp_out_lis.COUNT:  ' || x_emp_out_lis.COUNT);
  WHEN OTHERS THEN
    Log_Set.Write_Other_Error;

END Save_Emps;

/***************************************************************************************************

Get_Dept_Emps: For given department id, return department and employee details including salary 
               ratios, excluding employees with job 'AD_ASST', and returning none if global salary
               total < 1600, via ref cursor

***************************************************************************************************/
PROCEDURE Get_Dept_Emps(
            p_dep_id                       PLS_INTEGER,      -- department id
            x_emp_csr                  OUT SYS_REFCURSOR) IS -- departm, employee details cursor
  API_NM                         CONSTANT VARCHAR2(30) := 'Get_Dept_Emps';
  API_LOG_ID                     CONSTANT PLS_INTEGER := Log_Set.Entry_Point(
                                                                     p_plsql_unit => $$PLSQL_UNIT,
                                                                     p_api_nm     => API_NM,
                                                                     p_config_key => 'APPINFO');
BEGIN

  OPEN x_emp_csr FOR
  WITH all_emps AS (
        SELECT Avg(salary) avg_sal, SUM(salary) sal_tot_g
          FROM employees e
  )
  SELECT e.last_name, d.department_name, m.last_name manager, e.salary,
         Round(e.salary / Avg(e.salary) OVER (), 2) sal_rat,
         Round(e.salary / a.avg_sal, 2) sal_rat_g
    FROM all_emps a
   CROSS JOIN employees e
    JOIN departments d
      ON d.department_id = e.department_id
    LEFT JOIN employees m
      ON m.employee_id = e.manager_id
   WHERE e.job_id != 'AD_ASST'
     AND a.sal_tot_g >= 1600
     AND d.department_id = p_dep_id;
  Log_Set.Exit_Point(p_log_id => API_LOG_ID,
                     p_text   => API_NM);

EXCEPTION
  WHEN OTHERS THEN
    Log_Set.Write_Other_Error;

END Get_Dept_Emps;

END Emp_WS;
/
SHO ERR
