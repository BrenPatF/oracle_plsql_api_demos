CREATE OR REPLACE PACKAGE BODY Log_Config AS
/***************************************************************************************************
Name: log_config.pkb                   Author: Brendan Furey                       Date: 17-Mar-2019

Package body component in the log_set_oracle module. This is a logging framework that supports the
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

This file has the package body for the DML API for the log_configs table. See README for API
specification

***************************************************************************************************/

/***************************************************************************************************

set_Default_Config: Set one of the configs to be the default, unsetting any other active default

***************************************************************************************************/
PROCEDURE set_Default_Config(
            p_config_key                   VARCHAR2) IS -- config key
BEGIN

  UPDATE log_configs
    SET default_yn = CASE WHEN config_key = p_config_key THEN 'Y' END
   WHERE active_yn = 'Y';

END set_Default_Config;

/***************************************************************************************************

set_Default_Error_Config: Set one of the configs to be the default error config, unsetting any other
                          active default error config

***************************************************************************************************/
PROCEDURE set_Default_Error_Config(
            p_config_key                   VARCHAR2) IS -- config key
BEGIN

  UPDATE log_configs
    SET default_error_yn = CASE WHEN config_key = p_config_key THEN 'Y' END
   WHERE active_yn = 'Y';

END set_Default_Error_Config;

/***************************************************************************************************

Get_Default_Config: Get the config key of the default config, of which there is exactly one active

***************************************************************************************************/
FUNCTION Get_Default_Config RETURN VARCHAR2 IS -- config key
  l_config_key            log_configs.config_key%TYPE;
BEGIN

  SELECT config_key
    INTO l_config_key
    FROM log_configs
   WHERE default_yn = 'Y'
     AND active_yn = 'Y';

  RETURN l_config_key;

END Get_Default_Config;

/***************************************************************************************************

Get_Default_Error_Config: Get the config key of the default error config, of which there is exactly
                          one active

***************************************************************************************************/
FUNCTION Get_Default_Error_Config RETURN VARCHAR2 IS -- config key
  l_config_key            log_configs.config_key%TYPE;
BEGIN

  SELECT config_key
    INTO l_config_key
    FROM log_configs
   WHERE default_error_yn = 'Y'
     AND active_yn = 'Y';

  RETURN l_config_key;

END Get_Default_Error_Config;

/***************************************************************************************************

Ins_Config: Insert a new log config. If the config key exists, a new active version will be 
            inserted, inheriting description and config type, de-activating prior versions, else 
            version 1 will be inserted

***************************************************************************************************/
PROCEDURE Ins_Config(
            p_config_key                   VARCHAR2,            -- config key
            p_config_type                  VARCHAR2 := NULL,    -- config type
            p_default_yn                   VARCHAR2 := NULL,    -- default config? Y/N
            p_default_error_yn             VARCHAR2 := NULL,    -- default error config? Y/N
            p_singleton_yn                 VARCHAR2 := NULL,    -- singleton config? Y/N
            p_description                  VARCHAR2 := NULL,    -- description
            p_put_lev                      PLS_INTEGER := 10,   -- put level for header and lines
            p_put_lev_stack                PLS_INTEGER := NULL, -- put level for call stack
            p_put_lev_cpu                  PLS_INTEGER := NULL, -- put level for CPU time
            p_ctx_inp_lis                  ctx_inp_arr := NULL, -- list of contexts with put levels and scopes
            p_put_lev_module               PLS_INTEGER := NULL, -- put level for module (DBMS_Application_Info)
            p_put_lev_action               PLS_INTEGER := NULL, -- put level for action (DBMS_Application_Info)
            p_put_lev_client_info          PLS_INTEGER := NULL, -- put level for client info (DBMS_Application_Info)
            p_app_info_only_yn             VARCHAR2 := NULL,    -- DBMS_Application_Info only (don't put to table)? Y/N
            p_buff_len                     PLS_INTEGER := 1,    -- length of lines buffer 
            p_extend_len                   PLS_INTEGER := 1) IS -- length by which to extend buffer when needed
  l_vsn_no				  PLS_INTEGER;
  l_id						  PLS_INTEGER;
  l_description     log_configs.description%TYPE;
  l_config_type     log_configs.config_type%TYPE;
  l_config          log_configs%ROWTYPE;
BEGIN

  SELECT Max(id)
    INTO l_id
    FROM log_configs
   WHERE config_key = p_config_key;

  IF l_id IS NULL THEN

    l_vsn_no := 1;

  ELSE

    UPDATE log_configs
       SET active_yn = 'N'
     WHERE id = l_id;

    SELECT *
      INTO l_config
      FROM log_configs
     WHERE id = l_id;
    l_vsn_no := l_config.vsn_no + 1;

  END IF;

  INSERT INTO log_configs (
        id,
        config_key,
        config_type,
        vsn_no,
        active_yn,
        default_yn,
        default_error_yn,
        singleton_yn,
        description,
        creation_tmstp,
        put_lev,
        put_lev_stack,
        put_lev_cpu,
        ctx_inp_lis,
        put_lev_module,
        put_lev_action,
        put_lev_client_info,
        app_info_only_yn,
        buff_len,
        extend_len
  ) VALUES (
        log_configs_s.NEXTVAL,
        p_config_key,
        Nvl(p_config_type, l_config_type),
        l_vsn_no,
        'Y',
        Nvl(p_default_yn, l_config.default_yn),
        Nvl(p_default_error_yn, l_config.default_error_yn),
        Nvl(p_singleton_yn, l_config.singleton_yn),
        Nvl(p_description, l_config.description),
        SYSTIMESTAMP,
        Nvl(p_put_lev, l_config.put_lev),
        Nvl(p_put_lev_stack, l_config.put_lev_stack),
        Nvl(p_put_lev_cpu, l_config.put_lev_cpu),
        Nvl(p_ctx_inp_lis, l_config.ctx_inp_lis),
        Nvl(p_put_lev_module, l_config.put_lev_module),
        Nvl(p_put_lev_action, l_config.put_lev_action),
        Nvl(p_put_lev_client_info, l_config.put_lev_client_info),
        Nvl(p_app_info_only_yn, l_config.app_info_only_yn),
        Nvl(p_buff_len, l_config.buff_len),
        Nvl(p_extend_len, l_config.extend_len)
  );
  IF p_default_yn = 'Y' THEN
    set_Default_Config(p_config_key => p_config_key);
  END IF;
  IF p_default_error_yn = 'Y' THEN
    set_Default_Error_Config(p_config_key => p_config_key);
  END IF;

END Ins_Config;

/***************************************************************************************************

Get_Config: Return the active log config for the passed config key

***************************************************************************************************/
FUNCTION Get_Config(
            p_config_key                   VARCHAR2)   -- config key
            RETURN                         log_configs%ROWTYPE IS -- config
  l_config            log_configs%ROWTYPE;
BEGIN

  SELECT *
    INTO l_config
    FROM log_configs
   WHERE config_key = p_config_key
     AND active_yn = 'Y';

  RETURN l_config;

END Get_Config;

/***************************************************************************************************

Del_Config: Delete the active log config, making most recent with same key active, if any

***************************************************************************************************/
PROCEDURE Del_Config(
            p_config_key                   VARCHAR2) IS -- config key
BEGIN

  DELETE log_configs
   WHERE config_key = p_config_key
     AND active_yn = 'Y';

  UPDATE log_configs
     SET active_yn = 'Y'
   WHERE config_key = p_config_key
     AND id = (SELECT Max(id) FROM log_configs
                WHERE config_key = p_config_key);

END Del_Config;

END Log_Config;
/
SHOW ERROR