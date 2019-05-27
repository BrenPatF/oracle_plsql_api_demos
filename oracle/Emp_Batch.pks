CREATE OR REPLACE PACKAGE Emp_Batch AS
/***************************************************************************************************
Description: HR demo batch code. Procedure saves new employees from file via external table

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        11-Sep-2016 1.0   Created

***************************************************************************************************/

PROCEDURE AIP_Load_Emps (p_file_name    VARCHAR2,
                         p_file_count   PLS_INTEGER);
END Emp_Batch;
/
SHO ERR
