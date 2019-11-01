@..\initspool install_api_demos
/***************************************************************************************************
Name: install_api_demos.sql             Author: Brendan Furey                      Date: 21-Sep-2019

Installation script for API Demo components in the Oracle PL/SQL API Demos module. 

The module demonstrates instrumentation and logging, code timing, and unit testing of PL/SQL APIs,
using example APIs writtten against Oracle's HR demo schema. 

    GitHub: https://github.com/BrenPatF/https://github.com/BrenPatF/oracle_plsql_api_demos

There are install scripts in the lib, hr and app schemas. Note that installation of this module is
dependent on pre-requisite installs of other modules as described in the README.

INSTALL SCRIPTS
====================================================================================================
|  Script                 |  Notes                                                                 |
|===================================================================================================
|  LIB SCHEMA                                                                                      |
----------------------------------------------------------------------------------------------------
|  install_jobs.sql       |  Creates batch_jobs and related components in lib schema               |
----------------------------------------------------------------------------------------------------
|  grant_jobs_to_app.sql  |  Grants privileges on batch_jobs and related components from lib to    |
|                         |  app schema                                                            |
----------------------------------------------------------------------------------------------------
|  HR SCHEMA                                                                                       |
----------------------------------------------------------------------------------------------------
|  install_hr.sql         |  Creates hr components                                                 |
|  revert_hr.sql          |  Reverts hr components (undoes install_hr.sql)                         |
----------------------------------------------------------------------------------------------------
|  APP SCHEMA                                                                                      |
----------------------------------------------------------------------------------------------------
|  c_jobs_syns.sql        |  Creates synonyms for batch_jobs and related components in app schema  |
|                         |  to lib schema                                                         |
----------------------------------------------------------------------------------------------------
| *install_api_demos.sql* |  Creates API Demo components in app schema                             |
====================================================================================================
This file has the install script for the API Demo components in app schema.

Components created in app schema:

    Types               Description
    ===========         ============================================================================
    emp_in_rec          Object type for employee input
    emp_in_arr          Array of emp_in_rec
    emp_out_rec         Object type for employee output
    emp_out_arr         Array of emp_out_rec

    External Tables     Description
    ==================  ============================================================================
    employees_et        For loading employees from file

    Sequences           Description
    ==================  ============================================================================
    job_statistics_seq  For job_statistics primary key

    Views               Description
    ==================  ============================================================================
    employees           View on hr.employees with sys_context condition for unit testing
    err$_employees      View on hr.err$_employees with sys_context condition for unit testing

    Synonym             Object Type
    ==================  ============================================================================
    (lib schema)        [@c_jobs_syns lib]
    departments         hr table
    employees_seq       hr sequence

    Packages            Description
    ==================  ============================================================================
    DML_API_TT_HR       DML for hr tables for unit testing
    Emp_WS              Employee web service procedures
    Emp_Batch           Employee batch procedures
    TT_Emp_WS           Unit testing for employee web service procedures
    TT_Emp_Batch        Unit testing for employee batch procedures
    TT_View_Drivers     Unit testing for views

    Metadata            Description
    ==================  ============================================================================
    batch_jobs          LOAD_EMPS job
    tt_units            Record for each test package, procedure. The input JSON files must first be
                        placed in the OS folder pointed to by INPUT_DIR directory

***************************************************************************************************/

@c_jobs_syns lib

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
@hr_test_view_v

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

PROMPT Packages creation
PROMPT =================

PROMPT Create package DML_API_TT_HR
@dml_api_tt_hr.pks
@dml_api_tt_hr.pkb

PROMPT Create package Emp_WS
@emp_ws.pks
@emp_ws.pkb

PROMPT Create package TT_Emp_WS
@tt_emp_ws.pks
@tt_emp_ws.pkb

PROMPT Create Emp_Batch package
@emp_batch.pks
@emp_batch.pkb

PROMPT Create TT_Emp_Batch package
@tt_emp_batch.pks
@tt_emp_batch.pkb

PROMPT Create package TT_View_Drivers
@tt_view_drivers.pks
@tt_view_drivers.pkb

@..\endspool