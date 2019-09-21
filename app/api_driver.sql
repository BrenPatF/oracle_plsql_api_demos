@..\initspool api_driver
/***************************************************************************************************
Name: api_driver.sql                    Author: Brendan Furey                      Date: 21-Sep-2019

API driver script component in the Oracle PL/SQL API Demos module. 

The module demonstrates instrumentation and logging, code timing, and unit testing of PL/SQL APIs,
using example APIs writtten against Oracle's HR demo schema. 

    GitHub: https://github.com/BrenPatF/https://github.com/BrenPatF/oracle_plsql_api_demos

There are two driver SQL scripts, one for the base packages, with demonstration of instrumentation
and logging, and code timing, and the other for unit testing.

DRIVER SCRIPTS
====================================================================================================
|  SQL Script  |  API/Test Unit                   |  Notes                                         |
|===================================================================================================
| *api_driver* |  Emp_WS.Save_Emps                |  Save a list of new employees                  |
|              |  Emp_WS.Get_Dept_Emps            |  Get department and employee details           |
|              |  Emp_Batch.Load_Emps             |  Load new/updated employees from file          |
|              |  HR_Test_View_V                  |  View for department and employees             |
----------------------------------------------------------------------------------------------------
|  r_tests     |  TT_Emp_WS.Save_Emps             |  Unit test for Emp_WS.Save_Emps                |
|              |  TT_Emp_WS.Get_Dept_Emps         |  Unit test for Emp_WS.Get_Dept_Emps            |
|              |  TT_Emp_Batch.Load_Emps          |  Unit test for Emp_Batch.Load_Emps             |
|              |  TT_View_Drivers.HR_Test_View_V  |  Unit test for HR_Test_View_V                  |
====================================================================================================
This file has the driver script for the example code calling the base APIs, with code timing and
logging via the installed modules Utils, Timer_Set and Log_Set.

***************************************************************************************************/
DECLARE
  DRIVER_INFILE         CONSTANT VARCHAR2(30) := 'employees.dat';
  VIEW_NAME             CONSTANT VARCHAR2(61) := 'HR_Test_View_V';
  SEL_LIS               CONSTANT L1_chr_arr := 
                                   L1_chr_arr('last_name', 'department_name', 'manager',
                                              'salary', 'sal_rat', 'sal_rat_g');
  l_timer_set                    PLS_INTEGER := Timer_Set.Construct('api_driver');
  l_res_arr                      chr_int_arr;
  l_emp_in_lis                   emp_in_arr := emp_in_arr(
                                   emp_in_rec('Furey', 'myemail@world.com', 'IT_PROG', 100000),
                                   emp_in_rec('Bloggs', 'hisemail@world.com', 'MK_MAN', 5000));
  l_emp_out_lis                  emp_out_arr;
  l_emp_lis                      L1_chr_arr := 
                                   L1_chr_arr(
                                     ',Furey,myemail_B@world.com,10-MAY-1962,IT_PROG,100000',
                                     ',Bloggs,hisemail_B@world.com,06-AUG-1984,MK_MAN,5000');
  l_emp_csr                      SYS_REFCURSOR;

  PROCEDURE Put_Module IS
    l_module_name                  VARCHAR2(100);
    l_action_name                  VARCHAR2(100);
    l_client_info                  VARCHAR2(100);
  BEGIN
    DBMS_Application_Info.Read_Module(module_name => l_module_name, action_name => l_action_name);
    DBMS_Application_Info.Read_Client_Info(client_info  => l_client_info);
    Log_Set.Put_List(p_line_lis => L1_chr_arr('DBMS_Application_Info: Module = ' || l_module_name,
                                              '...................... Action = ' || l_action_name,
                                              '...................... Client Info = ' || l_client_info));

  END Put_Module;

  PROCEDURE Put_Heading(           
            p_head                         VARCHAR2,
            p_num_blanks_pre               PLS_INTEGER := 0,
            p_num_blanks_post              PLS_INTEGER := 0) IS
  BEGIN
    Log_Set.Put_List(p_line_lis => Utils.Heading(p_head            => p_head, 
                                                 p_num_blanks_pre  => p_num_blanks_pre,
                                                 p_num_blanks_post => p_num_blanks_post));

  END Put_Heading;

  PROCEDURE Do_Save IS
  BEGIN

    Put_Heading(p_head => 'Call Emp_WS.Save_Emps to save a list of employees passed...');
    Emp_WS.Save_Emps(
              p_emp_in_lis    => l_emp_in_lis,
              x_emp_out_lis   => l_emp_out_lis);
    Timer_Set.Increment_Time(p_timer_set_id => l_timer_set, 
                             p_timer_name   => 'Save_Emps');
    Put_Module;
    Put_Heading(p_head => 'Print the records returned...');
    FOR i IN 1..l_emp_out_lis.COUNT LOOP
      Log_Set.Put_Line(p_line_text => l_emp_out_lis(i).employee_id || ' - ' ||
                                      l_emp_out_lis(i).description);
    END LOOP;

  END Do_Save;

  PROCEDURE Do_Get IS
  BEGIN

    Put_Heading(p_head           => 'Call Emp_WS.Get_Dept_Emps to get employees for a department...', 
                p_num_blanks_pre => 1);
    Emp_WS.Get_Dept_Emps(
              p_dep_id    => 60,
              x_emp_csr   => l_emp_csr);
    Timer_Set.Increment_Time(p_timer_set_id => l_timer_set, 
                             p_timer_name   => 'Get_Dept_Emps');
    Put_Module;
    Put_Heading(p_head => 'Call Utils.Cursor_To_List to read output cursor into delimited list...');
    Log_Set.Put_List(p_line_lis => Utils.Cursor_To_List(x_csr => l_emp_csr));

  END Do_Get;

  PROCEDURE Do_Load IS
  BEGIN

    Put_Heading(p_head           => 'Call Utils.Write_File to create a file for loading employees...',
                p_num_blanks_pre => 1);
    Utils.Write_File(p_file_name => DRIVER_INFILE,
                     p_line_lis  => l_emp_lis);
    Timer_Set.Increment_Time(p_timer_set_id => l_timer_set, 
                             p_timer_name   => 'Write_File');
    Put_Heading(p_head           => 'Call Emp_Batch.Load_Emps to load employee data from file just created...', 
                p_num_blanks_pre => 1);
    Emp_Batch.Load_Emps(p_file_name  => DRIVER_INFILE,
                        p_file_count => 2);
    Timer_Set.Increment_Time(p_timer_set_id => l_timer_set, 
                             p_timer_name   => 'Load_Emps');
    Put_Module;
    Utils.Delete_File(p_file_name => DRIVER_INFILE);
    Timer_Set.Increment_Time(p_timer_set_id => l_timer_set, 
                             p_timer_name   => 'Delete_File');

  END Do_Load;

  PROCEDURE Do_View IS
  BEGIN

    Put_Heading(p_head           => 'Call Utils.View_To_List to list employees with last name ''B%'', print records returned...', 
                p_num_blanks_pre => 1);
    Log_Set.Put_List(p_line_lis => Utils.View_To_List(
                                           p_view_name     => VIEW_NAME,
                                           p_sel_value_lis => SEL_LIS,
                                           p_where         => 'last_name LIKE ''B%'''));
    Timer_Set.Increment_Time(p_timer_set_id => l_timer_set,
                             p_timer_name   => 'View_To_List');
  END Do_View;

  PROCEDURE Timings IS
  BEGIN

    Put_Heading(p_head            => 'Call to Timer_Set.Format_Results gives summary table of timings...', 
                p_num_blanks_pre  => 1,
                p_num_blanks_post => 1);
    Log_Set.Put_List(p_line_lis => Timer_Set.Format_Results(p_timer_set_id => l_timer_set));

  END Timings;

BEGIN

  Do_Save;
  Do_Get;
  Do_Load;
  Do_View;
  Timings;

  RAISE NO_DATA_FOUND;

EXCEPTION
  WHEN OTHERS THEN
    Log_Set.Write_Other_Error(p_line_text => 'Error raised for demo purpose');

END;
/
COLUMN id              FORMAT 990
COLUMN lno             FORMAT 990
COLUMN "At"            FORMAT A12
COLUMN text            FORMAT A90
COLUMN plsql_unit      FORMAT A9
COLUMN api_nm          FORMAT A9
COLUMN err_msg         FORMAT A24
COLUMN error_backtrace FORMAT A22
COLUMN call_stack      FORMAT A71
PROMPT Lines
SELECT hdr.id, hdr.plsql_unit, hdr.api_nm, lin.line_num lno, To_Char(lin.creation_tmstp, 'hh24:mi:ss.ff3') "At", line_text text
  FROM log_lines lin
  JOIN log_headers hdr ON hdr.id = lin.log_id
 WHERE hdr.session_id = SYS_CONTEXT('USERENV', 'SESSIONID')
   AND Nvl(lin.line_type, 'NON-ERROR') != 'ERROR'
 ORDER BY lin.session_line_num
/
PROMPT Errors
SELECT hdr.id, lin.line_num lno, err_msg, error_backtrace, call_stack
  FROM log_lines lin
  JOIN log_headers hdr ON hdr.id = lin.log_id
 WHERE hdr.session_id = SYS_CONTEXT('USERENV', 'SESSIONID')
   AND lin.line_type = 'ERROR'
 ORDER BY lin.session_line_num
/
PROMPT Delete the logs, rollback the saved employees, and delete job statistics for this demo to facilitate repeated running in a session
EXEC Log_Set.Delete_Log(p_session_id => SYS_CONTEXT('USERENV', 'SESSIONID'));
ROLLBACK
/
DELETE job_statistics_v
/
COMMIT
/
@..\endspool