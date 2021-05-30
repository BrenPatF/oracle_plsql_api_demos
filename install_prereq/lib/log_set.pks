CREATE OR REPLACE PACKAGE Log_Set AS
/***************************************************************************************************
Name: log_set.pks                      Author: Brendan Furey                       Date: 17-Mar-2019

Package spec component in the log_set_oracle module. This is a logging framework that supports the
writing of messages to log tables, along with various optional data items that may be specified as
parameters or read at runtime via system calls.

    GitHub: https://github.com/BrenPatF/log_set_oracle

====================================================================================================
|  Package     |  Notes                                                                            |
|==================================================================================================|
| *Log_Set*    |  Logging package                                                                  |
|--------------|-----------------------------------------------------------------------------------|
|  Log_Config  |  DML API package for log configs table                                            |
====================================================================================================

This file has the Log_Set package spec. See README for API specification, and the main_col_group.sql
script for simple examples of use.

***************************************************************************************************/

TYPE construct_rec IS RECORD(
       null_yn                      VARCHAR2(1) := 'N',
       config_key                   VARCHAR2(30),
       header                       log_headers%ROWTYPE,
       do_close                     BOOLEAN := FALSE);
CONSTRUCT_DEF construct_rec;

TYPE line_rec IS RECORD(
       null_yn                      VARCHAR2(1) := 'N',
       line                         log_lines%ROWTYPE,
       do_close                     BOOLEAN := FALSE);
LINE_DEF line_rec;

PROCEDURE Init;

FUNCTION Con_Construct_Rec(
            p_config_key                   VARCHAR2 := NULL,
            p_description                  VARCHAR2 := NULL,
            p_plsql_unit                   VARCHAR2 := NULL,
            p_api_nm                       VARCHAR2 := NULL,
            p_put_lev_min                  PLS_INTEGER := NULL,
            p_do_close                     BOOLEAN := NULL) RETURN construct_rec;
FUNCTION Con_Line_Rec(
            p_line_type                    VARCHAR2 := NULL,
            p_plsql_unit                   VARCHAR2 := NULL,
            p_plsql_line                   VARCHAR2 := NULL,
            p_group_text                   VARCHAR2 := NULL,
            p_action                       VARCHAR2 := NULL,
            p_put_lev_min                  PLS_INTEGER := NULL,
            p_err_num                      PLS_INTEGER := NULL,
            p_err_msg                      VARCHAR2 := NULL,
            p_call_stack                   VARCHAR2 := NULL,
            p_do_close                     BOOLEAN := NULL) RETURN line_rec;

FUNCTION Construct(
            p_construct_rec                construct_rec := CONSTRUCT_DEF)
            RETURN                         PLS_INTEGER;
FUNCTION Construct(   
            p_line_text                    VARCHAR2,
            p_construct_rec                construct_rec := CONSTRUCT_DEF,
            p_line_rec                     line_rec := LINE_DEF)
            RETURN                         PLS_INTEGER;
FUNCTION Construct(
            p_line_lis                     L1_chr_arr,
            p_construct_rec                construct_rec := CONSTRUCT_DEF,
            p_line_rec                     line_rec := LINE_DEF)
            RETURN                         PLS_INTEGER;
PROCEDURE Put_Line(
            p_line_text                    VARCHAR2,
            p_log_id                       PLS_INTEGER := NULL,
            p_line_rec                     line_rec := LINE_DEF);
PROCEDURE Put_List(
            p_line_lis                     L1_chr_arr,
            p_log_id                       PLS_INTEGER := NULL,
            p_line_rec                     line_rec := LINE_DEF);
PROCEDURE Close_Log(
            p_log_id                       PLS_INTEGER := NULL,
            p_line_text                    VARCHAR2 := NULL,
            p_line_rec                     line_rec := LINE_DEF);
      
PROCEDURE Raise_Error(
            p_err_msg                      VARCHAR2,
            p_log_id                       PLS_INTEGER := NULL,
            p_line_rec                     line_rec := LINE_DEF,
            p_do_close                     BOOLEAN := TRUE);
PROCEDURE Write_Other_Error(
            p_log_id                       PLS_INTEGER := NULL,
            p_line_text                    VARCHAR2 := NULL,
            p_line_rec                     line_rec := LINE_DEF,
            p_do_close                     BOOLEAN := TRUE);
PROCEDURE Delete_Log(
            p_log_id                       PLS_INTEGER := NULL,
            p_min_log_id                   PLS_INTEGER := 0,
            p_session_id                   VARCHAR2 := NULL);
FUNCTION Entry_Point(
            p_plsql_unit                  VARCHAR2,
            p_api_nm                      VARCHAR2,
            p_config_key                  VARCHAR2,
            p_text                        VARCHAR2 := NULL)
            RETURN                        PLS_INTEGER;
PROCEDURE Exit_Point(
            p_log_id                      PLS_INTEGER,
            p_text                        VARCHAR2 := NULL);

END Log_Set;
/
SHOW ERROR
