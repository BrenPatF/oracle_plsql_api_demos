CREATE OR REPLACE PACKAGE TT_View_Drivers AS
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
Brendan Furey        22-Oct-2016 1.52   TRAPIT name changes, UT->TT etc.

***************************************************************************************************/

PROCEDURE tt_HR_Test_View_V;

END TT_View_Drivers;
/
