@..\initspool r_tests
/***************************************************************************************************
Name: r_tests.sql                       Author: Brendan Furey                      Date: 21-Sep-2019

Unit test driver script component in the Oracle PL/SQL API Demos module. 

The module demonstrates instrumentation and logging, code timing, and unit testing of PL/SQL APIs,
using example APIs writtten against Oracle's HR demo schema. 

    GitHub: https://github.com/BrenPatF/https://github.com/BrenPatF/oracle_plsql_api_demos

There are two driver SQL scripts, one for the base packages, with demonstration of instrumentation
and logging, and code timing, and the other for unit testing.

DRIVER SCRIPTS
====================================================================================================
|  SQL Script  |  API/Test Unit                   |  Notes                                         |
|===================================================================================================
|  api_driver  |  Emp_WS.Save_Emps                |  Save a list of new employees                  |
|              |  Emp_WS.Get_Dept_Emps            |  Get department and employee details           |
|              |  Emp_Batch.Load_Emps             |  Load new/updated employees from file          |
|              |  HR_Test_View_V                  |  View for department and employees             |
----------------------------------------------------------------------------------------------------
| *r_tests*    |  TT_Emp_WS.Save_Emps             |  Unit test for Emp_WS.Save_Emps                |
|              |  TT_Emp_WS.Get_Dept_Emps         |  Unit test for Emp_WS.Get_Dept_Emps            |
|              |  TT_Emp_Batch.Load_Emps          |  Unit test for Emp_Batch.Load_Emps             |
|              |  TT_View_Drivers.HR_Test_View_V  |  Unit test for HR_Test_View_V                  |
====================================================================================================
This file has the unit test driver script. Note that the test packages are called by the unit test 
utility package Trapit, which reads the unit test details from a table, tt_units, populated by the
install scripts.

The test programs follow 'The Math Function Unit Testing design pattern':

    GitHub: https://github.com/BrenPatF/trapit_nodejs_tester

Note that the unit test programs generates output files, tt_*.*_out.json, that are processed by a separate nodejs program, npm package trapit (see README for further details).

The output JSON files contain arrays of expected and actual records by group and scenario, in the
format expected by the nodejs program. This program produces listings of the results in HTML and/or
text format, and a sample set of listings is included in the folder test_output.

***************************************************************************************************/
BEGIN

  Trapit_Run.Run_Tests('app');

END;
/
@..\endspool