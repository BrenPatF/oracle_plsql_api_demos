CREATE OR REPLACE PACKAGE TT_Emp_Batch AS
/***************************************************************************************************
Description: Transactional API testing for HR demo batch code

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        11-Sep-2016 1.0   Created
Brendan Furey        22-Oct-2016 1.1   TRAPIT name changes, UT->TT etc.

***************************************************************************************************/
PROCEDURE tt_AIP_Load_Emps;

END TT_Emp_Batch;
/
SHO ERR
