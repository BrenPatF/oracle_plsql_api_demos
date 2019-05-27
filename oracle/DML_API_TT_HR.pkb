CREATE OR REPLACE PACKAGE BODY DML_API_TT_HR AS
/***************************************************************************************************
Description: This package contains HR DML procedures for Brendan's TRAPIT API testing
             framework demo test data

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        10-May-2016 1.0   Initial
Brendan Furey        09-Jul-2016 1.1   Added output parameter x_rec for new printing of inputs
Brendan Furey        11-Sep-2016 1.2   Defaulted extra parameters
Brendan Furey        22-Oct-2016 1.3   TRAPIT name changes, UT->TT etc.

***************************************************************************************************/

/***************************************************************************************************

Ins_Emp: Inserts a record in employees table for testing, setting the new ttid column to
         session id

***************************************************************************************************/
FUNCTION Ins_Emp (p_emp_ind       PLS_INTEGER,           -- employee index
                  p_dep_id        PLS_INTEGER,           -- department id
                  p_mgr_id        PLS_INTEGER,           -- manager id
                  p_job_id        VARCHAR2,              -- job id
                  p_salary        PLS_INTEGER,           -- salary
                  p_last_name     VARCHAR2 DEFAULT NULL, -- last name
                  p_email         VARCHAR2 DEFAULT NULL, -- email address
                  p_hire_date     DATE DEFAULT SYSDATE,  -- hire date
                  p_update_date   DATE DEFAULT SYSDATE)              -- output record
                  RETURN PLS_INTEGER IS                  -- employee id created
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
        SYS_Context ('userenv', 'sessionid')
  ) RETURNING employee_id
         INTO l_emp_id;

  RETURN l_emp_id;

END Ins_Emp;

END DML_API_TT_HR;
/
SHO ERR
