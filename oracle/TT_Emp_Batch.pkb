CREATE OR REPLACE PACKAGE BODY TT_Emp_Batch AS
/***************************************************************************************************
Description: Transactional API testing for HR demo batch code

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        11-Sep-2016 1.0   Created
Brendan Furey        22-Oct-2016 1.1   TRAPIT name changes, UT->TT etc.
Brendan Furey        27-Jan-2018 1.2   Re-factor to emphasise single underlying design pattern
Brendan Furey        06-Jul-2018 1.3   Initial JSON version

***************************************************************************************************/
c_date_fmt              CONSTANT VARCHAR2(30) := Utils_TT.c_date_fmt;
c_dat_name              CONSTANT VARCHAR2(20) := 'employees.dat';
c_seconds_in_day        CONSTANT PLS_INTEGER := 86400;

/***************************************************************************************************

tt_AIP_Load_Emps: Main procedure for testing Emp_Batch.AIP_Load_Emps procedure

***************************************************************************************************/
PROCEDURE tt_AIP_Load_Emps IS

  c_proc_nm               CONSTANT VARCHAR2(30) := 'tt_AIP_Load_Emps';
  c_timer_set_nm          CONSTANT VARCHAR2(61) := $$PLSQL_UNIT || '.' ||c_proc_nm;
  c_fmt_datetime          CONSTANT VARCHAR2(61) := 'DD-MON-YYYY hh24:mi:ss';
  c_ms_limit              CONSTANT PLS_INTEGER := 2;

  l_timer_set                      PLS_INTEGER;
  l_act_3lis                       L3_chr_arr := L3_chr_arr();
  l_sces_4lis                      L4_chr_arr;

  /***************************************************************************************************

  Setup_DB: Database setup procedure for testing AIP_Load_Emps

  ***************************************************************************************************/
  PROCEDURE Setup_DB (p_file_name            VARCHAR2,    -- data file inputs
                      p_fil_2lis             L2_chr_arr,    -- data file inputs
                      p_emp_2lis             L2_chr_arr,    -- employees inputs
                      p_jbs_2lis             L2_chr_arr,  -- job statistics inputs
                      x_last_seq_emp  OUT    PLS_INTEGER,
                      x_last_seq_jbs  OUT    PLS_INTEGER) IS
    l_emp_id        PLS_INTEGER;
    l_last_seq_emp  PLS_INTEGER;
    l_fil_lis       L1_chr_arr := L1_chr_arr();
    l_line          VARCHAR2(32767);
  BEGIN

    SELECT job_statistics_seq.NEXTVAL
      INTO x_last_seq_jbs
      FROM DUAL;

    IF p_jbs_2lis IS NOT NULL THEN

      FOR i IN 1..p_jbs_2lis.COUNT LOOP

        DML_API_TT_Bren.Ins_jbs (
                            p_batch_job_id      => p_jbs_2lis(i)(2),
                            p_file_name         => p_jbs_2lis(i)(3),
                            p_records_loaded    => p_jbs_2lis(i)(4),
                            p_records_failed_et => p_jbs_2lis(i)(5),
                            p_records_failed_db => p_jbs_2lis(i)(6),
                            p_start_time        => To_Date(p_jbs_2lis(i)(7), c_fmt_datetime),
                            p_end_time          => To_Date(p_jbs_2lis(i)(8), c_fmt_datetime),
                            p_job_status        => p_jbs_2lis(i)(9));
      END LOOP;

    END IF;

    SELECT employees_seq.NEXTVAL
      INTO x_last_seq_emp
      FROM DUAL;

    IF p_emp_2lis IS NOT NULL THEN

      FOR i IN 1..p_emp_2lis.COUNT LOOP

        l_last_seq_emp := DML_API_TT_HR.Ins_Emp (
                            p_emp_ind     => i,
                            p_dep_id      => p_emp_2lis(i)(8),
                            p_mgr_id      => p_emp_2lis(i)(7),
                            p_job_id      => p_emp_2lis(i)(5),
                            p_salary      => p_emp_2lis(i)(6),
                            p_last_name   => p_emp_2lis(i)(2),
                            p_email       => p_emp_2lis(i)(3),
                            p_hire_date   => p_emp_2lis(i)(4),
                            p_update_date => To_Date(p_emp_2lis(i)(9), c_fmt_datetime));
      END LOOP;

    END IF;

    l_fil_lis.EXTEND(p_fil_2lis.COUNT);
    FOR i IN 1..p_fil_2lis.COUNT LOOP
      l_line := p_fil_2lis(i)(1);
      l_emp_id := Substr(l_line, 1, Instr(l_line, ',', 1) - 1);
      IF l_emp_id IS NOT NULL THEN
        l_line := (l_emp_id + x_last_seq_emp) || Substr(l_line, Instr(l_line, ',', 1));
      END IF;
      l_fil_lis(i) := l_line;
    END LOOP;
    Utils.Delete_File (c_dat_name);
    Utils.Write_File (c_dat_name, l_fil_lis);
  END Setup_DB;

  /***************************************************************************************************

  Purely_Wrap_API: Design pattern has the API call wrapped in a 'pure' procedure, called once per 
                   scenario, with the output 'actuals' array including everything affected by the API,
                   whether as output parameters, or on database tables, etc. The inputs are also
                   extended from the API parameters to include any other effective inputs. Assertion 
                   takes place after all scenarios and is against the extended outputs, with extended
                   inputs also listed. The API call is timed

  ***************************************************************************************************/
  PROCEDURE Purely_Wrap_API (p_inp_3lis        L3_chr_arr,       -- input list of lists (record, field)
                             x_act_2lis    OUT L2_chr_arr) IS    -- output list of lists (group, record)

    l_tab_lis           L1_chr_arr;
    l_err_lis           L1_chr_arr;
    l_jbs_lis           L1_chr_arr;
    l_exc_lis           L1_chr_arr;
    l_last_seq_emp      PLS_INTEGER;
    l_last_seq_jbs      PLS_INTEGER;


    -- Get_Tab_Lis: gets the database records inserted into a generic list of strings
    PROCEDURE Get_Tab_Lis (p_last_seq_emp PLS_INTEGER, x_tab_lis OUT L1_chr_arr) IS
    BEGIN

      SELECT Utils.List_Delim (
                 employee_id - p_last_seq_emp,
                 last_name,
                 email,
                 To_Char (hire_date, c_date_fmt),
                 job_id,
                 salary,
                 To_Char(update_date, c_fmt_datetime),
                 c_seconds_in_day*(SYSDATE - update_date))
        BULK COLLECT INTO x_tab_lis
        FROM employees
       ORDER BY employee_id;

    END Get_Tab_Lis;

    -- Get_Err_Lis: gets the database error records inserted into a generic list of strings
    PROCEDURE Get_Err_Lis (p_last_seq_emp PLS_INTEGER, p_last_seq_jbs PLS_INTEGER, x_err_lis OUT L1_chr_arr) IS
    BEGIN

      SELECT Utils.List_Delim (
                job_statistic_id - p_last_seq_jbs,
                ORA_ERR_TAG$,
                Replace (ORA_ERR_MESG$, Chr(10)),
                ORA_ERR_OPTYP$,
                employee_id - p_last_seq_emp,
                last_name,
                email,
                hire_date,
                job_id,
                salary)
      BULK COLLECT INTO x_err_lis
      FROM err$_employees;

    END Get_Err_Lis;

    -- Get_Jbs_Lis: gets the job_statistics_v records inserted into a generic list of strings
    PROCEDURE Get_Jbs_Lis (p_last_seq_jbs PLS_INTEGER, x_jbs_lis OUT L1_chr_arr) IS
    BEGIN

      SELECT Utils.List_Delim (
                 job_statistic_id - p_last_seq_jbs,
                 batch_job_id,
                 file_name,
                 records_loaded,
                 records_failed_et,
                 records_failed_db,
                 To_Char(start_time, c_fmt_datetime),
                 To_Char(end_time, c_fmt_datetime),
                 c_seconds_in_day*(SYSDATE - start_time),
                 c_seconds_in_day*(SYSDATE - end_time),
                 job_status)
        BULK COLLECT INTO x_jbs_lis
        FROM job_statistics_v
       ORDER BY job_statistic_id;

    END Get_Jbs_Lis;

  BEGIN

    Setup_DB (p_file_name          => p_inp_3lis(1)(1)(1), -- data file
              p_fil_2lis           => p_inp_3lis(2),    -- data file inputs
              p_emp_2lis           => p_inp_3lis(5),
              p_jbs_2lis           => p_inp_3lis(4),
              x_last_seq_emp       => l_last_seq_emp,
              x_last_seq_jbs       => l_last_seq_jbs);
    Timer_Set.Increment_Time (l_timer_set, 'Setup_DB');

   BEGIN

      Emp_Batch.AIP_Load_Emps (p_file_name => p_inp_3lis(1)(1)(1), p_file_count => p_inp_3lis(1)(1)(2));
      Timer_Set.Increment_Time (l_timer_set, Utils_TT.c_call_timer);

    EXCEPTION
      WHEN OTHERS THEN
        l_exc_lis := L1_chr_arr (SQLERRM);
    END;

    Get_Tab_Lis (p_last_seq_emp => l_last_seq_emp, x_tab_lis => l_tab_lis); Timer_Set.Increment_Time (l_timer_set, 'Get_Tab_Lis');
    Get_Err_Lis (p_last_seq_emp => l_last_seq_emp, p_last_seq_jbs => l_last_seq_jbs, x_err_lis => l_err_lis); Timer_Set.Increment_Time (l_timer_set, 'Get_Err_Lis');
    Get_Jbs_Lis (p_last_seq_jbs => l_last_seq_jbs, x_jbs_lis => l_jbs_lis); Timer_Set.Increment_Time (l_timer_set, 'Get_Jbs_Lis');

    x_act_2lis := L2_chr_arr (l_tab_lis,
                              l_err_lis,
                              l_jbs_lis,
                              l_exc_lis);
    ROLLBACK;

    DELETE err$_employees; -- DML logging does auto transaction
    DELETE job_statistics_v; -- job statistics done via auto transaction
    COMMIT;

  END Purely_Wrap_API;

BEGIN
--
-- Every testing main section should be similar to this, with array setup, then loop over scenarios
-- making a 'pure'(-ish) call to specific, local Purely_Wrap_API, with single assertion call outside
-- the loop
--
  l_timer_set := Utils_TT.Init(c_timer_set_nm);
  l_sces_4lis := Utils_TT.Get_Inputs (p_package_nm    => $$PLSQL_UNIT,
                                      p_procedure_nm  => c_proc_nm,
                                      p_timer_set     => l_timer_set);
  l_act_3lis.EXTEND (l_sces_4lis.COUNT);

  FOR i IN 1..l_sces_4lis.COUNT LOOP

    Purely_Wrap_API (l_sces_4lis(i), l_act_3lis(i));

  END LOOP;

  Utils_TT.Set_Outputs(p_package_nm    => $$PLSQL_UNIT,
                       p_procedure_nm  => c_proc_nm,
                       p_act_3lis      => l_act_3lis,
                       p_timer_set     => l_timer_set);

EXCEPTION
  WHEN OTHERS THEN
    Utils.Write_Other_Error;
    RAISE;
END tt_AIP_Load_Emps;

END TT_Emp_Batch;
/
SHO ERR
