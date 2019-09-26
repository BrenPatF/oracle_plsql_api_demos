CREATE OR REPLACE PACKAGE Timer_Set AS
/***************************************************************************************************
Name: timer_set.pks                   Author: Brendan Furey                       Date: 29-Jan-2019

Package spec component in the timer_set_oracle module. This module facilitates code timing for 
instrumentation and other purposes, with very small footprint in both code and resource usage.

    GitHub: https://github.com/BrenPatF/timer_set_oracle

====================================================================================================
|  Package    |  Notes                                                                             |
|===================================================================================================
| *Timer_Set* |  Code timing package                                                               |
====================================================================================================

This file has the Timer_Set package spec. See README for API specification, and the 
main_col_group.sql script for simple examples of use.

***************************************************************************************************/

TYPE timer_stat_rec IS RECORD(
            name                           VARCHAR2(100), 
            ela_secs                       NUMBER, 
            cpu_secs                       NUMBER, 
            calls                          PLS_INTEGER);
TYPE timer_stat_arr IS VARRAY(1000) OF timer_stat_rec;
TYPE time_point_rec IS RECORD(
            ela                            TIMESTAMP, 
            cpu                            PLS_INTEGER);
TYPE time_point_arr IS VARRAY(1000) OF time_point_rec;
TYPE format_prm_rec IS RECORD(
            time_width                     PLS_INTEGER := 8,
            time_dp                        PLS_INTEGER := 2,
            time_ratio_dp                  PLS_INTEGER := 5,
            calls_width                    PLS_INTEGER := 10);
--        Parameters: time width and decimal places, time ratio dp

FORMAT_PRMS_DEF format_prm_rec;
PROCEDURE Remove_Timer_Set(
            p_timer_set_id                 PLS_INTEGER);
PROCEDURE Null_Mock;
FUNCTION Construct(
            p_timer_set_name               VARCHAR2, 
            p_mock_time_lis                time_point_arr DEFAULT NULL) 
            RETURN                         PLS_INTEGER;
PROCEDURE Init_Time(
            p_timer_set_id                 PLS_INTEGER);
PROCEDURE Increment_Time(
            p_timer_set_id                 PLS_INTEGER, 
            p_timer_name                   VARCHAR2);
FUNCTION Get_Timers(
            p_timer_set_id                 PLS_INTEGER) 
            RETURN                         timer_stat_arr;
FUNCTION Format_Timers(
            p_timer_set_id                 PLS_INTEGER, 
            p_format_prms                  format_prm_rec DEFAULT FORMAT_PRMS_DEF)
            RETURN                         L1_chr_arr;
FUNCTION Get_Self_Timer  
            RETURN                         L1_num_arr;
FUNCTION Format_Self_Timer(
            p_format_prms                  format_prm_rec DEFAULT FORMAT_PRMS_DEF) 
            RETURN                         VARCHAR2;
FUNCTION Format_Results(
            p_timer_set_id                 PLS_INTEGER, 
            p_format_prms                  format_prm_rec DEFAULT FORMAT_PRMS_DEF) 
            RETURN                         L1_chr_arr;

END Timer_Set;
/
SHOW ERROR