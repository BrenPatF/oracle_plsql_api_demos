SET SERVEROUTPUT ON
SET TRIMSPOOL ON
SET PAGES 1000
SET LINES 500
WHENEVER SQLERROR CONTINUE 
SPOOL Install_Bren.log
/***************************************************************************************************

Author:      Brendan Furey
Description: Script for new schema to create the common objects for Brendan's TRAPIT API testing
             framework design patterns demo

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        04-May-2016 1.0   Created
Brendan Furey        11-Sep-2016 1.1   Generic array field size increased from 4000 to 32767; also
                                       various additions for new TRAPIT examples
Brendan Furey        06-Jul-2018 1.2   Initial JSON version

***************************************************************************************************/

REM Run this script from schema for Brendan's TRAPIT API testing framework design patterns demo to create the common objects

PROMPT Common types creation
PROMPT =====================

PROMPT Drop type L4_chr_arr
DROP TYPE L4_chr_arr
/
PROMPT Drop type L3_chr_arr
DROP TYPE L3_chr_arr
/
PROMPT Drop type L2_chr_arr
DROP TYPE L2_chr_arr
/
PROMPT Create type L1_chr_arr
CREATE OR REPLACE TYPE L1_chr_arr IS VARRAY(32767) OF VARCHAR2(32767)
/
PROMPT Create type L2_chr_arr
CREATE OR REPLACE TYPE L2_chr_arr IS VARRAY(32767) OF L1_chr_arr
/
PROMPT Create type L3_chr_arr
CREATE OR REPLACE TYPE L3_chr_arr IS VARRAY(32767) OF L2_chr_arr
/
PROMPT Create type L4_chr_arr
CREATE OR REPLACE TYPE L4_chr_arr IS VARRAY(32767) OF L3_chr_arr
/
CREATE OR REPLACE PUBLIC SYNONYM L1_chr_arr FOR L1_chr_arr
/
GRANT EXECUTE ON L1_chr_arr TO PUBLIC
/
CREATE OR REPLACE PUBLIC SYNONYM L2_chr_arr FOR L2_chr_arr
/
GRANT EXECUTE ON L2_chr_arr TO PUBLIC
/
CREATE OR REPLACE PUBLIC SYNONYM L3_chr_arr FOR L3_chr_arr
/
GRANT EXECUTE ON L3_chr_arr TO PUBLIC
/
CREATE OR REPLACE PUBLIC SYNONYM L4_chr_arr FOR L4_chr_arr
/
GRANT EXECUTE ON L4_chr_arr TO PUBLIC
/
PROMPT Create type L1_num_arr
CREATE OR REPLACE TYPE L1_num_arr IS VARRAY(32767) OF NUMBER
/
CREATE OR REPLACE PUBLIC SYNONYM L1_num_arr FOR L1_num_arr
/
GRANT EXECUTE ON L1_num_arr TO PUBLIC
/

PROMPT Common tables creation
PROMPT ======================

PROMPT Create table log_headers
DROP TABLE log_lines
/
DROP TABLE log_headers
/
CREATE TABLE log_headers (
        id                      INTEGER NOT NULL,
        description             VARCHAR2(500),
        creation_date           TIMESTAMP,
        CONSTRAINT hdr_pk       PRIMARY KEY (id)
)
/
PROMPT Insert the default log header
INSERT INTO log_headers VALUES (0, 'Miscellaneous output', SYSTIMESTAMP)
/
CREATE OR REPLACE PUBLIC SYNONYM log_headers FOR log_headers
/
GRANT ALL ON log_headers TO PUBLIC
/
DROP SEQUENCE log_headers_s
/
CREATE SEQUENCE log_headers_s START WITH 1
/
CREATE OR REPLACE PUBLIC SYNONYM log_headers_s FOR log_headers_s
/
GRANT SELECT ON log_headers_s TO PUBLIC
/
PROMPT Create table log_lines
CREATE TABLE log_lines (
        id                      INTEGER NOT NULL,
        log_header_id           INTEGER NOT NULL,
        group_text              VARCHAR2(100),
        line_text               VARCHAR2(4000),
        creation_date           TIMESTAMP,
        CONSTRAINT lin_pk       PRIMARY KEY (id, log_header_id),
        CONSTRAINT lin_hdr_fk   FOREIGN KEY (log_header_id) REFERENCES log_headers (id)
)
/
CREATE OR REPLACE PUBLIC SYNONYM log_lines FOR log_lines
/
GRANT ALL ON log_lines TO PUBLIC
/
DROP SEQUENCE log_lines_s
/
CREATE SEQUENCE log_lines_s START WITH 1
/
CREATE OR REPLACE PUBLIC SYNONYM log_lines_s FOR log_lines_s
/
GRANT SELECT ON log_lines_s TO PUBLIC
/

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
 WHERE (ttid = SYS_Context ('userenv', 'sessionid') OR
        Substr (Nvl (SYS_Context ('userenv', 'client_info'), 'XX'), 1, 2) != 'TT')
/
PROMPT err$_employees view
CREATE OR REPLACE VIEW err$_employees AS
SELECT *
  FROM  hr.err$_employees
 WHERE (ttid = SYS_Context ('userenv', 'sessionid') OR
        Substr (Nvl (SYS_Context ('userenv', 'client_info'), 'XX'), 1, 2) != 'TT')
/
PROMPT hr_test_view_v view
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
PROMPT Create batch_jobs
DROP TABLE job_statistics
/
DROP TABLE batch_jobs
/
CREATE TABLE batch_jobs (
        batch_job_id        VARCHAR2(30) NOT NULL,
        fail_threshold_perc NUMBER,
        CONSTRAINT bjb_pk PRIMARY KEY (batch_job_id)
)
/
PROMPT Seed batch_jobs record for load_employees
INSERT INTO batch_jobs
VALUES ('LOAD_EMPS', 70)
/
PROMPT Create job_statistics
CREATE TABLE job_statistics (
        job_statistic_id        NUMBER NOT NULL,
        batch_job_id            VARCHAR2(30) NOT NULL,
        file_name               VARCHAR2(60) NOT NULL,
        records_loaded          NUMBER,
        records_failed_et       NUMBER,
        records_failed_db       NUMBER,
        start_time              DATE,
        end_time                DATE,
        job_status              VARCHAR2(1),
        ttid                    VARCHAR2(30),
        CONSTRAINT jbs_pk PRIMARY KEY (job_statistic_id),
        CONSTRAINT jbs_bjb_fk FOREIGN KEY (batch_job_id) REFERENCES batch_jobs (batch_job_id),
        CONSTRAINT jbs_job_status_chk CHECK (job_status IN ('S', 'F'))
)
/
DROP SEQUENCE job_statistics_seq
/
CREATE SEQUENCE job_statistics_seq START WITH 1
/
PROMPT job_statistics_v view
CREATE OR REPLACE VIEW job_statistics_v AS
SELECT job_statistic_id,
       batch_job_id,
       file_name,
       records_loaded,
       records_failed_et,
       records_failed_db,
       start_time,
       end_time,
       job_status,
       ttid
  FROM job_statistics
 WHERE (ttid = SYS_Context ('userenv', 'sessionid') OR
        Substr (Nvl (SYS_Context ('userenv', 'client_info'), 'XX'), 1, 2) != 'TT')
/

PROMPT Dropping tables
DROP TABLE tt_units
/
PROMPT tt_units
CREATE TABLE tt_units (
    package_nm                   VARCHAR2(30) NOT NULL,
    procedure_nm                 VARCHAR2(30) NOT NULL,
    description                  VARCHAR2(500),
    active_yn                    VARCHAR2(1),
    input_data                   CLOB,
    output_data                  CLOB,
    CONSTRAINT uni_pk            PRIMARY KEY (package_nm, procedure_nm),
    CONSTRAINT uni_js1           CHECK (input_data IS JSON),
    CONSTRAINT uni_js2           CHECK (output_data IS JSON))
/
COMMENT ON TABLE tt_units IS 'Unit test metadata'
/

PROMPT Read in json files
DECLARE
  PROCEDURE Add_Ttu (p_package_nm VARCHAR2, p_procedure_nm VARCHAR2, p_active_yn VARCHAR2, p_input_file VARCHAR2) IS

    l_src_file      BFILE := BFileName( 'INPUT_DIR', p_input_file);
    l_dest_lob      CLOB;
    l_dest_offset   INTEGER := 1;
    l_src_offset    INTEGER := 1;
    l_lang_context  NUMBER := DBMS_LOB.Default_Lang_Ctx;
    l_warning       NUMBER;

  BEGIN

    DBMS_LOB.CreateTemporary(l_dest_lob,true);

    DBMS_LOB.Open(l_src_file, DBMS_LOB.Lob_readonly);
    DBMS_LOB.LoadCLOBFromFile( 
                dest_lob     => l_dest_lob,
                src_bfile    => l_src_file,
                amount       => DBMS_LOB.LOBMAXSIZE,
                dest_offset  => l_dest_offset,
                src_offset   => l_src_offset,
                bfile_csid   => DBMS_LOB.Default_Csid,
                lang_context => l_lang_context,
                warning      => l_warning );

    INSERT INTO tt_units (package_nm, procedure_nm, active_yn, input_data)
    VALUES (p_package_nm, p_procedure_nm, p_active_yn, l_dest_lob);
    COMMIT;
    DBMS_LOB.FreeTemporary(l_dest_lob);
    DBMS_LOB.Close(l_src_file);

  END Add_Ttu;

BEGIN

  Add_Ttu ('TT_EMP_BATCH', 'tt_AIP_Load_Emps', 'Y', 'tt_AIP_Load_Emps.json');
  Add_Ttu ('TT_EMP_WS', 'tt_AIP_Get_Dept_Emps', 'Y', 'tt_AIP_Get_Dept_Emps.json');
  Add_Ttu ('TT_EMP_WS', 'tt_AIP_Save_Emps', 'Y', 'tt_AIP_Save_Emps.json');
  Add_Ttu ('TT_VIEW_DRIVERS', 'tt_HR_Test_View_V', 'Y', 'tt_HR_Test_View_V.json');

END;
/

PROMPT Packages creation
PROMPT =================

PROMPT Create package Utils
@Utils.pks
@Utils.pkb

PROMPT Create package Timer_Set
@Timer_Set.pks
@Timer_Set.pkb

PROMPT Create package Utils_TT
@Utils_TT.pks
@Utils_TT.pkb

PROMPT HR Packages creation
PROMPT ====================

PROMPT Create package DML_API_TT_HR
@DML_API_TT_HR.pks
@DML_API_TT_HR.pkb

PROMPT Create package Emp_WS
@Emp_WS.pks
@Emp_WS.pkb

PROMPT Create package TT_Emp_WS
@TT_Emp_WS.pks
@TT_Emp_WS.pkb

PROMPT Create package TT_View_Drivers
@TT_View_Drivers.pks
@TT_View_Drivers.pkb

PROMPT Create DML_API_Bren package
@DML_API_Bren.pks
@DML_API_Bren.pkb

PROMPT Create DML_API_TT_Bren package
@DML_API_TT_Bren.pks
@DML_API_TT_Bren.pkb

PROMPT Create Emp_Batch package
@Emp_Batch.pks
@Emp_Batch.pkb

PROMPT Create Emp_Batch package
@TT_Emp_Batch.pks
@TT_Emp_Batch.pkb

SPOOL OFF