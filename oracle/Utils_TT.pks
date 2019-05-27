CREATE OR REPLACE PACKAGE Utils_TT AS
/***************************************************************************************************
Description: This package contains procedures for Brendan's TRAPIT API testing framework .

             It was published initially with two other utility packages for the articles linked in
             the link below:

                 Utils:     General utilities
                 Timer_Set: Code timing utility

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723


Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        08-May-2016 1.0   Initial
Brendan Furey        21-May-2016 1.1   Replaced SYS.ODCI types with custom types L1_chr_arr etc.
Brendan Furey        25-Jun-2016 1.2   Refactored the output formatting; removed utPLSQL calls and
                                       replaced Run_Suite with new version that loops over array
                                       making its own calls
Brendan Furey        09-Jul-2016 1.3   Check_TT_Results: Write_Inp_Group added to body write inputs
                                       per scenario, with extra parameters for the inputs
Brendan Furey        09-Sep-2016 1.4   Cursor_to_Array added
Brendan Furey        22-Oct-2016 1.5   TRAPIT name changes, UT->TT etc.
Brendan Furey        27-Jan-2018 1.6   Check_TT_Results name change: -> Is_Deeply
Brendan Furey        06-Jul-2018 1.7   Initial JSON version

***************************************************************************************************/
c_date_fmt                  CONSTANT VARCHAR2(11) := 'DD-MON-YYYY';
c_past_date                 CONSTANT DATE := To_Date ('01-JAN-2010', c_date_fmt);
c_past_date_chr             CONSTANT VARCHAR2(11) := To_Char (c_past_date, c_date_fmt);
c_call_timer                CONSTANT VARCHAR2(30) := 'Caller';
c_setup_timer               CONSTANT VARCHAR2(30) := 'Setup';

FUNCTION Get_Inputs (		p_package_nm                VARCHAR2,
                            p_procedure_nm              VARCHAR2,
                            p_timer_set                 PLS_INTEGER)
                            RETURN                      L4_chr_arr;
PROCEDURE Set_Outputs (     p_package_nm                VARCHAR2,
                            p_procedure_nm              VARCHAR2,
                            p_act_3lis                  L3_chr_arr,
                            p_timer_set                 PLS_INTEGER);
FUNCTION Init (             p_proc_name                 VARCHAR2)
                            RETURN                      PLS_INTEGER;
PROCEDURE Run_Suite;
FUNCTION Get_View (         p_view_name                 VARCHAR2,
                            p_sel_field_lis             L1_chr_arr,
                            p_where                     VARCHAR2 DEFAULT NULL,
                            p_timer_set                 PLS_INTEGER) 
                            RETURN                      L1_chr_arr;

FUNCTION Cursor_to_Array (  x_csr                IN OUT SYS_REFCURSOR, 
                            p_filter                    VARCHAR2 DEFAULT NULL) 
                            RETURN                      L1_chr_arr;

END Utils_TT;
/
SHOW ERROR
CREATE OR REPLACE PUBLIC SYNONYM Utils_TT FOR Utils_TT
/
GRANT EXECUTE ON Utils_TT TO PUBLIC
/
