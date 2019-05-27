CREATE OR REPLACE PACKAGE BODY Emp_WS AS
/***************************************************************************************************
Description: HR demo web service code. Procedure saves new employees list and returns primary key
             plus same in words, or zero plus error message in output list

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        04-May-2016 1.0   Created
Brendan Furey        11-Sep-2016 1.1   AIP_Get_Dept_Emps added
Brendan Furey        21-Jan-2018 1.2   AIP_Get_Dept_Emps: Make SQL static; remove PARTITION BY

***************************************************************************************************/

/***************************************************************************************************

AIP_Save_Emps: HR demo web service setter entry point procedure

***************************************************************************************************/
PROCEDURE AIP_Save_Emps (p_emp_in_lis           emp_in_arr,     -- list of employees to insert
                         x_emp_out_lis      OUT emp_out_arr) IS -- list of employee results

  l_emp_out_lis        emp_out_arr;
  bulk_errors          EXCEPTION;
  PRAGMA               EXCEPTION_INIT (bulk_errors, -24381);
  n_err PLS_INTEGER := 0;

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
        Utils.c_session_id_if_TT
    )
    RETURNING emp_out_rec (employee_id, To_Char(To_Date(employee_id,'J'),'JSP')) BULK COLLECT INTO x_emp_out_lis;

EXCEPTION
  WHEN bulk_errors THEN

    l_emp_out_lis := x_emp_out_lis;

    FOR i IN 1 .. sql%BULK_EXCEPTIONS.COUNT LOOP
      IF i > x_emp_out_lis.COUNT THEN
        x_emp_out_lis.Extend;
      END IF;
      x_emp_out_lis (SQL%Bulk_Exceptions (i).Error_Index) := emp_out_rec (0, SQLERRM (- (SQL%Bulk_Exceptions (i).Error_Code)));
    END LOOP;

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

END AIP_Save_Emps;

/***************************************************************************************************

AIP_Get_Dept_Emps: HR demo web service getter entry point procedure

***************************************************************************************************/
PROCEDURE AIP_Get_Dept_Emps (p_dep_id           PLS_INTEGER,      -- department id
                             x_emp_csr      OUT SYS_REFCURSOR) IS -- reference cursor

BEGIN

  OPEN x_emp_csr FOR
  WITH all_emps AS (
        SELECT Avg (salary) avg_sal, SUM (salary) sal_tot_g
          FROM employees e
  )
  SELECT e.last_name, d.department_name, m.last_name manager, e.salary,
         Round (e.salary / Avg (e.salary) OVER (), 2) sal_rat,
         Round (e.salary / a.avg_sal, 2) sal_rat_g
    FROM all_emps a
   CROSS JOIN employees e
    JOIN departments d
      ON d.department_id = e.department_id
    LEFT JOIN employees m
      ON m.employee_id = e.manager_id
   WHERE e.job_id != 'AD_ASST'
     AND a.sal_tot_g >= 1600
     AND d.department_id = p_dep_id;

END AIP_Get_Dept_Emps;

END Emp_WS;
/
SHO ERR
