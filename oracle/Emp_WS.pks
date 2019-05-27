CREATE OR REPLACE PACKAGE Emp_WS AS
/***************************************************************************************************
Description: HR demo web service code. Procedure saves new employees list and returns primary key
             plus same in words, or zero plus error message in output list

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        04-May-2016 1.0   Created
Brendan Furey        09-Sep-2016 1.1   AIP_Get_Dept_Emps added

***************************************************************************************************/

PROCEDURE AIP_Save_Emps (p_emp_in_lis emp_in_arr, x_emp_out_lis OUT emp_out_arr);
PROCEDURE AIP_Get_Dept_Emps (p_dep_id PLS_INTEGER, x_emp_csr OUT SYS_REFCURSOR);

END Emp_WS;
/
