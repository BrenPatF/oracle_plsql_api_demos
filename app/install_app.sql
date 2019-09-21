@..\initspool install_app

@c_jobs_syns lib

PROMPT HR Types creation
PROMPT =================

PROMPT Input types creation
DROP TYPE emp_in_arr
/
CREATE OR REPLACE TYPE emp_in_rec AS OBJECT (
        last_name       VARCHAR2(25),
        email           VARCHAR2(25),
        job_id          VARCHAR2(10),
        salary          NUMBER
)
/
CREATE TYPE emp_in_arr AS TABLE OF emp_in_rec
/
PROMPT Output types creation
DROP TYPE emp_out_arr
/
CREATE OR REPLACE TYPE emp_out_rec AS OBJECT (
        employee_id     NUMBER,
        description     VARCHAR2(500)
)
/
CREATE TYPE emp_out_arr AS TABLE OF emp_out_rec
/
PROMPT HR synonyms AND views creation
PROMPT ==============================
CREATE OR REPLACE SYNONYM departments FOR hr.departments
/
CREATE OR REPLACE SYNONYM employees_seq FOR hr.employees_seq
/
PROMPT employees view
CREATE OR REPLACE VIEW employees AS
SELECT
        employee_id,
        first_name,
        last_name,
        email,
        phone_number,
        hire_date,
        job_id,
        salary,
        commission_pct,
        manager_id,
        department_id,
        update_date,
        ttid
  FROM  hr.employees
 WHERE (ttid = SYS_Context('userenv', 'sessionid') OR
        Substr(Nvl(SYS_Context('TRAPIT_CTX', 'MODE'), 'XX'), 1, 2) != 'UT')
/
PROMPT err$_employees view
CREATE OR REPLACE VIEW err$_employees AS
SELECT *
  FROM  hr.err$_employees
 WHERE (ttid = SYS_Context('userenv', 'sessionid') OR
        SYS_Context('TRAPIT_CTX', 'MODE') IS NULL)
/
PROMPT hr_test_view_v view
/***************************************************************************************************

hr_test_view_v: View returning department and employee details including salary ratios, excluding
                employees with job 'AD_ASST', and returning none if global salary total < 1600

***************************************************************************************************/
CREATE OR REPLACE VIEW hr_test_view_v AS
WITH all_emps AS (
        SELECT Avg (salary) avg_sal, SUM (salary) sal_tot_g
          FROM employees e
)
SELECT e.last_name, d.department_name, m.last_name manager, e.salary,
       Round (e.salary / Avg (e.salary) OVER (PARTITION BY e.department_id), 2) sal_rat,
       Round (e.salary / a.avg_sal, 2) sal_rat_g
  FROM all_emps a
 CROSS JOIN employees e
  JOIN departments d
    ON d.department_id = e.department_id
  LEFT JOIN employees m
    ON m.employee_id = e.manager_id
 WHERE e.job_id != 'AD_ASST'
   AND a.sal_tot_g >= 1600
/

PROMPT Create employees_et
DROP TABLE employees_et
/
CREATE TABLE employees_et (
                    employee_id         VARCHAR2(4000),
                    last_name           VARCHAR2(4000),
                    email               VARCHAR2(4000),
                    hire_date           VARCHAR2(4000),
                    job_id              VARCHAR2(4000),
                    salary              VARCHAR2(4000)
)
ORGANIZATION EXTERNAL (
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY input_dir
    ACCESS PARAMETERS (
            RECORDS DELIMITED BY NEWLINE
            FIELDS TERMINATED BY  ','
            MISSING FIELD VALUES ARE NULL (
                    employee_id,
                    last_name,
                    email,
                    hire_date,
                    job_id,
                    salary
            )
    )
    LOCATION ('employees.dat')
)
    REJECT LIMIT UNLIMITED
/
PROMPT Seed batch_jobs record for load_employees
BEGIN

  DML_API_Jobs.Ins_Job(
            p_batch_job_id        => 'LOAD_EMPS',
            p_fail_threshold_perc => 70);
END;
/
PROMPT Add the ut records
DEFINE APP=app
BEGIN
  Trapit.Add_Ttu('TT_EMP_BATCH',    'Load_Emps',      '&APP', 'Y', 'tt_emp_batch.load_emps_inp.json');
  Trapit.Add_Ttu('TT_EMP_WS',       'Get_Dept_Emps',  '&APP', 'Y', 'tt_emp_ws.get_dept_emps_inp.json');
  Trapit.Add_Ttu('TT_EMP_WS',       'Save_Emps',      '&APP', 'Y', 'tt_emp_ws.save_emps_inp.json');
  Trapit.Add_Ttu('TT_VIEW_DRIVERS', 'HR_Test_View_V', '&APP', 'Y', 'tt_view_drivers.hr_test_view_v_inp.json');
END;
/
PROMPT Add the log config records
BEGIN
  Log_Config.Ins_Config(
      p_config_key              => 'WS',
      p_description             => 'Web service/real time apps',
      p_put_lev_module          => 1,
      p_put_lev_client_info     => 1);
  Log_Config.Ins_Config(
      p_config_key              => 'BATCH',
      p_description             => 'Batch jobs',
      p_put_lev_module          => 1,
      p_put_lev_client_info     => 1);
END;
/

PROMPT Packages creation
PROMPT =================

PROMPT HR Packages creation
PROMPT ====================

PROMPT Create package DML_API_TT_HR
@dml_api_tt_hr.pks
@dml_api_tt_hr.pkb

PROMPT Create package Emp_WS
@emp_ws.pks
@emp_ws.pkb

PROMPT Create package TT_Emp_WS
@tt_emp_ws.pks
@tt_emp_ws.pkb

PROMPT Create package TT_View_Drivers
@tt_view_drivers.pks
@tt_view_drivers.pkb

PROMPT Create Emp_Batch package
@emp_batch.pks
@emp_batch.pkb

PROMPT Create TT_Emp_Batch package
@tt_emp_batch.pks
@tt_emp_batch.pkb


@..\endspool