CREATE OR REPLACE PACKAGE BODY TT_Emp_WS AS
/***************************************************************************************************
Description: Transactional API testing for HR demo web service code (Emp_WS) using Brendan's TRAPIT
             API testing framework.

             It was published initially with three utility packages and the base package for the
             articles linked in the link below:

                 Utils_TT:  Utility procedures for Brendan's TRAPIT API testing framework
                 Utils:     General utilities
                 Timer_Set: Code timing utility
                 Emp_WS:    HR demo web service base code

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        08-May-2016 1.0   Initial
Brendan Furey        21-May-2016 1.1   Re-factored: setup at procedure level; new type names;
                                       Write_Session_Results moved to Check_TT_Results; etc.
Brendan Furey        25-Jun-2016 1.2   Removed tt_Setup and ut_Teardown following removal of uPLSQL
Brendan Furey        09-Jul-2016 1.3   Passing new input arrays to Check_TT_Results for printing per
                                       scenario
Brendan Furey        11-Sep-2016 1.4   tt_AIP_Get_Dept_Emps added
Brendan Furey        01-Oct-2016 1.5   tt_AIP_Get_Dept_Emps: Call timing added; also, null dept
                                       scenario added
Brendan Furey        22-Oct-2016 1.6   TRAPIT name changes, UT->TT etc.
Brendan Furey        27-Jan-2018 1.7   Re-factor to emphasise single underlying design pattern
Brendan Furey        06-Jul-2018 1.8   Initial JSON version

***************************************************************************************************/

/***************************************************************************************************

tt_AIP_Save_Emps: Main procedure for testing Emp_WS.AIP_Save_Emps procedure

***************************************************************************************************/
PROCEDURE tt_AIP_Save_Emps IS

  c_proc_nm             CONSTANT VARCHAR2(30) := 'tt_AIP_Save_Emps';
  c_timer_set_nm        CONSTANT VARCHAR2(61) := $$PLSQL_UNIT || '.' ||c_proc_nm;

  l_timer_set           PLS_INTEGER;

  l_act_3lis            L3_chr_arr := L3_chr_arr();
  l_sces_4lis           L4_chr_arr;
  l_last_seq_val        PLS_INTEGER;

  /***************************************************************************************************

  Get_Offsets: Array setup procedure for testing AIP_Save_Emps. Sets the expected 
               output nested array after determining where the primary key generating sequence is at

  ***************************************************************************************************/
  PROCEDURE Get_Offsets (x_last_seq_val OUT PLS_INTEGER) IS
  BEGIN

    SELECT employees_seq.NEXTVAL
      INTO x_last_seq_val
      FROM DUAL;

  END Get_Offsets;

  /***************************************************************************************************

  Purely_Wrap_API: Design pattern has the API call wrapped in a 'pure' procedure, called once per 
                   scenario, with the output 'actuals' array including everything affected by the API,
                   whether as output parameters, or on database tables, etc. The inputs are also
                   extended from the API parameters to include any other effective inputs. Assertion 
                   takes place after all scenarios and is against the extended outputs, with extended
                   inputs also listed. The API call is timed

                   Here, input is list of lists for single call to web service procedure, the specific
                   array type output list is converted to our generic list of lists format allowing 
                   for error cases. 

  ***************************************************************************************************/
  PROCEDURE Purely_Wrap_API (p_last_seq_val    PLS_INTEGER,
                             p_inp_3lis        L3_chr_arr,       -- input list of lists (record, field)
                             x_act_2lis    OUT L2_chr_arr) IS    -- output list of lists (group, record)

    l_emp_out_lis       emp_out_arr;
    l_tab_lis           L1_chr_arr;
    l_arr_lis           L1_chr_arr;
    l_err_lis           L1_chr_arr;

    -- Do_Save makes the ws call and returns o/p array
    PROCEDURE Do_Save (x_emp_out_lis OUT emp_out_arr) IS
      l_emp_in_lis        emp_in_arr := emp_in_arr();
    BEGIN

      FOR i IN 1..p_inp_3lis(1).COUNT LOOP
        l_emp_in_lis.EXTEND;
        l_emp_in_lis (l_emp_in_lis.COUNT) := emp_in_rec (p_inp_3lis(1)(i)(1), 
                                                         p_inp_3lis(1)(i)(2), 
                                                         p_inp_3lis(1)(i)(3), 
                                                         p_inp_3lis(1)(i)(4));
      END LOOP;

      Timer_Set.Init_Time (p_timer_set_ind => l_timer_set);
      Emp_WS.AIP_Save_Emps (
                p_emp_in_lis        => l_emp_in_lis,
                x_emp_out_lis       => x_emp_out_lis);
      Timer_Set.Increment_Time (p_timer_set_ind => l_timer_set, p_timer_name => Utils_TT.c_call_timer);

    END Do_Save;

    -- Get_Tab_Lis: gets the database records inserted into a generic list of strings
    PROCEDURE Get_Tab_Lis (x_tab_lis OUT L1_chr_arr) IS
    BEGIN

      SELECT Utils.List_Delim (employee_id - p_last_seq_val, last_name, email, job_id, salary)
        BULK COLLECT INTO x_tab_lis
        FROM employees
       ORDER BY employee_id;
      Timer_Set.Increment_Time (p_timer_set_ind => l_timer_set, p_timer_name => 'SELECT');

    EXCEPTION
      WHEN NO_DATA_FOUND THEN NULL;
    END Get_Tab_Lis;

    -- Get_Arr_Lis converts the ws output array into a generic list of strings
    PROCEDURE Get_Arr_Lis (p_emp_out_lis emp_out_arr, x_arr_lis OUT L1_chr_arr) IS
    BEGIN

      IF p_emp_out_lis IS NOT NULL THEN

        x_arr_lis := L1_chr_arr();
        x_arr_lis.EXTEND (p_emp_out_lis.COUNT);
        FOR i IN 1..p_emp_out_lis.COUNT LOOP

          x_arr_lis (i) := Utils.List_Delim (
              p_emp_out_lis(i).employee_id - CASE WHEN p_emp_out_lis(i).employee_id > 0 THEN p_last_seq_val ELSE 0 END, 
              p_emp_out_lis(i).description);

        END LOOP;

      END IF;

    END Get_Arr_Lis;

  BEGIN

    BEGIN

      Do_Save (x_emp_out_lis => l_emp_out_lis);
      Get_Tab_Lis (x_tab_lis => l_tab_lis);
      Get_Arr_Lis (p_emp_out_lis => l_emp_out_lis, x_arr_lis => l_arr_lis);

    EXCEPTION
      WHEN OTHERS THEN
        l_err_lis := L1_chr_arr (SQLERRM);
    END;

    x_act_2lis := L2_chr_arr (l_tab_lis, l_arr_lis, l_err_lis);
    ROLLBACK;

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
  Get_Offsets(l_last_seq_val);
  Timer_Set.Increment_Time (l_timer_set, 'Get_Offsets');
  l_act_3lis.EXTEND (l_sces_4lis.COUNT);

  FOR i IN 1..l_sces_4lis.COUNT LOOP

    Purely_Wrap_API (l_last_seq_val, l_sces_4lis(i), l_act_3lis(i));

  END LOOP;

  Utils_TT.Set_Outputs(p_package_nm    => $$PLSQL_UNIT,
                       p_procedure_nm  => c_proc_nm,
                       p_act_3lis      => l_act_3lis,
                       p_timer_set     => l_timer_set);
  
EXCEPTION
  WHEN OTHERS THEN
    Utils.Write_Other_Error;
    RAISE;
END tt_AIP_Save_Emps;

/***************************************************************************************************

tt_AIP_Get_Dept_Emps: Main procedure for testing Emp_WS.AIP_Get_Dept_Emps procedure

***************************************************************************************************/
PROCEDURE tt_AIP_Get_Dept_Emps IS

  c_proc_nm             CONSTANT VARCHAR2(30) := 'tt_AIP_Get_Dept_Emps';
  c_timer_set_nm        CONSTANT VARCHAR2(61) := $$PLSQL_UNIT || '.' ||c_proc_nm;

  l_act_3lis            L3_chr_arr := L3_chr_arr();
  l_sces_4lis           L4_chr_arr;

  c_ms_limit            CONSTANT PLS_INTEGER := 1;
  l_timer_set                    PLS_INTEGER;
  l_emp_csr                      SYS_REFCURSOR;

  /***************************************************************************************************

  Setup_DB: Create test records for a given scenario for testing AIP_Get_Dept_Emps

  ***************************************************************************************************/
  PROCEDURE Setup_DB(p_inp_2lis           L2_chr_arr) IS -- input list, employees

    l_emp_id            PLS_INTEGER;
    l_mgr_id            PLS_INTEGER;

  BEGIN

    FOR i IN 1..p_inp_2lis.COUNT LOOP

      l_emp_id := DML_API_TT_HR.Ins_Emp (
                            p_emp_ind  => i,
                            p_dep_id   => p_inp_2lis(i)(8),
                            p_mgr_id   => l_mgr_id,
                            p_job_id   => p_inp_2lis(i)(5),
                            p_salary   => p_inp_2lis(i)(6));
      IF i = 1 THEN
        l_mgr_id := l_emp_id;
      END IF;

    END LOOP;

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
  BEGIN

    Setup_DB (p_inp_3lis(1));
    Timer_Set.Increment_Time (l_timer_set, Utils_TT.c_setup_timer);

    Emp_WS.AIP_Get_Dept_Emps (p_dep_id  => p_inp_3lis(2)(1)(1),
                              x_emp_csr => l_emp_csr);
    x_act_2lis := L2_chr_arr();
    x_act_2lis.EXTEND;
    x_act_2lis(1) := Utils_TT.Cursor_to_Array (x_csr => l_emp_csr);
    Timer_Set.Increment_Time (l_timer_set, Utils_TT.c_call_timer);
    ROLLBACK;

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
                       p_procedure_nm  => 'tt_AIP_Get_Dept_Emps',
                       p_act_3lis      => l_act_3lis,
                       p_timer_set     => l_timer_set);

EXCEPTION

  WHEN OTHERS THEN
    Utils.Write_Other_Error;
    RAISE;

END tt_AIP_Get_Dept_Emps;

END TT_Emp_WS;
/
SHO ERR