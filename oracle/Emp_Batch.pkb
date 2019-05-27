CREATE OR REPLACE PACKAGE BODY Emp_Batch AS
/***************************************************************************************************
Description: HR demo batch code. Procedure saves new employees from file via external table

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        11-Sep-2016 1.0   Created

***************************************************************************************************/

/***************************************************************************************************

AIP_Load_Emps: HR demo batch entry point procedure

***************************************************************************************************/
PROCEDURE AIP_Load_Emps (p_file_name    VARCHAR2,       -- original file name
                         p_file_count   PLS_INTEGER) IS -- number of lines in file

  c_batch_job_id CONSTANT VARCHAR2(30) := 'LOAD_EMPS';
  l_n_updated             PLS_INTEGER;
  l_n_inserted            PLS_INTEGER;
  l_status                VARCHAR2(1) := 'S';
  l_start_time            DATE := SYSDATE;
  l_uid                   PLS_INTEGER;
  l_n_errors_et           PLS_INTEGER;
  l_n_errors_db           PLS_INTEGER;
  l_dummy                 PLS_INTEGER;
  l_fail_threshold_perc   PLS_INTEGER;
  Already_Processed       EXCEPTION;

  FUNCTION Ins_Jbs (p_records_loaded    PLS_INTEGER,
                    p_records_failed_et PLS_INTEGER,
                    p_records_failed_db PLS_INTEGER,
                    p_start_time        DATE,
                    p_job_status        VARCHAR2)
                    RETURN              PLS_INTEGER IS

    PRAGMA AUTONOMOUS_TRANSACTION;
    l_uid                   PLS_INTEGER;

  BEGIN

    l_uid := DML_API_Bren.Ins_Jbs (
                          p_batch_job_id      => c_batch_job_id,
                          p_file_name         => p_file_name,
                          p_records_loaded    => p_records_loaded,
                          p_records_failed_et => p_records_failed_et,
                          p_records_failed_db => p_records_failed_db,
                          p_start_time        => p_start_time,
                          p_end_time          => SYSDATE,
                          p_job_status        => p_job_status);

    COMMIT;
    RETURN l_uid;

  END Ins_Jbs;

BEGIN

  BEGIN

    SELECT 1 INTO l_dummy
      FROM job_statistics
     WHERE batch_job_id = c_batch_job_id
       AND file_name    = p_file_name
       AND job_status   = 'S';
     RAISE Already_Processed;

   EXCEPTION
     WHEN NO_DATA_FOUND THEN NULL;
   END;

   MERGE INTO hr.employees tgt
   USING (SELECT employee_id,
                 last_name,
                 email,
                 hire_date,
                 job_id,
                 To_Number(salary) salary
            FROM employees_et
           MINUS
          SELECT To_Char (employee_id),
                 last_name,
                 email,
                 To_Char (hire_date, 'DD-MON-YYYY'),
                 job_id,
                 salary
            FROM hr.employees) src
      ON (tgt.employee_id = src.employee_id)
    WHEN MATCHED THEN
  UPDATE SET     tgt.last_name          = src.last_name,
                 tgt.email              = src.email,
                 tgt.hire_date          = To_Date (src.hire_date, 'DD-MON-YYYY'),
                 tgt.job_id             = src.job_id,
                 tgt.salary             = src.salary,
                 tgt.update_date        = SYSDATE,
                 tgt.ttid               = Utils.c_session_id_if_TT
  LOG ERRORS INTO hr.err$_employees REJECT LIMIT UNLIMITED;
  l_n_updated := SQL%ROWCOUNT;

  INSERT INTO hr.employees (
                 employee_id,
                 last_name,
                 email,
                 hire_date,
                 job_id,
                 salary,
                 update_date,
                 ttid
  )
  SELECT         employees_seq.NEXTVAL,
                 src.last_name,
                 src.email,
                 To_Date (src.hire_date, 'DD-MON-YYYY'),
                 src.job_id,
                 src.salary,
                 SYSDATE,
                 Utils.c_session_id_if_TT
    FROM employees_et src
   WHERE src.employee_id IS NULL
  LOG ERRORS INTO hr.err$_employees REJECT LIMIT UNLIMITED;
  l_n_inserted := SQL%ROWCOUNT;

  SELECT fail_threshold_perc
    INTO l_fail_threshold_perc
    FROM batch_jobs
   WHERE batch_job_id = c_batch_job_id;

  INSERT INTO hr.err$_employees (
         ORA_ERR_MESG$,
         ORA_ERR_OPTYP$,
         employee_id,
         last_name,
         email,
         hire_date,
         job_id,
         salary,
         ttid
  )
  SELECT 'Employee not found',
         'PK',
         src.employee_id,
         src.last_name,
         src.email,
         src.hire_date,
         src.job_id,
         src.salary,
         Utils.c_session_id_if_TT
    FROM employees_et src
    LEFT JOIN hr.employees tgt
        ON tgt.employee_id = src.employee_id
   WHERE src.employee_id IS NOT NULL
     AND tgt.employee_id IS NULL;

  SELECT COUNT(*) INTO l_n_errors_db
    FROM hr.err$_employees
   WHERE job_statistic_id IS NULL;

  SELECT p_file_count - COUNT(*) INTO l_n_errors_et
    FROM employees_et;

  IF 100 * (l_n_errors_et + l_n_errors_db) / (l_n_errors_et + l_n_errors_db + l_n_inserted + l_n_updated) >= l_fail_threshold_perc THEN

    l_status := 'F';

  END IF;

  l_uid := Ins_Jbs (p_records_loaded    => l_n_inserted + l_n_updated,
                    p_records_failed_et => l_n_errors_et,
                    p_records_failed_db => l_n_errors_db,
                    p_start_time        => l_start_time,
                    p_job_status        => l_status);

  UPDATE hr.err$_employees
     SET job_statistic_id = l_uid
   WHERE job_statistic_id IS NULL;

  IF l_status = 'F'  THEN
    RAISE_APPLICATION_ERROR (-20001, 'Batch failed with too many invalid records!');
  END IF;

EXCEPTION
  WHEN Already_Processed THEN
    RAISE_APPLICATION_ERROR (-20002, 'File has already been processed successfully!');

END AIP_Load_Emps;

END Emp_Batch;
/
SHO ERR
