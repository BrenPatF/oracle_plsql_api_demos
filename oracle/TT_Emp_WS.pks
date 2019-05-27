CREATE OR REPLACE PACKAGE TT_Emp_WS AS
/***************************************************************************************************
Description: Transactional API testing for HR demo web service code (Emp_WS) using Brendan's TRAPIT API
             testing framework.

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
Brendan Furey        25-Jun-2016 1.1   Removed tt_Setup and ut_Teardown following removal of uPLSQL
Brendan Furey        11-Sep-2016 1.2   tt_AIP_Get_Dept_Emps added
Brendan Furey        22-Oct-2016 1.3   TRAPIT name changes, UT->TT etc.

***************************************************************************************************/

PROCEDURE tt_AIP_Save_Emps;
PROCEDURE tt_AIP_Get_Dept_Emps;

END TT_Emp_WS;
/
