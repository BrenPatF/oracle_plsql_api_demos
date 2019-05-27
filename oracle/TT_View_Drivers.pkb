CREATE OR REPLACE PACKAGE BODY TT_View_Drivers AS
/***************************************************************************************************
Description: This package contains testing procedures corresponding to SQL views, which allows
             testing of SQL statements with Brendan's TRAPIT API testing framework.

             For tt_View_X, no package is required as this test package actually calls a generic
             packaged procedure in Utils_TT to execute the SQL for the job.

             It was published initially with three other utility packages for the articles linked in
             the link below:

                 Utils_TT:  Utility procedures for Brendan's TRAPIT API testing framework
                 Utils:     General utilities
                 Timer_Set: Code timing utility

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        21-May-2016 1.0   Created
Brendan Furey        25-Jun-2016 1.1   Removed tt_Setup and ut_Teardown following removal of uPLSQL
Brendan Furey        09-Jul-2016 1.2   Passing new input arrays to Is_Deeply for printing per
                                       scenario
Brendan Furey        22-Oct-2016 1.3   TRAPIT name changes, UT->TT etc.
Brendan Furey        27-Jan-2018 1.4   Re-factor to emphasise single underlying design pattern
Brendan Furey        06-Jul-2018 1.5   Initial JSON version

***************************************************************************************************/

/***************************************************************************************************

tt_HR_Test_View_V: TRAPIT procedure to test view HR_Test_View_V

***************************************************************************************************/
PROCEDURE tt_HR_Test_View_V IS

  c_view_name           CONSTANT VARCHAR2(61) := 'HR_Test_View_V';
  c_proc_nm             CONSTANT VARCHAR2(30) := 'tt_HR_Test_View_V';
  c_timer_set_nm        CONSTANT VARCHAR2(61) := $$PLSQL_UNIT || '.' ||c_proc_nm;
  c_sel_lis             CONSTANT L1_chr_arr := L1_chr_arr ('last_name', 'department_name', 'manager', 'salary', 'sal_rat', 'sal_rat_g');

  l_act_3lis            L3_chr_arr := L3_chr_arr();
  l_sces_4lis           L4_chr_arr;
  c_ms_limit            CONSTANT PLS_INTEGER := 1;
  l_timer_set                    PLS_INTEGER;

  /***************************************************************************************************

  Setup_DB: Create test records for a given scenario for testing view

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
    x_act_2lis := L2_chr_arr();
    x_act_2lis.EXTEND;
    x_act_2lis(1) := Utils_TT.Get_View (
                            p_view_name         => c_view_name,
                            p_sel_field_lis     => c_sel_lis,
                            p_where             => p_inp_3lis(2)(1)(1),
                            p_timer_set         => l_timer_set);
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
                       p_procedure_nm  => c_proc_nm,
                       p_act_3lis      => l_act_3lis,
                       p_timer_set     => l_timer_set);

EXCEPTION

  WHEN OTHERS THEN
    Utils.Write_Other_Error;
    RAISE;

END tt_HR_Test_View_V;

END TT_View_Drivers;
/
SHO ERR