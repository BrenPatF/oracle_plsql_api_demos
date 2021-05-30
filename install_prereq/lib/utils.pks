CREATE OR REPLACE PACKAGE Utils AUTHID CURRENT_USER AS
/***************************************************************************************************
Name: utils.pks                        Author: Brendan Furey                       Date: 18-May-2019

Package spec component in the oracle_plsql_utils module. The module comprises a set of generic 
user-defined Oracle types and a PL/SQL package of functions and procedures of general utility.

      GitHub: https://github.com/BrenPatF/oracle_plsql_utils

====================================================================================================
|  Package     |  Notes                                                                            |
|==================================================================================================|
|   Utils      |  General utility functions and procedures                                         |
====================================================================================================

This file has the Utils package spec. See README for API specification, and the main_col_group.sql
script for simple examples of use.

This package runs with Invoker rights, not the default Definer rights, so that the dynamic SQL 
methods execute SQL using the rights of the calling schema, not the lib schema (if different).
***************************************************************************************************/

PRMS_END             CONSTANT VARCHAR2(30) := 'PRMS_END';
DELIM                         VARCHAR2(30) := '|';

FUNCTION Heading(
            p_head                         VARCHAR2,
            p_num_blanks_pre               PLS_INTEGER := 0,
            p_num_blanks_post              PLS_INTEGER := 0) 
            RETURN                         L1_chr_arr;
FUNCTION Col_Headers(
            p_value_lis                    chr_int_arr) 
            RETURN                         L1_chr_arr;
FUNCTION List_To_Line(
            p_value_lis                    chr_int_arr) -- token, length list
            RETURN                         VARCHAR2;
FUNCTION Join_Values(
            p_value_lis                    L1_chr_arr, 
            p_delim                        VARCHAR2 := DELIM) 
            RETURN                         VARCHAR2;
FUNCTION Join_Values(
            p_value1                       VARCHAR2,
            p_value2                       VARCHAR2 := PRMS_END, p_value3  VARCHAR2 := PRMS_END,
            p_value4                       VARCHAR2 := PRMS_END, p_value5  VARCHAR2 := PRMS_END,
            p_value6                       VARCHAR2 := PRMS_END, p_value7  VARCHAR2 := PRMS_END,
            p_value8                       VARCHAR2 := PRMS_END, p_value9  VARCHAR2 := PRMS_END,
            p_value10                      VARCHAR2 := PRMS_END, p_value11 VARCHAR2 := PRMS_END,
            p_value12                      VARCHAR2 := PRMS_END, p_value13 VARCHAR2 := PRMS_END,
            p_value14                      VARCHAR2 := PRMS_END, p_value15 VARCHAR2 := PRMS_END,
            p_value16                      VARCHAR2 := PRMS_END, p_value17 VARCHAR2 := PRMS_END,
            p_delim                        VARCHAR2 := DELIM) 
            RETURN                         VARCHAR2;
FUNCTION Split_Values(
            p_string                       VARCHAR2,
            p_delim                        VARCHAR2 := DELIM)
            RETURN                         L1_chr_arr;
FUNCTION View_To_List(         
            p_view_name                    VARCHAR2,
            p_sel_value_lis                L1_chr_arr,
            p_where                        VARCHAR2 := NULL,
            p_order_by                     VARCHAR2 := '1',
            p_delim                        VARCHAR2 := DELIM) 
            RETURN                         L1_chr_arr;
FUNCTION Cursor_To_List(  
            x_csr                   IN OUT SYS_REFCURSOR, 
            p_filter                       VARCHAR2 := NULL,
            p_delim                        VARCHAR2 := DELIM)
            RETURN                         L1_chr_arr;
FUNCTION IntervalDS_To_Seconds(
            p_interval                     INTERVAL DAY TO SECOND) 
            RETURN                         NUMBER;

PROCEDURE Sleep(
            p_ela_seconds                  NUMBER, 
            p_fraction_CPU                 NUMBER := 0.5);
PROCEDURE Raise_Error(
            p_message                      VARCHAR2);
PROCEDURE W(p_line                         VARCHAR2);
PROCEDURE W(p_line_lis                     L1_chr_arr);

PROCEDURE Delete_File(
            p_file_name                    VARCHAR2);
PROCEDURE Write_File(
            p_file_name                    VARCHAR2,
            p_line_lis                     L1_chr_arr);
FUNCTION Read_File(
            p_file_name                    VARCHAR2)
            RETURN                         L1_chr_arr;

FUNCTION Get_XPlan(
            p_sql_marker                   VARCHAR2,
            p_add_outline                  BOOLEAN DEFAULT FALSE)
            RETURN                         L1_chr_arr;

END Utils;
/
SHOW ERROR