CREATE OR REPLACE PACKAGE Log_Config AS
/***************************************************************************************************
Name: log_config.pks                   Author: Brendan Furey                       Date: 17-Mar-2019

Package spec component in the log_set_oracle module. This is a logging framework that supports the
writing of messages to log tables, along with various optional data items that may be specified as
parameters or read at runtime via system calls.

    GitHub: https://github.com/BrenPatF/log_set_oracle

====================================================================================================
|  Package     |  Notes                                                                            |
|==================================================================================================|
|  Log_Set     |  Logging package                                                                  |
|--------------|-----------------------------------------------------------------------------------|
| *Log_Config* |  DML API package for the log_configs table                                        |
====================================================================================================

This file has the package spec for the DML API for the log_configs table. See README for API
specification

***************************************************************************************************/

FUNCTION Get_Default_Config RETURN VARCHAR2;
FUNCTION Get_Default_Error_Config RETURN VARCHAR2;
FUNCTION Get_Config(
            p_config_key                   VARCHAR2)
            RETURN                         log_configs%ROWTYPE;
PROCEDURE Ins_Config(
            p_config_key                   VARCHAR2,
            p_config_type                  VARCHAR2 := NULL,
            p_default_yn                   VARCHAR2 := NULL,
            p_default_error_yn             VARCHAR2 := NULL,
            p_singleton_yn                 VARCHAR2 := NULL,
            p_description                  VARCHAR2 := NULL,
            p_put_lev                      PLS_INTEGER := 10,
            p_put_lev_stack                PLS_INTEGER := NULL,
            p_put_lev_cpu                  PLS_INTEGER := NULL,
            p_ctx_inp_lis                  ctx_inp_arr := NULL,
            p_put_lev_module               PLS_INTEGER := NULL,
            p_put_lev_action               PLS_INTEGER := NULL,
            p_put_lev_client_info          PLS_INTEGER := NULL,
            p_app_info_only_yn             VARCHAR2 := NULL,
            p_buff_len                     PLS_INTEGER := 1,
            p_extend_len                   PLS_INTEGER := 1);
PROCEDURE Del_Config(
            p_config_key                   VARCHAR2);

END Log_Config;
/
SHOW ERROR
